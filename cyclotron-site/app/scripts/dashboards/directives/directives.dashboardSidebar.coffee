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

cyclotronDirectives.directive 'dashboardSidebar', ($timeout, layoutService) ->
    {
        restrict: 'EAC'
        link: (scope, element, attrs) ->
            # Initial position 
            isSidebarExpanded = false

            scope.sidebarContent = _.cloneDeep scope.dashboard.sidebar.sidebarContent
            if scope.sidebarContent?.length > 0
                scope.sidebarContent[0].isOpen = true
            else 
                scope.isShowHideWidgetsOpen = true
            
            $element = $(element)
            $parent = $element.parent()
            $header = $element.find '.sidebar-header'
            $accordion = $element.find '.sidebar-accordion'
            $footer = $element.find '.sidebar-footer'
            $hitbox = $element.find '.sidebar-expander-hitbox'
            $expander = $element.find '.sidebar-expander'
            $expanderIcon = $expander.children 'i'
            $clickCover = $parent.find '.click-cover'

            updateExpandedState = ->
                if isSidebarExpanded
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
                isSidebarExpanded = !isSidebarExpanded
                updateExpandedState()

            $clickCover.on 'click', (event) ->
                event.preventDefault()
                isSidebarExpanded = false
                updateExpandedState()

            # Resize accordion around header/footer
            sizer = ->
                $accordion.height($element.outerHeight() - $header.outerHeight() - $footer.outerHeight())
                
            $element.on 'resize', _.debounce sizer, 300, { leading: false, maxWait: 600 }

            # Run in 100ms
            timer = $timeout sizer, 100

            scope.$on '$destroy', ->
                $timeout.cancel timer
                $element.off 'resize'
           
            return

        controller: ($scope, $window, configService, dashboardOverridesService, dashboardService) ->
            $scope.footerLogos = configService.dashboardSidebar?.footer?.logos || []
            $scope.calculatedWidgets = []
            $scope.widgetOverrides = []
            $scope.allWidgetsVisible = false

            calculateOverrides = ->
                actualWidgets = $scope.currentPage[0]?.widgets
                $scope.widgetOverrides = $scope.dashboardOverrides?.pages[$scope.currentPageIndex]?.widgets

                $scope.calculatedWidgets = _.map actualWidgets, (widget, index) ->
                    # Visible by default
                    visible = true

                    if $scope.widgetOverrides?[index].hidden?
                        visible = !$scope.widgetOverrides?[index].hidden
                    else if widget.hidden
                        visible = false

                    if $scope.widgetOverrides?[index].indexOverride?
                        indexOverride = $scope.widgetOverrides?[index].indexOverride
                    else 
                        indexOverride = index
                    
                    return {
                        label: dashboardService.getWidgetName(widget, index)
                        visible: visible
                        index: index                    # Actual Widget index
                        indexOverride: indexOverride    # Override to index
                    }

                visibleWidgets = _.filter($scope.calculatedWidgets, { visible: true }).length
                $scope.allWidgetsVisible = (visibleWidgets / $scope.calculatedWidgets.length) > 0.5

                # Resort the widgets using the index override
                $scope.calculatedWidgets = _.sortBy $scope.calculatedWidgets, 'indexOverride'

            $scope.moveWidget = (index) ->
                # Remove widget from old posision
                $scope.calculatedWidgets.splice(index, 1)

                # Save all widget positions
                _.each $scope.calculatedWidgets, (widgetOverride, index) ->
                    widgetOverride.indexOverride = index
                    $scope.widgetOverrides[widgetOverride.index].indexOverride = index
                    return

            $scope.changeVisibility = (widgetOverride) ->
                if widgetOverride.visible == true
                    $scope.widgetOverrides[widgetOverride.index].hidden = false
                else
                    $scope.widgetOverrides[widgetOverride.index].hidden = true
                return

            $scope.toggleAllWidgets = ->
                _.each $scope.widgetOverrides, (widgetOverride) ->
                    widgetOverride.hidden = $scope.allWidgetsVisible
                    return
                return

            $scope.$watchCollection 'currentPage', (currentPage) ->
                return unless currentPage?.length > 0
                calculateOverrides()

            $scope.$watch 'dashboardOverrides', (dashboardOverrides) ->
                return unless dashboardOverrides?
                calculateOverrides()
            , true

    }
