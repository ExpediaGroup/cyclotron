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

cyclotronDirectives.directive 'collapseMenu', (filterFilter) -> 
    {
        restrict: 'EAC'
        scope: 
            items: '='
            filter: '='
            initialSelection: '='
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

            # Find and select an item by name
            $scope.findItem = (name) ->
                _.each $scope.items, (section) ->
                    if section.name == name
                        $scope.selectSection section
                        return false

                    child = _.find section.children, { name: name }
                    if child?
                        $scope.selectChild child, section
                        return false

            $scope.$watch 'filter', (filter) ->
                $scope.isFiltered = not _.isEmpty filter

            $scope.$on 'feelingLucky', ->
                # Select the first item that matches the current filter
                # Use filterFilter to apply the filter to the items
                matchingSections = filterFilter($scope.items, $scope.filter)
                if matchingSections?.length > 0
                    firstSection = _.first matchingSections

                    # Check to see if the Section matches on its own, or because of a Child
                    # Remove children and run filter again.
                    firstSectionSolo = _.cloneDeep firstSection
                    delete firstSectionSolo.children
                    if filterFilter([firstSectionSolo], $scope.filter).length > 0
                        $scope.selectSection firstSection
                    else
                        # Parent section didn't match, so check children
                        matchingChildren = filterFilter(firstSection.children, $scope.filter)
                        if matchingChildren?.length > 0
                            $scope.selectChild _.first(matchingChildren), firstSection

            $scope.$on 'findItem', (event, args) ->
                $scope.findItem(args.name)

            # Initialize
            if $scope.initialSelection?
                $scope.findItem $scope.initialSelection
            else
                $scope.selectSection _.first $scope.items
        
        link: (scope, element, attrs) ->
            return
    }
