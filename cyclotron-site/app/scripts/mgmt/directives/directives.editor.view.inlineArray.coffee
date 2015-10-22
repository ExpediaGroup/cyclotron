###
# Copyright (c) 2013-2015 the original author or authors.
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

cyclotronDirectives.directive 'editorViewInlineArray', ->
    {
        restrict: 'EAC'
        scope:
            model: '='
            definition: '='
            factory: '&'
            headingfn: '&'

        templateUrl: '/partials/editor/inlineArray.html'
        transclude: true

        controller: ($scope) ->
           
            $scope.removeItem = (index) ->
                $scope.model.splice(index, 1)

            # Moves an item to a new location
            $scope.moveItem = (oldIndex, newIndex) ->
                return unless $scope.model?
                return if newIndex < 0 || newIndex >= $scope.model.length
                
                item = $scope.model.splice(oldIndex, 1)[0]
                $scope.model.splice(newIndex, 0, item)

            $scope.moveUp = (index) ->
                $scope.moveItem(index, index - 1)

            $scope.moveDown = (index) ->
                $scope.moveItem(index, index + 1)

            $scope.addNewObject = ->
                $scope.model = [] unless $scope.model?
                if $scope.definition.sample?
                    $scope.model.push _.cloneDeep($scope.definition.sample)
                else 
                    $scope.model.push {}

    }
