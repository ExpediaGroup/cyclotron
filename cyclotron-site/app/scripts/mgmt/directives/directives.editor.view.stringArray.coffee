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

cyclotronDirectives.directive 'editorViewStringArray', -> 
    {
        restrict: 'EAC'
        scope: 
            label: '@'
            model: '='
            definition: '='

        templateUrl: '/partials/editor/stringArray.html'

        controller: ($scope) ->

            $scope.addArrayValue = ->
                $scope.model = [] unless $scope.model?
                $scope.model.push ''
            
            $scope.updateArrayValue = (index, value) ->
                $scope.model[index] = value

            $scope.removeArrayValue = (index) ->
                $scope.model.splice(index, 1)
        
        link: (scope, element, attrs) ->

            scope.label ?= 'Item'
            return
            
    }
