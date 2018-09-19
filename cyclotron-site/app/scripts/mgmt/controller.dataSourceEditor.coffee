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
# Gui Editor - Data Source controller.
#
cyclotronApp.controller 'DataSourceEditorController', ($scope, $state, $stateParams, configService, dashboardService) ->

    # Store some configuration settings for the Editor
    $scope.dashboardProperties = configService.dashboard.properties
    $scope.allDataSources = configService.dashboard.properties.dataSources.options

    $scope.$watch 'editor.selectedItemIndex', ->
        $scope.dataSourceIndex = $scope.editor.selectedItemIndex
        $scope.dataSource = $scope.editor.selectedItem

    $scope.combinedDataSourceProperties = (dataSource) ->
        general = _.omit configService.dashboard.properties.dataSources.properties, 'type'

        if dataSource.type? and $scope.allDataSources[dataSource.type]?
            specific = $scope.allDataSources[dataSource.type].properties
            return _.defaults specific, general
        else
            return {}

    $scope.dataSourceMessage = ->
        $scope.allDataSources[$scope.dataSource.type]?.message

    return
