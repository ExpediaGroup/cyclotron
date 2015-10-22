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
# Number Widget
#
# Displays one or more numbers, either hardcoded or pulled from a data source.
#
# When using the data source, the first row only will be used.  If multiple
# rows are returned, the filters/sortBy properties can be used to ensure the 
# correct row is positioned first.  For example, to show a single real-time number,
# sort by time descending.
#

cyclotronApp.controller 'NumberWidget', ($scope, dashboardService, dataService) ->

    $scope.loading = false
    $scope.dataSourceError = false
    $scope.dataSourceErrorMessage = null
    $scope.orientation = $scope.widget.orientation ? 'vertical'

    $scope.widgetTitle = -> _.jsExec($scope.widget.title)

    $scope.linkTarget = ->
        if $scope.dashboard.openLinksInNewWindow == false then '_self' else '_blank'

    $scope.getClass = ->
        if $scope.numbers.length == 1
            return 'orientation-vertical'
        else
            return 'orientation-' + $scope.orientation

    $scope.getUrl = ->
        return '' if _.isEmpty($scope.widget.link)

        url = $scope.widget.link

        if $scope.widget.link.indexOf('http') != 0
            url = 'http://' + url

        return $scope.$sce.trustAsResourceUrl(url)

    # Compiles the numbers and updates the widget
    $scope.compileNumbers = (row) ->
        $scope.numbers = _.map $scope.widget.numbers, (item, index) ->
            {
                number: _.compile(item.number, row)
                prefix: _.compile(item.prefix, row)
                suffix: _.compile(item.suffix, row)
                color: _.compile(item.color, row)
                tooltip: _.compile(item.tooltip, row)
                icon: _.compile(item.icon, row)
                iconColor: _.compile(item.iconColor, row)
                iconTooltip: _.compile(item.iconTooltip, row)
            }

        # Set flag for single number or not
        $scope.singleNumber = ($scope.numbers.length == 1)

    $scope.loadData = ->
        $scope.loading = true
        $scope.dataSourceError = false
        $scope.dataSourceErrorMessage = null

        # Load data source
        dsDefinition = dashboardService.getDataSource($scope.dashboard, $scope.widget)
        $scope.dataSource = dataService.get(dsDefinition)

        # Load data from the data source and get the field
        $scope.dataSource.getData dsDefinition, (data, headers, isUpdate) ->

            $scope.dataSourceError = false
            $scope.dataSourceErrorMessage = null

            # Filter the data if the widget has filters
            if $scope.widget.filters?
                data = dataService.filter(data, $scope.widget.filters)

            # Sort the data if the widget has sortBy
            if $scope.widget.sortBy?
                data = dataService.sort(data, $scope.widget.sortBy)


            # Check for no Data
            if _.isEmpty(data) && $scope.widget.noData?
                $scope.nodata = _.jsExec($scope.widget.noData)
            else
                $scope.nodata = null

                # Compile display with the first row
                $scope.compileNumbers data[0]

            $scope.loading = false

        , (errorMessage, status) ->
            # Error callback
            $scope.loading = false
            $scope.dataSourceError = true
            $scope.dataSourceErrorMessage = errorMessage
            $scope.nodata = null
        , ->
            # Loading callback
            $scope.loading = true

    $scope.reload = ->
        $scope.dataSource.execute(true)

    # Initialize
    if $scope.widget.dataSource?
        $scope.loadData()
    else
        # Compile display with no data source
        $scope.compileNumbers {}
