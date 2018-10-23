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

cyclotronDirectives.directive 'newUserMessage', ->
    {
        restrict: 'E'
        scope: { }
        templateUrl: 'partials/newUserMessage.html'

        link: (scope, element, attrs) ->
            return

        controller: ($scope, $timeout, configService, logService, userService) ->

            $scope.message = configService.newUser.welcomeMessage
            $scope.iconClass = configService.newUser.iconClass

            $scope.canDisplay = ->
                configService.newUser.enableMessage and userService.isNewUser

            $scope.dismiss = ->
                userService.notNewUser()

            # Automatically remove New User quality after a fixed period of time on the site
            # This won't hide the message if it's currently displayed
            duration = configService.newUser.autoDecayDuration
            if _.isNumber duration
                t = $timeout _.partial(userService.notNewUser, false), duration * 1000
            
    }
