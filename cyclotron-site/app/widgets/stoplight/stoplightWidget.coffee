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
# Stoplight Widget
#
cyclotronApp.controller 'StoplightWidget', ($scope, dashboardService, dataService) ->
    
    $scope.activeColor = null

    $scope.evalColors = (row) ->
        rules = $scope.widget.rules
        return unless rules?
        
        $scope.tooltip = _.compile($scope.widget.tooltip, row)
        
        if rules.red?
            red = _.compile(rules.red, row)
            if red == true then return $scope.activeColor = 'red'
        if rules.yellow?
            yellow = _.compile(rules.yellow, row)
            if yellow == true then return $scope.activeColor = 'yellow'
        if rules.green
            green = _.compile(rules.green, row)
            if green == true then return $scope.activeColor = 'green'
            return

        $scope.activeColor = null
    
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
                # Load the data
                $scope.evalColors(_.first(data))

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
        $scope.widgetContext.allowExport = false
        $scope.evalColors({})
