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
# Treemap Widget
#
cyclotronApp.controller 'TreemapWidget', ($scope, dashboardService, dataService) ->

    $scope.loading = false
    $scope.dataSourceError = false
    $scope.dataSourceErrorMessage = null

    $scope.legendHeight = $scope.widget.legendHeight || 30

    $scope.widgetTitle = -> _.jsExec($scope.widget.title)

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
                $scope.nodata = _.jsExec $scope.widget.noData
            else
                $scope.nodata = null

                # (Re)compile variables
                $scope.labelProperty = _.jsExec $scope.widget.labelProperty
                if _.isEmpty $scope.labelProperty
                    $scope.labelProperty = 'name'

                $scope.valueProperty = _.jsExec $scope.widget.valueProperty
                if _.isEmpty $scope.valueProperty
                    $scope.valueProperty = 'value'

                $scope.valueDescription = _.jsExec $scope.widget.valueDescription
                if _.isEmpty $scope.valueDescription
                    $scope.valueDescription = 'value'

                $scope.valueFormat = _.jsExec $scope.widget.valueFormat
                if _.isEmpty $scope.valueFormat
                    $scope.valueFormat = '0,0.[0]'

                $scope.colorDescription = _.jsExec $scope.widget.colorDescription
                if _.isEmpty $scope.colorDescription
                    $scope.colorDescription = 'color value'

                $scope.colorProperty = _.jsExec $scope.widget.colorProperty
                $scope.colorStops = _.compile $scope.widget.colorStops

                $scope.showLegend = _.jsExec $scope.widget.showLegend
                $scope.colorFormat = _.jsExec $scope.widget.colorFormat
                if _.isEmpty $scope.colorFormat
                    $scope.colorFormat = '0,0.[0]'

                $scope.treeData = _.cloneDeep data[0]

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
