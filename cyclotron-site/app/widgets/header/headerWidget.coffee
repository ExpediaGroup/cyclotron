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
# Header Widget
#
cyclotronApp.controller 'HeaderWidget', ($scope, $sce, configService) ->
    # Override the widget feature of exporting data, since there is no data
    $scope.widgetContext.allowExport = false
    
    $scope.headerTitle = _.compile $scope.widget.headerTitle

    # Load user-specified format if defined
    if $scope.headerTitle.showTitle == true 
        $scope.showTitle = true
        $scope.title = _.jsExec($scope.widget.title) || _.jsExec($scope.dashboard.displayName) || $scope.dashboard.name

        $scope.pageNameSeparator ?= ''

    if $scope.widget.customHtml?
        $scope.showCustomHtml = true

        $scope.customHtml = ->
            $sce.trustAsHtml _.jsExec($scope.widget.customHtml)

    $scope.showParameters = $scope.widget.parameters?.showParameters == true

    # If Parameters are show in the Widget...
    if $scope.showParameters
        $scope.showUpdateButton = $scope.widget.parameters.showUpdateButton
        $scope.updateButtonLabel = $scope.widget.parameters.updateButtonLabel || 'Update'

        $scope.parameters = _.filter $scope.dashboard.parameters, { editInHeader: true }

        # Filter further using the Widget's parametersIncluded property
        if _.isArray($scope.widget.parameters.parametersIncluded) and $scope.widget.parameters.parametersIncluded.length > 0
            $scope.parameters = _.filter $scope.parameters, (param) ->
                _.contains $scope.widget.parameters.parametersIncluded, param.name

        updateEventHandler = _.jsEval $scope.widget.parameters.updateEvent
        if !_.isFunction(updateEventHandler) then updateEventHandler = null

        $scope.updateButtonClick = ->
            updateEventHandler() unless _.isNull updateEventHandler
            
