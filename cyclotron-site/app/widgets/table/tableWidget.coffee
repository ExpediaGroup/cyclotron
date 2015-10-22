###
# Copyright (c) 2013-2015 the original author or authors.
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
# Table Widget
#
# Requires a dataService property to load data
# Support dataServices that return object-based data:
#
#    Object-based (keys are columns):
#        [ 
#            {color: "red", number: 1, state: "WA"}
#            {color: "green", number: 41, state: "CA"}
#        ]
# Optionally, headers can be provided by the callback as well
#

cyclotronApp.controller 'TableWidget', ($scope, $location, dashboardService, dataService) ->

    $scope.loading = false
    $scope.dataSourceError = false
    $scope.dataSourceErrorMessage = null
    $scope.columnGroups = []

    $scope.widgetTitle = -> _.jsExec($scope.widget.title)
    sortFunction = _.jsEval $scope.widget.sortFunction

    # Load data source
    dsDefinition = dashboardService.getDataSource($scope.dashboard, $scope.widget)
    $scope.dataSource = dataService.get(dsDefinition)

    $scope.linkTarget = (column) ->
        if column.openLinksInNewWindow?
            if column.openLinksInNewWindow == false then '_self' else '_blank'
        else
            if $scope.dashboard.openLinksInNewWindow == false then '_self' else '_blank'

    # Returns a rule property for a given row/column, if it exists.  
    # Considers the matching rules for the row, and the columns for each rule.
    # Returns undefined (or default value) if it does not exist.
    getRuleProperty = (row, column, property, defaultValue) ->
        if row.__matchingRules?
            # Filter rules by the given column
            rules = _.filter row.__matchingRules, (rule) -> 
                return true if !rule.columnsAffected?
                return _.contains(rule.columnsAffected, column.name)

            # Get the last property set in a rule.
            value = _.last _.compact _.pluck(rules, property)
            if value?
                return _.compile(value, row)

        return defaultValue

    # Load table options
    $scope.sortBy = $scope.widget.sortBy

    $scope.selectSort = (columnName) ->
        if columnName == $scope.sortBy
            $scope.sortBy = '-' + columnName
        else
            $scope.sortBy = columnName

    $scope.isSorted = (columnName, ascending) ->
        return false if _.isNullOrUndefined($scope.sortBy)

        # Convert everything into an array for simplicity
        sortlist = $scope.sortBy
        if _.isString($scope.sortBy)
            sortlist = [$scope.sortBy]

        return _.some(_.map(sortlist, dataService.parseSortBy), 
            { columnName: columnName, ascending: ascending})

    $scope.getCellProperty = (row, column, propertyName) ->
        ruleValue = getRuleProperty(row, column, propertyName)
        return ruleValue if ruleValue?
        
        if (propertyName of column)
            return _.compile(column[propertyName], row)

        return null

    # Returns the display text for a given row/column
    $scope.getText = (row, column) -> 
        ruleText = getRuleProperty(row, column, 'text')
        return ruleText if ruleText?

        ruleName = getRuleProperty(row, column, 'name')
        columnName = ruleName ? column.name

        numeralFormat = getRuleProperty(row, column, 'numeralformat', column.numeralformat)

        if column.text?
            _.compile(column.text, row)
        else if numeralFormat?
            _.numeralformat(numeralFormat, row[columnName])
        else
            row[columnName]

    # Returns the row span for a given cell
    $scope.getRowSpan = (row, column) ->
        return 1 unless row.__rowSpans?
        return row.__rowSpans[column.name]

    # Table sort (TODO: Optimize mutiple sorts)
    $scope.sortRows = ->
        if $scope.sortedRows?
            if sortFunction?
                result = sortFunction $scope.sortedRows, $scope.sortBy, dataService.sort

                # Can either modify $scope.sortedRows directly, or return a new array
                if _.isArray(result) then $scope.sortedRows = result
            else
                dataService.sort $scope.sortedRows, $scope.sortBy

            $scope.processRowGroups $scope.sortedRows, $scope.columns

    # Process rules on the rows
    $scope.processRules = (rows, rules) -> 
        return if not rules?

        # Each row..
        _.each rows, (row) ->
            row.__matchingRules = []

            # Generate varSub object for mapping columns
            # Maps row properties to an expression to get the value.
            columnNames = _.keys(row)
            columnExps = _.map(columnNames, (columnName) -> 'row["' + columnName + '"]')
            varSubObj = _.zipObject columnNames, columnExps

            # Each rule..
            _.each rules, (rule) ->
                try
                    # Do variable replacement in rule expression, using the current row
                    ruleExp = _.compile(rule.rule, row)

                    # Evaluate the rule
                    ruleTest = eval(ruleExp)

                    if _.isBoolean(ruleTest) and ruleTest == true
                        matchingRule = _.omit(rule, 'rule')

                        # Calculate affected columns
                        columnsAffected = rule.columns
                        if rule.columnsIgnored?
                            if !columnsAffected?
                                columnsAffected = _.pluck($scope.columns, 'name')
                            columnsAffected = _.difference(columnsAffected, rule.columnsIgnored)

                        matchingRule.columnsAffected = columnsAffected
                        
                        # Set matching rule properties
                        row.__matchingRules.push matchingRule
                catch
                    console.log('Table Widget: Error in rule: ' + rule.rule)
                    return


    # Process the rows to collect row groups
    $scope.processRowGroups = (rows, columns) ->

        _.each columns, (column, columnIndex) ->
            currentGroupHead = null
            currentGroupValue = null

            # Loop through rows
            _.each rows, (row, rowIndex) ->
                if !row.__rowSpans? 
                    row.__rowSpans = {}

                if column.groupRows != true
                    # Abort this column and set all the rows to 1
                    row.__rowSpans[column.name] = 1

                else if rowIndex == 0
                    row.__rowSpans[column.name] = 1
                    currentGroupHead = row
                    currentGroupValue = row[column.name]
                else
                    if row[column.name] == currentGroupValue
                        # Increment row span for the group head
                        currentGroupHead.__rowSpans[column.name]++

                        # Set the current row to 0 so it doesn't appear
                        row.__rowSpans[column.name] = 0
                    else
                        row.__rowSpans[column.name] = 1
                        currentGroupHead = row
                        currentGroupValue = row[column.name]

    # Expand regex and wildcard columns and return the new list
    $scope.expandColumns = (columns, headers) ->
        expandedColumns = []
        usedHeaders = ['__index'] # Ignore this column unless explicitly asked for

        pushColumns = (columnTemplate, columnsToAdd) ->
            # Sort columns using 'columnSortFunction' function
            if columnTemplate.columnSortFunction?
                sortFunction = _.jsExec(columnTemplate.columnSortFunction)
                if _.isFunction sortFunction
                    columnsToAdd = sortFunction(columnsToAdd)

            # Clone each column to add
            _.each columnsToAdd, (columnToAdd) ->
                newColumn = _.cloneDeep(columnTemplate)
                newColumn.name = columnToAdd
                expandedColumns.push newColumn
                usedHeaders.push columnToAdd

        _.each columns, (column) ->
            if column.name == '*'
                remainingColumns = _.difference(headers, usedHeaders)
                if column.columnsIgnored?
                    remainingColumns = _.difference(remainingColumns, column.columnsIgnored)
                
                pushColumns(column, remainingColumns)

            else if /^\/.*\/$/i.test(column.name)
                try
                    regex = new RegExp(column.name.substring(1, column.name.length-1), 'i')
                catch
                    console.log('Table Widget: Error in column regex: ' + column.name)
                    return

                remainingColumns = _.difference(headers, usedHeaders)
                if column.columnsIgnored?
                    remainingColumns = _.difference(remainingColumns, column.columnsIgnored)
                matchingColumns = _.filter remainingColumns, (column) ->
                    return regex.test(column)
                
                pushColumns(column, matchingColumns)
            else
                expandedColumns.push column
                usedHeaders.push column.name if column.name?
                

        return expandedColumns

    # Load data from the data source and run the callback
    $scope.loadData = (callback) ->
        # Reset scope variables
        $scope.loading = true
        $scope.dataSourceError = false
        $scope.dataSourceErrorMessage = null

        $scope.dataSource.getData(dsDefinition, (originalData, headers, isUpdate) ->

            $scope.dataSourceError = false
            $scope.dataSourceErrorMessage = null

            # Filter the data if needed
            if $scope.widget.filters?
                data = dataService.filter(originalData, $scope.widget.filters)
            else
                data = originalData

            # Check for no Data
            if _.isEmpty(data)
                $scope.sortedRows = null
                $scope.loading = false

                if $scope.widget.noData?
                    $scope.nodata = _.jsExec($scope.widget.noData)
                else
                    $scope.nodata = null

                return
            else
                $scope.nodata = null

            data = _.cloneDeep(data)
            _.each data, (row, index) -> row.__index = index

            # First load only!
            if (!isUpdate || !$scope.columns?)

                if _.isNullOrUndefined headers
                    headers = _.keys(_.omit(data[0], '$$hashKey'))

                # Use columns object if provided, otherwise generate from headers
                columns = angular.copy($scope.widget.columns)
                if _.isNullOrUndefined columns
                    columns = _.map headers, (header) -> { name: header }

                currentGroup = { name: null, length: 0 }

                # Expand wildcard/regex columns
                columns = $scope.expandColumns(columns, headers)

                # Process columns
                _.each columns, (column) ->
                    # Ensure each column has a label (use name if necessary)
                    if _.isNullOrUndefined column.label
                        column.label = _.titleCase(column.name)
                    else
                        # #value can be used in the inline JS, representing the name property
                        column.label = _.jsExec _.valSub(column.label, column.name)

                    if !_.isNullOrUndefined column.headerTooltip
                        # #value can be used in the inline JS, representing the name property
                        column.headerTooltip = _.jsExec _.valSub(column.headerTooltip, column.name)

                    # Load column groups
                    if column.group?
                        column.group = _.jsExec column.group

                        if column.group == currentGroup.name
                            currentGroup.length++
                        else
                            $scope.columnGroups.push currentGroup

                            # Create new group
                            currentGroup = {
                                name: column.group
                                length: 1
                            }
                    else 
                        if _.isNull(currentGroup.name)
                            currentGroup.length++
                        else
                            # Save the existing group and reset to null
                            $scope.columnGroups.push currentGroup
                            currentGroup = { name: null, length: 1 }
                
                # Save the last group
                if $scope.columnGroups.length > 0 || currentGroup.name?
                    $scope.columnGroups.push currentGroup

                # Save columns
                $scope.columns = columns

            # Process rules
            $scope.processRules(data, $scope.widget.rules)

            # Save sorted rows (will be sorted later if sortBy is provided)
            $scope.sortedRows = data

            callback() if _.isFunction(callback)

        , (errorMessage, status) ->
            # Error callback
            $scope.dataSourceError = true
            $scope.dataSourceErrorMessage = errorMessage
            $scope.nodata = null
            $scope.sortedRows = null
            $scope.columns = null
            callback() if _.isFunction(callback)
        , ->
            $scope.loading = true
        )


    $scope.initialLoad = ->
        $scope.loadData ->
            # Post-load initialization
            $scope.loading = false

            # Watches
            $scope.$watch('sortBy', $scope.sortRows, true)

    $scope.reload = ->
        $scope.dataSource.execute(true)

    # Initialize
    if not _.isUndefined(dsDefinition)
        $scope.initialLoad()
