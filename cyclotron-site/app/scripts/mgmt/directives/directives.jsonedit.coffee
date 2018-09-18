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

cyclotronDirectives.directive 'jsonedit', ->
    {
        restrict: 'EAC'
        scope: 
            model: '='
        replace: true 
        template: '<div ui-ace="aceOptions" ng-model="jsonValue"></div>'

        controller: ($scope, dashboardService) ->

            $scope.aceLoaded = (editor) ->
                editor.setOptions {
                    maxLines: Infinity
                    minLines: 10
                    enableBasicAutocompletion: true
                }
                editor.focus()

            # Settings for the JSON Editor
            $scope.aceOptions = 
                useWrapMode : true
                showGutter: true
                showPrintMargin: false
                mode: 'json'
                theme: 'chrome'
                onLoad: $scope.aceLoaded

            $scope.jsonValue = dashboardService.toString $scope.model

            $scope.$watch 'jsonValue', (json) ->
                # Catch parse errors due to incomplete objects
                try
                    if $scope.model?
                        _.replaceInside $scope.model, dashboardService.parse(json)
                    else
                        $scope.model = dashboardService.parse(json)
    }
