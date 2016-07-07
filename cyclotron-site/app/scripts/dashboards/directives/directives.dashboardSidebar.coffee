###
# Copyright (c) 2013-2016 the original author or authors.
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

cyclotronDirectives.directive 'dashboardSidebar', ($timeout, layoutService) ->
    {
        restrict: 'EAC'
        link: (scope, element, attrs) ->
            # Initial position 
            scope.sidebarExpanded = false
            
            $element = $(element)
            $parent = $element.parent()
            $header = $element.find '.sidebar-header'
            $accordion = $element.find '.sidebar-accordion'
            $footer = $element.find '.sidebar-footer'
            $hitbox = $element.find '.sidebar-expander-hitbox'
            $expander = $element.find '.sidebar-expander'
            $expanderIcon = $expander.children 'i'
            $clickCover = $parent.find '.click-cover'

            scope.$watch 'sidebarExpanded', (expanded) ->
                if expanded
                    $element.removeClass 'collapsed'
                    $clickCover.css 'display', 'block'
                    $expanderIcon.removeClass 'fa-caret-right'
                    $expanderIcon.addClass 'fa-caret-left'
                    $hitbox.attr 'title', 'Click to collapse the sidebar'
                else
                    $element.addClass 'collapsed'
                    $clickCover.css 'display', 'none'
                    $expanderIcon.removeClass 'fa-caret-left'
                    $expanderIcon.addClass 'fa-caret-right'
                    $hitbox.attr 'title', 'Click to expand the sidebar'

            $hitbox.on 'click', (event) ->
                event.preventDefault()
                scope.$apply ->
                    scope.sidebarExpanded = !scope.sidebarExpanded

            $clickCover.on 'click', (event) ->
                event.preventDefault()
                scope.$apply ->
                    scope.sidebarExpanded = false

            # Resize accordion around header/footer
            sizer = ->
                $accordion.height($element.outerHeight() - $header.outerHeight() - $footer.outerHeight())
                
            $element.on 'resize', _.debounce(-> 
                scope.$apply sizer
            , 300, { leading: false, maxWait: 600 })

            # Run in 100ms
            timer = $timeout sizer, 100

            scope.$on '$destroy', ->
                $timeout.cancel timer
                $element.off 'resize'
           
            return

        controller: ($scope, configService, dashboardService) ->
            $scope.footerLogos = configService.dashboardSidebar?.footer?.logos || []
            $scope.widgetVisibilities = []
            $scope.widgetOverrides = []

            $scope.updateVisibility = ->
                actualWidgets = $scope.currentPage[0]?.widgets
                $scope.widgetOverrides = $scope.dashboardOverrides?.pages[$scope.currentPageIndex]?.widgets

                $scope.widgetVisibilities = _.map actualWidgets, (widget, index) ->
                    # Visible by default
                    visible = true

                    if $scope.widgetOverrides?[index].hidden?
                        visible = !$scope.widgetOverrides?[index].hidden
                    else if widget.hidden
                        visible = false

                    return {
                        label: dashboardService.getWidgetName(widget, index)
                        visible: visible
                    }
            
            $scope.changeVisibility = (widget, index) ->

                if widget.visible == true
                    $scope.widgetOverrides[index].hidden = false
                else
                    $scope.widgetOverrides[index].hidden = true
                return

            $scope.$watch 'currentPage', (currentPage) ->
                return unless currentPage?.length > 0
                $scope.updateVisibility()
            , true

            $scope.$watch 'dashboardOverrides', (dashboardOverrides) ->
                return unless dashboardOverrides?
                $scope.updateVisibility()
            , true

    }
