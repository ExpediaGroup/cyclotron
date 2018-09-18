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

    $scope.orientation = $scope.widget.orientation ? 'vertical'

    $scope.numberCount = $scope.widget.numbers?.length || 0
    $scope.isHorizontal = $scope.widget.orientation == 'horizontal'

    # Flip horizontal/vertical if the widgets are auto-sized
    if $scope.numberCount <= 4 and $scope.widget.autoSize != false
        $scope.isHorizontal = !$scope.isHorizontal      

    $scope.linkTarget = ->
        if $scope.dashboard.openLinksInNewWindow == false then '_self' else '_blank'

    $scope.getClass = (number) ->
        c = ''
        if $scope.isHorizontal
            c = 'orientation-horizontal'
        else
            c = 'orientation-vertical'

        if _.isFunction(number.onClick)
            c += ' actionable'

        return c

    $scope.getUrl = ->
        return '' if _.isEmpty($scope.widget.link)

        url = $scope.widget.link

        if $scope.widget.link.indexOf('http') != 0
            url = 'http://' + url

        return $scope.$sce.trustAsResourceUrl(url)

    # Compiles the numbers and updates the widget
    $scope.compileNumbers = (row) ->
        numbers = _.map $scope.widget.numbers, (item, index) ->
            {
                number: _.compile(item.number, row)
                prefix: _.compile(item.prefix, row)
                suffix: _.compile(item.suffix, row)
                color: _.compile(item.color, row)
                tooltip: _.compile(item.tooltip, row)
                icon: _.compile(item.icon, row)
                iconColor: _.compile(item.iconColor, row)
                iconTooltip: _.compile(item.iconTooltip, row)
                onClick: _.jsEval _.compile(item.onClick, row)
            }      

        if $scope.numbers?
            _.each numbers, (number, index) ->
                _.assign($scope.numbers[index], number)
        else
            $scope.numbers = numbers


    $scope.onClickEvent = (number) ->
        if _.isFunction(number.onClick)
            # Invoke event handler; pass the number object as an argument
            number.onClick({ number })

    $scope.reload = ->
        $scope.dataSource.execute(true)

    # Load Data Source
    dsDefinition = dashboardService.getDataSource $scope.dashboard, $scope.widget
    $scope.dataSource = dataService.get dsDefinition
    
    # Initialize
    if $scope.dataSource?
        $scope.dataVersion = 0
        $scope.widgetContext.loading = true

        # Data Source (re)loaded
        $scope.$on 'dataSource:' + dsDefinition.name + ':data', (event, eventData) ->
            return unless eventData.version > $scope.dataVersion
            $scope.dataVersion = eventData.version

            $scope.widgetContext.dataSourceError = false
            $scope.widgetContext.dataSourceErrorMessage = null

            data = eventData.data[dsDefinition.resultSet].data
            data = $scope.filterAndSortWidgetData(data)

            # Check for no data
            if data?

                # Compile display with the first row
                $scope.compileNumbers data[0]

            $scope.widgetContext.loading = false

        # Data Source error
        $scope.$on 'dataSource:' + dsDefinition.name + ':error', (event, data) ->
            $scope.widgetContext.dataSourceError = true
            $scope.widgetContext.dataSourceErrorMessage = data.error
            $scope.widgetContext.nodata = null
            $scope.widgetContext.loading = false

        # Data Source loading
        $scope.$on 'dataSource:' + dsDefinition.name + ':loading', ->
            $scope.widgetContext.loading = true
        
        # Initialize the Data Source
        $scope.dataSource.init dsDefinition

    else
        # Compile display with no data source
        $scope.widgetContext.allowExport = false
        $scope.compileNumbers {}
