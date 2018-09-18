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

cyclotronDirectives.directive 'editorViewObjectArray', ->
    {
        restrict: 'EAC'
        scope:
            label: '@'
            substate: '@'
            model: '='
            headingfn: '&'

        templateUrl: '/partials/editor/objectArray.html'
        transclude: true

        controller: ($scope) ->

            $scope.removeItem = (index) ->
                $scope.model.splice(index, 1)

            # Clones an item
            $scope.cloneItem = (index) ->
                cloned = angular.copy($scope.model[index])
                spliceIndex = index
                if cloned.name?
                    cloned.name += '_clone'
                    clonedName = cloned.name 
                    duplicate = true
                    cloneIndex = 1
                    while duplicate
                        duplicateIndex = _.findIndex($scope.model, { 'name': cloned.name })
                        if duplicateIndex == -1
                            duplicate = false
                        else
                            cloneIndex++
                            spliceIndex = duplicateIndex
                            cloned.name = clonedName + cloneIndex
                $scope.model.splice(spliceIndex+1, 0, cloned)

            $scope.goToSubState = (state, item, index) ->
                $scope.$parent.goToSubState(state, item, index)

            # Initialize
            $scope.model = [] unless $scope.model?

        link: (scope, element, attrs) ->

            scope.label ?= 'Item'
            return

    }
