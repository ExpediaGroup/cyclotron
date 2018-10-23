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
# PushDashboard controller -- for modal dialog
#
cyclotronApp.controller 'PushDashboardController', ($scope, $uibModalInstance, $q, $http, $timeout, analyticsService, configService, dashboardService, focusService, userService) ->

    $scope.environmentsForPush = _.reject configService.cyclotronEnvironments, { canPush: false }

    $scope.fields = {}

    $scope.updateFocus = ->
        $timeout ->
            # Load cached username
            if userService.cachedUsername?
                $scope.fields.username = userService.cachedUsername
                focusService.focus 'focusPassword', $scope
            else 
                focusService.focus 'focusUsername', $scope

    # Login to the remote server if required.
    $scope.login = ->
        deferred = $q.defer()

        if !$scope.fields.pushLocation.requiresAuth
            deferred.resolve(null)
        else 
            targetUrl = new URI($scope.fields.pushLocation.serviceUrl)
                .segment '/users/login'
                .protocol ''
                .toString()

            loginPromise = $http.post(targetUrl, { 
                username: $scope.fields.username, 
                password: $scope.fields.password 
            })

            loginPromise.success (session) ->
                $scope.fields.password = ''
                deferred.resolve(session.key)
                
            loginPromise.error (error) ->
                $scope.fields.password = ''
                focusService.focus 'focusPassword', $scope

                if _.isObject(error)
                    alertify.error('Login Error: ' + error.name, 2500)    
                else
                    alertify.error('Login Error: ' + error.toString(), 2500)
                deferred.reject(error)
            
        return deferred.promise

    $scope.push = ->

        p = $scope.login()

        p.then (sessionKey) ->
            q = dashboardService.pushToService($scope.editor.dashboardWrapper, $scope.fields.pushLocation.serviceUrl, sessionKey)
            q.then ->
                analyticsService.recordEvent 'pushDashboard', { dashboardName: $scope.editor.dashboardWrapper.name, destination: $scope.fields.pushLocation.serviceUrl }
                alertify.log("Pushed Dashboard to " + $scope.fields.pushLocation.name, 2500)

                $uibModalInstance.close()

            q.catch (error) ->
                alertify.error('Error pushing Dashboard: ' + error, 2500)
        
    $scope.cancel = ->
        $uibModalInstance.dismiss('cancel')
