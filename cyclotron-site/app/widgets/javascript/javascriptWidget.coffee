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
# Javascript Widget
#
# Optionally allows a dataService property to load data
# Support dataServices that return object-based data:
#
#    Object-based (keys are columns):
#        [ 
#            {color: "red", number: 1, state: "WA"}
#            {color: "green", number: 41, state: "CA"}
#        ]
# Optionally, headers can be provided by the callback as well
#

cyclotronApp.controller 'JavascriptWidget', ($scope, dashboardService, dataService) ->

    $scope.loading = false
    $scope.dataSourceError = false
    $scope.dataSourceErrorMessage = null

    $scope.data = null

    $scope.jsObject = _.executeFunctionByName($scope.widget.functionName, window, $scope.widget)

    $scope.reload = ->
        $scope.dataSource.execute(true)

    # Load Data Source
    dsDefinition = dashboardService.getDataSource $scope.dashboard, $scope.widget
    $scope.dataSource = dataService.get dsDefinition
    
    # Initialize
    if $scope.dataSource?
        $scope.dataVersion = 0
        $scope.loading = true

        # Data Source (re)loaded
        $scope.$on 'dataSource:' + dsDefinition.name + ':data', (event, eventData) ->
            return unless eventData.version > $scope.dataVersion
            $scope.dataVersion = eventData.version

            $scope.dataSourceError = false
            $scope.dataSourceErrorMessage = null

            data = eventData.data[dsDefinition.resultSet].data

            # Always ignore empty data sets, even on update
            if _.isEmpty(data)
                $scope.loading = false
                return

            # Filter the data if the widget has "filters"
            if $scope.widget.filters?
                data = dataService.filter(data, $scope.widget.filters)

            # Sort the data if the widget has "sortBy"
            if $scope.widget.sortBy?
                data = dataService.sort(data, $scope.widget.sortBy)

            $scope.data = data
            $scope.loading = false

        # Data Source error
        $scope.$on 'dataSource:' + dsDefinition.name + ':error', (event, data) ->
            $scope.dataSourceError = true
            $scope.dataSourceErrorMessage = data.error
            $scope.nodata = null
            $scope.loading = false

        # Data Source loading
        $scope.$on 'dataSource:' + dsDefinition.name + ':loading', ->
            $scope.loading = true
        
        # Initialize the Data Source
        $scope.dataSource.init dsDefinition 
