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

cyclotronDirectives.directive 'collapseMenu', ($parse) -> 
    {
        restrict: 'EAC'
        scope: 
            items: '='
            selectItem: '&'

        templateUrl: '/partials/help/collapseMenu.html'
        controller: ($scope) ->

            $scope.unselectAll = ->
                _.each $scope.items, (item) ->
                    item.selected = item.expanded = false
                    _.each item.children, (child) ->
                        child.selected = false
                        return
                    return

            $scope.selectSection = (section) ->
                $scope.unselectAll()
                section.selected = true
                section.expanded = true
                $scope.selectItem {'item': section}

            $scope.selectChild = (child, section) ->
                $scope.unselectAll()
                child.selected = true
                section.expanded = true
                $scope.selectItem {'item': child}
           
            # Initialize
            $scope.selectSection _.first $scope.items
        
        link: (scope, element, attrs) ->
            return
    }
