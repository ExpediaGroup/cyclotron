###
# Copyright (c) 2013-2018 the original author or authors.
#
# Licensed under the MIT License (the "License");
# you may not use this file except in compliance with the License. 
# You may obtain a copy of the License at
#
#     http://www.opensource.org/licenses/mit-license.php
#
# Unless required by applicable law or agreed to in writing, 
# software distributed under the License is distributed on an 
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
# either express or implied. See the License for the specific 
# language governing permissions and limitations under the License. 
###

#
# Provides access to data sources in a generic way.  Using the Angular injector, it 
# will return instances of a given data source by name.  The name property will be concat 
# with "DataSource" to load the data source. e.g. "mock" -> "mockDataSource"
#
# To use data sources in a widget, add a reference to this service in the controller defintion:
#
#     cyclotronApp.controller 'SampleWidget', [
#         '$scope', 'dataService', 
#         ($scope, dataService) ->
# 
# Dashboard widgets can have a data source added like this:
#     "widgets": [{
#             "dataSource": {
#                 "name": "mock",
#                 "optionA": "aaaaa",
#                 "optionB": "bbbbb",
#             },
#             "widget": "sampleWidget",
#             "gridHeight": 2,
#             "gridWidth": 2
#         }
#     ]
#
# All other properties set in the dataSource object can be accessed by the data source.
#
cyclotronServices.factory 'dataService', ($injector, configService) ->

    defaultSortFunction = (a, b, ascending) ->
        if (!a? and !b?)
            0
        else if a? and !b?
            if ascending then 1 else -1
        else if !a? and b?
            if ascending then -1 else 1
        else if _.isBoolean(a) and _.isBoolean(b)
            if a == b then return 0
            if (ascending and !a) or (!ascending and a) then return 1
            -1
        else if _.isNumber(a)
            if ascending then return a - b
            b - a
        else if _.isString(a)
            if ascending then return a.localeCompare(b)
            b.localeCompare(a)
        else
            0

    # Convert a sort string ("+/-col") into a sort object
    parseSortBy = (columnName) ->
        # +/- at the start of the name determines order
        ascending = true
        firstChar = columnName.charAt(0)

        if firstChar == '+'
            columnName = columnName.substring(1)
        else if firstChar == '-'
            ascending = false
            columnName = columnName.substring(1)

        return { columnName: columnName, ascending: ascending }


    return {
        # Gets an instance of a data source from a definition object.
        # Uses the Angular injector to load the data source by name.
        # The 'type' property will be concat with "DataSource" to load the 
        # data source. e.g. "mock" -> "mockDataSource"
        get: (dataSourceDefinition) -> 

            return if _.isNullOrUndefined(dataSourceDefinition)
            return if _.isNullOrUndefined(dataSourceDefinition.type)

            name = dataSourceDefinition.name
            type = dataSourceDefinition.type.toLowerCase()
            
            # Create if not in the cache
            if not Cyclotron.dataSources[name]?
                
                # Get instance by name
                dataSource = $injector.get(type + 'DataSource')

                # Get default options
                dataSourceProperties = configService?.dashboard.properties.dataSources.options[type]?.properties
                if dataSourceProperties?
                    _.each dataSourceProperties, (property, name) ->
                        if property.default?
                            dataSourceDefinition[name] ?= property.default

                # Set options
                Cyclotron.dataSources[name] = dataSource.initialize(dataSourceDefinition)

            # Return from cache
            return Cyclotron.dataSources[name]


        # Client-side filtering of data.  Does not modify the original array
        # but returns a new array
        #
        # data: Standard data source data, array of objects
        # filters: Object with keys to be filtered.  The value of the data must match
        #          the filter value for each property.  e.g:
        #
        #       {
        #           col1: "val1",
        #           col2: "val2",
        #           col3: [1, 2]
        #       }
        #
        #       For col3 above, either values 1 or 2 will match, so the result
        #       will be any rows that match:
        #           col1=val1 and col2=val2 and (col3=1 or col3=2)
        #
        filter: (data, filters) ->

            return data if _.isEmpty(data) or !_.isArray(data)

            # Compile inline javascript
            # Convert "*" or "/../"" to regexp
            parseFilter = (value) ->
                value = _.jsExec value

                if /^\/.*\/$/i.test(value)
                    return new RegExp(value.substring(1, value.length-1), 'i')

                return value
        
            # Compile inline JS in each filter (allowed in key or value)
            filters2 = {}
            _.each filters, (value, key) -> 
                key = _.jsExec key

                # Handle string values or arrays
                value2 = if _.isArray(value)
                    _.map value, (v) -> parseFilter(v)
                else
                    parseFilter(value)
                
                filters2[key] = value2

            compareRow = (row) ->
                _.every filters2, (filterValue, key) ->
                    value = row[key]
                    if filterValue == '*'
                        return !_.isEmpty(value)
                    if _.isRegExp(filterValue)
                        return !_.isEmpty(value) && filterValue.test(value)
                    else if _.isArray(filterValue)
                        return _.some filterValue, (arrayValue) ->
                            if arrayValue == '*'
                                return !_.isEmpty(value)
                            if _.isRegExp arrayValue
                                arrayValue.test(value)
                            else
                                arrayValue == value
                    else
                        return value == filterValue

            filtered = _.filter(data, compareRow)
            return filtered

        # Sorts the data array in-place (modifies and returns the original array).
        # Uses a stable-sort so the original sort order will be reflected in the result.
        #
        #
        #
        sort: (data, sortBy) ->
            return data unless sortBy? and !_.isEmpty(data) and _.isArray(data)

            # Sorts the set by a column name or a sort function
            sorter = (input) ->

                if _.isString input
                    columnName = input

                    sortObj = parseSortBy(columnName)

                    # Sort!
                    data.sort (r1, r2) ->
                        a = r1[sortObj.columnName]
                        b = r2[sortObj.columnName]

                        defaultSortFunction a, b, sortObj.ascending

                else if _.isFunction input
                    data.sort (r1, r2) ->
                        input r1, r2, defaultSortFunction

                # Else do nothing

            if (_.isArray(sortBy))
                # Compile inline JS in column names
                sortBy2 = _.map sortBy, (v) -> _.jsExec v

                # Multiple sorts - clone and reverse the array
                _.each(sortBy2.reverse(), (column) -> sorter(column))
                return data
            else 
                sorter _.jsExec(sortBy)


        # Convert a sort string ("+/-col") into a sort object
        parseSortBy: parseSortBy

        defaultSortFunction: defaultSortFunction
    }
