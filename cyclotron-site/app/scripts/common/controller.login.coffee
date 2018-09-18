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
# Login controller -- for login modal dialog
#
cyclotronApp.controller 'LoginController', ($scope, $uibModalInstance, $localForage, configService, focusService, userService) ->

    $scope.credentials = {}
    $scope.loginError = false
    $scope.loggingIn = false

    $scope.loginMessage ?= configService.authentication.loginMessage

    # Load cached username
    if userService.cachedUsername?
        $scope.credentials.username = userService.cachedUsername
        focusService.focus 'focusPassword', $scope
    else 
        focusService.focus 'focusUsername', $scope

    $scope.canLogin = ->
        return !_.isEmpty($scope.credentials.username) && !_.isEmpty($scope.credentials.password) && !$scope.loggingIn

    $scope.login = ->
        return if $scope.loggingIn
        $scope.loginError = false
        $scope.loggingIn = true
        loginPromise = userService.login $scope.credentials.username, $scope.credentials.password

        loginPromise.then (session) ->
            $scope.credentials.password = ''
            $uibModalInstance.close(session)

        loginPromise.catch (error) ->
            $scope.loginError = true
            $scope.loggingIn = false
            $scope.credentials.password = ''
            focusService.focus 'focusPassword', $scope

    $scope.cancel = ->
        $uibModalInstance.dismiss('cancel')
