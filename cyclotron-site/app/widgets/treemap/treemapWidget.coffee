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
# Treemap Widget
#
cyclotronApp.controller 'TreemapWidget', ($scope, dashboardService, dataService) ->

    $scope.legendHeight = $scope.widget.legendHeight || 30

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
