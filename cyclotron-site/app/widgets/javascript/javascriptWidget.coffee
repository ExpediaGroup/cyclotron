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

    $scope.widgetTitle = -> _.jsExec($scope.widget.title)

    # Load data source
    dsDefinition = dashboardService.getDataSource($scope.dashboard, $scope.widget)
    $scope.dataSource = dataService.get(dsDefinition)

    $scope.data = null

    # Create user-defined Javascript Object
    $scope.jsObject = _.executeFunctionByName($scope.widget.functionName, window, $scope.widget)

    $scope.initialLoad = ->
        # Reset scope variables
        $scope.loading = true
        $scope.dataSourceError = false
        $scope.dataSourceErrorMessage = null

        $scope.dataSource.getData dsDefinition, (data, headers, isUpdate) ->

            $scope.dataSourceError = false
            $scope.dataSourceErrorMessage = null

            # Always ignore empty data sets, even on update
            if _.isEmpty(data)
                $scope.loading = false
                return

            # Filter the data with the widget filters if needed
            if $scope.widget.filters?
                data = dataService.filter(data, $scope.widget.filters)

            # Sort the data if the widget has sortBy
            if $scope.widget.sortBy?
                data = dataService.sort(data, $scope.widget.sortBy)

            $scope.data = data
            $scope.loading = false

        , (errorMessage, status) ->
            # Error callback
            $scope.loading = false
            $scope.dataSourceError = true
            $scope.dataSourceErrorMessage = errorMessage
            $scope.data = null
        , ->
            # Loading callback
            $scope.loading = true

    $scope.reload = ->
        $scope.dataSource.execute(true)

    # Initialize
    if _.isUndefined(dsDefinition)
        $scope.data = null
    else
        $scope.initialLoad()
