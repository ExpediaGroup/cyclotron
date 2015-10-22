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
# Stoplight Widget
#
cyclotronApp.controller 'StoplightWidget', ($scope, dashboardService, dataService) ->
    $scope.loading = false

    $scope.widgetTitle = -> _.jsExec($scope.widget.title)

    $scope.activeColor = null

    $scope.evalColors = (row) ->
        rules = $scope.widget.rules
        return unless rules?

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

    $scope.loadData = ->
        $scope.loading = true
        $scope.dataSourceError = false
        $scope.dataSourceErrorMessage = null

        # Load data source
        dsDefinition = dashboardService.getDataSource($scope.dashboard, $scope.widget)
        $scope.dataSource = dataService.get(dsDefinition)
        $scope.loading = true

        # Load data from the data source
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

                # Load the data
                $scope.evalColors(_.first(data))

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

    # Data Source
    if $scope.widget.dataSource?
        $scope.loadData()
    else
        $scope.evalColors({})
