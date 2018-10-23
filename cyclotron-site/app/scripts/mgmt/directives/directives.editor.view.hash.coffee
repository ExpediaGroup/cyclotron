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

cyclotronDirectives.directive 'editorViewHash', -> 
    {
        restrict: 'EAC'
        scope:
            label: '@'
            model: '='
        templateUrl: '/partials/editor/hash.html'

        controller: ($scope) ->

            $scope.$watch 'model', (model) ->
                $scope.hashItems = [] unless model?

            $scope.addHashValue = ->
                $scope.model = {} unless $scope.model?
                $scope.hashItems.push { key: '', value: '', _key: ''}

            $scope.updateHashKey = (hashItem) ->
                # Set value to new key
                $scope.model[hashItem.key] = $scope.model[hashItem._key] ? ''

                # Delete old key
                delete $scope.model[hashItem._key]

                # Update hidden key
                hashItem._key = hashItem.key

            $scope.updateHashValue = (hashItem) ->
                $scope.model[hashItem.key] = hashItem.value

            $scope.removeHashItem = (hashItem) ->
                delete $scope.model[hashItem.key]
                _.remove $scope.hashItems, (item) ->
                    item == hashItem

            # Initialize
            if $scope.model?
                $scope.hashItems = _.map $scope.model, (value, key) -> 
                    { key: key, value: value, _key: key}
                $scope.hashItems = _.filter $scope.hashItems, (hashItem) -> 
                    hashItem._key != '$$hashKey'
            else
                $scope.hashItems = []

        link: (scope, element, attrs) ->
            scope.label ?= 'Item'
            return

    }
