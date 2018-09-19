###
# Copyright (c) 2016-2018 the original author or authors.
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
# Accordion for Dashboard Sidebar
# Adapted from http://jsfiddle.net/hanspc/TBz9F/
#
    
cyclotronDirectives.directive 'sidebarAccordion', ($sce, $timeout) ->
    {
        restrict: 'EAC'
        controller: ($scope, $attrs) ->

            this.groups = []

            $scope.trustHtml = (html) ->
                $sce.trustAsHtml(html)

            # Ensure that all the groups in this accordion are closed
            this.closeOthers = (openGroup) ->
                angular.forEach this.groups, (group) ->
                    group.isOpen = false unless group == openGroup
                        
                this.calcHeight()
                        
            # Watch for height changes
            that = this
            $scope.$watch 'accordionHeight', (value) ->
                that.calcHeight()
                
            this.calcHeight = ->
                height = _.reduce this.groups, (sum, group) ->
                    sum + group.returnHeight()
                , 0
                
                that.panelHeight = $scope.getAccordionHeight() - height

            # This is called from the accordion-group directive to add itself to the accordion
            this.addGroup = (groupScope) ->
                that = this
                this.groups.push(groupScope)

                groupScope.$on '$destroy', (event) ->
                    that.removeGroup(groupScope)

            # This is called from the accordion-group directive when to remove itself
            this.removeGroup = (group) ->
                index = this.groups.indexOf(group)
                if index != -1
                    this.groups.splice(index, 1)

            return 

        transclude: true,
        replace: false,
        templateUrl: '/partials/sidebarAccordion.html'
        link: (scope, element, attrs) ->
            scope.getAccordionHeight = -> $(element).height()

            # Track height of accordion
            sizer = ->
                scope.accordionHeight = scope.getAccordionHeight()
            
            $(element).on 'resize', _.debounce(-> 
                scope.$apply sizer
            , 100)

            # Run in 100ms
            timer = $timeout sizer, 100

            scope.$on '$destroy', ->
                $timeout.cancel timer
                $(element).off 'resize'
    }

cyclotronDirectives.directive 'accordionGroup', ->
    {
        require: '^sidebarAccordion'
        restrict: 'EA'
        transclude: true
        replace: true
        templateUrl: '/partials/sidebarAccordionGroup.html'
        scope:
            heading: '@'
            isOpen: '=?'
            isDisabled: '=?'

        controller: ->
            this.setHeading = (element) ->
                this.heading = element

        link: (scope, element, attrs, accordionController) ->
            accordionController.addGroup(scope)

            scope.$watch 'isOpen', (value) ->
                if value
                    accordionController.closeOthers(scope)

            scope.toggleOpen = ->
                if !scope.isDisabled
                    scope.isOpen = !scope.isOpen
                
            scope.returnHeight = ->
                element.find('.panel-heading').outerHeight(true)
            
            scope.$watch (-> accordionController.panelHeight), (value) ->
                if value
                    scope.styles =
                        height: accordionController.panelHeight + 'px'
    }

cyclotronDirectives.directive 'accordionHeading', ->
    {
        restrict: 'EA'
        transclude: true   
        template: ''       
        replace: true
        require: '^accordionGroup'
        link: (scope, element, attr, accordionGroupController, transclude) ->
            accordionGroupController.setHeading(transclude(scope, -> ))
    }

cyclotronDirectives.directive 'accordionTransclude', ->
    {
        require: '^accordionGroup'
        link: (scope, element, attr, controller) ->
            scope.$watch (-> controller[attr.accordionTransclude]), (heading) ->
                if heading
                    element.html ''
                    element.append heading
    }
