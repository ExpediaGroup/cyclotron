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
# JSON Widget
#
cyclotronApp.controller 'JsonWidget', ($scope, aceService, configService, dashboardService, dataService) ->

    $scope.jsonData = null;

    $scope.aceLoaded = (editor) ->
        editor.setOptions {
            #maxLines: Infinity
            highlightActiveLine: false
        }
        editor.setReadOnly true

    # Settings for the JSON Editor
    $scope.aceOptions = 
        useWrapMode: false
        showGutter: true
        showPrintMargin: false
        
        mode: 'json'
        theme: 'chrome'
        onLoad: $scope.aceLoaded

    themeSettings = configService.dashboard.properties.theme.options[$scope.widget.theme]
    if $scope.widget.theme? and themeSettings?.aceTheme
        $scope.aceOptions.theme = themeSettings.aceTheme

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
            if $scope.widgetContext.nodata == true
                $scope.jsonData = null
            else
                $scope.jsonData = dashboardService.toString data
                console.log($scope.jsonData)

            $scope.widgetContext.loading = false

        # Data Source error
        $scope.$on 'dataSource:' + dsDefinition.name + ':error', (event, data) ->
            $scope.widgetContext.dataSourceError = true
            $scope.widgetContext.dataSourceErrorMessage = data.error
            $scope.widgetContext.nodata = null
            $scope.widgetContext.loading = false
            $scope.jsonData = null

        # Data Source loading
        $scope.$on 'dataSource:' + dsDefinition.name + ':loading', ->
            $scope.widgetContext.loading = true
        
        # Initialize the Data Source
        $scope.dataSource.init dsDefinition
