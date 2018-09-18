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

cyclotronDirectives.directive 'recursive', ($compile) ->
    {
        restrict: 'EACM'
        priority: 100000

        compile: (tElement, tAttr) ->
            contents = tElement.contents().remove()
            compiledContents = null

            return (scope, iElement, iAttr) ->
                compiledContents ?= $compile(contents)
                iElement.append(compiledContents(scope, (clone) -> clone))
    }

cyclotronDirectives.directive 'editorPropertySet', (configService) ->
    {
        restrict: 'EAC'
        scope: 
            model: '='
            excludes: '='
            definition: '='
            dashboard: '='

        templateUrl: '/partials/editor/propertySet.html'

        controller: ($scope, cryptoService) ->

            $scope.booleanOptions = [true, false]

            $scope.optionsCache = {}

            $scope.aceLoaded = (editor) ->
                editor.setOptions({
                    maxLines: Infinity
                    minLines: 10
                    enableBasicAutocompletion: true
                })
                editor.focus()

                encryptButton = $(editor.container).parent().parent().find('.encrypter')

                encryptButton.unbind('click').click ->
                    selectedText = editor.session.getTextRange(editor.getSelectionRange())
                    cryptoService.encrypt(selectedText).then (result) ->
                        editor.session.replace(editor.selection.getRange(), result)
                        $scope.model[encryptButton.data('name')] = editor.getValue()

                editor.getSession().selection.on 'changeSelection', (e) ->
                    selectedText = editor.session.getTextRange(editor.getSelectionRange())
                    
                    if selectedText.length > 0
                        encryptButton.removeClass('hidden')
                    else
                        encryptButton.addClass('hidden')

            # Settings for the Ace Editor
            $scope.aceOptions = (mode) ->
                useWrapMode : true
                showGutter: true
                showPrintMargin: false
                mode: mode
                theme: 'chrome'
                onLoad: $scope.aceLoaded

            $scope.getRemainingProperties = (template, propertiesToRemove) ->
                return null unless template?
                propertiesToRemove = [] unless propertiesToRemove?

                properties = _.cloneDeep _.omit template, propertiesToRemove
                _.each properties, (property, name) ->
                    property['name'] = name

                _.sortBy properties, 'order'

            $scope.addHiddenProperty = (property) ->
                return unless property?

                _.remove $scope.hiddenProperties, (p) ->
                    p.name == property.name
                $scope.visibleProperties.push property

            $scope.clearProperty = (parent, name) ->
                delete parent[name]

                property = _.find $scope.visibleProperties, { name: name }
                if property.defaultHidden
                    _.remove $scope.visibleProperties, { name: name }
                    $scope.hiddenProperties.push property

            $scope.addArrayValue = (parent, name) ->
                parent[name] ?= []
                parent[name].push ''

            $scope.removeArrayValue = (array, index) ->
                array.splice(index, 1)

            $scope.updateArrayValue = (array, index, value) ->
                array[index] = value

            $scope.addHashValue = (parent, name) ->
                parent[name] ?= {}
                parent[name]['key'] = 'value'

            $scope.getHash = (hash) ->
                _.map hash, (value, key) ->
                    { key: key, value: value, _key: key}

            $scope.updateHashKey = (hash, hashItem) ->
                # Set value to new key
                hash[hashItem.key] = hash[hashItem._key]

                # Delete old key
                delete hash[hashItem._key]

                # Update hidden key
                hashItem._key = hashItem.key

            $scope.updateHashValue = (hash, hashItem) ->
                hash[hashItem.key] = hashItem.value

            $scope.removeHashItem = (hash, hashItem) ->
                delete hash[hashItem.key]

            $scope.getOptions = (key, options) ->
                if _.isFunction(options)
                    oldOptions = $scope.optionsCache[key]
                    newOptions = options($scope.dashboard)
                    if oldOptions? && angular.equals(oldOptions, newOptions)
                        return oldOptions
                    else
                        $scope.optionsCache[key] = newOptions
                        return newOptions
                else
                    return options

            update = ->
                if _.isNullOrUndefined($scope.model)
                    $scope.model = {}

                $scope.remainingProperties = $scope.getRemainingProperties($scope.definition, $scope.excludes)

                $scope.visibleProperties = []
                $scope.hiddenProperties = []

                _.each $scope.remainingProperties, (property) ->
                    if !property.defaultHidden || $scope.model?[property.name]?
                        $scope.visibleProperties.push property
                    else
                        $scope.hiddenProperties.push property

            # Initialize
            $scope.$watch 'definition', (newDefinition) ->
                update() unless _.isEmpty(newDefinition)

            $scope.$watch 'model', (model) ->
                update() unless _.isEmpty(model)

    }
