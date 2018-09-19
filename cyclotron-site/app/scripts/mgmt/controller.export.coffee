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
# Export controller.
#
cyclotronApp.controller 'ExportController', ($scope, $state, $stateParams, $location, $timeout, $uibModal, configService, dashboardService, exportService) ->

    $scope.exportFormats = configService.exportFormats
    $scope.exportFormat = _.first $scope.exportFormats

    $scope.exporting = false
    $scope.parameters = $location.search()

    $scope.$watch 'parameters', (parameters, oldParameters) ->
        deletedKeys = _.difference(_.keys(oldParameters), _.keys(parameters))
        _.each deletedKeys, (key) ->
            $location.search(key, null)
            
        _.each parameters, (value, key) ->
            $location.search(key, value)

    , true

    $scope.export = ->
        $scope.exporting = true

        # Add default, built-in parameters
        exportParameters = _.clone $location.search()
        exportParameters.browsercheck = false
        exportParameters.exporting = true

        exportService.exportAsync $scope.dashboardName, $scope.exportFormat.value, exportParameters, (result) ->
            $scope.checkStatus(result.statusUrl)


    $scope.checkStatus = (statusUrl) ->
        exportService.getStatus statusUrl, (status) ->
            status.humanDuration = moment.duration(status.duration).humanize()

            $scope.exportStatus = status
            if status.status == 'running'
                $timeout(_.wrap(statusUrl, $scope.checkStatus), 2500, true)
            else
                $scope.exporting = false

    # Initialization

    if _.isEmpty $stateParams.dashboardName
        $scope.dashboardName = ""
    else 
        # Get the latest revision
        q = dashboardService.getDashboard($stateParams.dashboardName)
        q.then (dashboardWrapper) ->
            $scope.dashboardName = $stateParams.dashboardName
            
        q.catch (error) ->
            switch error.status
                when 401
                    $scope.login(true).then ->
                        viewPermissionDenied()
                when 403
                    viewPermissionDenied()
            
    viewPermissionDenied = ->
        modalInstance = $uibModal.open {
            templateUrl: '/partials/viewPermissionDenied.html'
            scope: $scope
            controller: 'GenericErrorModalController'
            backdrop: 'static'
            keyboard: false
        }
