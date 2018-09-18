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

#
# Top-level Page directive
# 
# Renders a series of Widgets and manages page-level interactivity.  Expects the following
# scope variables:
#     page: Page to render
#     pageOverrides: Overrides for the current page
#     pageNumber: Index of the Page in the Dashboard (zero-indexed)
#     dashboard: Entire Dashboard object
#
cyclotronDirectives.directive 'dashboardPage', ($compile, $window, $timeout, configService, layoutService, logService) ->
    {
        replace: true
        restrict: 'E'

        scope:
            page: '='
            pageOverrides: '='
            pageNumber: '@'
            dashboard: '='

        template: '<div class="dashboard-page dashboard-{{page.theme}} {{page.style}}">' +
            '<div class="dashboard-page-inner">' +
                '<div class="dashboard-widgetwrapper dashboard-{{widget.theme}} theme-variant-{{widget.themeVariant}}" ng-repeat="widget in sortedWidgets track by widget.uid"' +
                ' widget="widget" page="page" page-overrides="pageOverrides" widget-index="$index" layout="layout" dashboard="dashboard" post-layout="postLayout()"></div>' + 
            '</div></div>'

        link: (scope, element, attrs) ->
            $element = $(element)
            $dashboard = $element.parents('.dashboard')
            $dashboardPageInner = $element.children('.dashboard-page-inner')
            $dashboardControls = $dashboard.find '.dashboard-controls'
            $dashboardSidebar = $dashboard.find '.dashboard-sidebar'

            masonry = ->
                return unless scope.layout?
                $dashboardPageInner.masonry({
                    itemSelector: '.dashboard-widgetwrapper'
                    columnWidth: scope.layout.gridSquareWidth
                    gutter: scope.layout.gutter
                    resize: false
                    transitionDuration: '0.1s'
                    stagger: 5
                })

            # Determine sort order of Widgets
            # Normally, Widgets appear in sequential order that they are listed in the Dashboard
            # However, Users can override the Widget index, so this must be taken into account
            resortWidgets = ->
                # Apply User overrides to Widget sort order
                if scope.pageOverrides?.widgets?
                    widgetOverrides = scope.pageOverrides.widgets
                    sortedWidgets = _.map scope.page.widgets, (widget, index) ->
                        widget = _.cloneDeep widget
                        widget._originalIndex = index
                        if widgetOverrides[index].indexOverride?
                            widget._index = widgetOverrides[index].indexOverride
                        else 
                            # No override, so use the default index of the Widget
                            widget._index = index
                        return widget

                    scope.sortedWidgets = _.sortBy sortedWidgets, '_index'
                else
                    # No overrides, so take the Widgets as-is
                    scope.sortedWidgets = scope.page.widgets


            updatePage = ->
                scope.page.widgets = scope.page?.widgets || []

                # Assign uids to Widgets -- use for tracking if widgets are rearranged
                _.each scope.page.widgets, (widget) ->
                    widget.uid ?= uuid.v4()
                    return

                # Merge Linked Widgets
                scope.page.widgets = _.map scope.page.widgets, (widget) ->
                    if widget.widget == 'linkedWidget'
                        indices = widget.linkedWidget.split ','
                        pageIndex = parseInt indices[0]
                        widgetIndex = parseInt indices[1]

                        linkedWidget = scope.dashboard.pages[pageIndex]?.widgets[widgetIndex]
                        
                        widget = _.defaults widget, linkedWidget
                        widget.widget = linkedWidget.widget
                        widget
                    else 
                        widget

                # Sort Widgets per overrides
                resortWidgets()
            
                # Update the layout -- this triggers all widgets to update
                # Masonry will be called after all widgets have redrawn
                updateLayout = ->

                    # Create a run-once function that triggers Masonry after all the Widgets have drawn themselves
                    scope.postLayout = _.after scope.page.widgets.length, ->
                        if (scope.page.enableMasonry != false)
                            masonry()
                        return

                    containerWidth = $dashboard.innerWidth()
                    containerHeight = $($window).height()

                    # Recalculate layout
                    scope.layout = layoutService.getLayout scope.page, containerWidth, containerHeight

                    # Set page margin if defined
                    if !_.isNullOrUndefined(scope.layout.margin)
                        $element.css 'padding', scope.layout.margin + 'px'

                    $dashboardPageInner.css { 
                        marginRight: '-' + scope.layout.gutter + 'px'
                        marginBottom: '-' + scope.layout.gutter + 'px'
                    }

                    # Enable/disable scrolling of the dashboard page
                    if !scope.layout.scrolling
                        $element.parents().addClass 'fullscreen'
                    else 
                        $element.parents().removeClass 'fullscreen'

                # Update everything
                updateLayout()

                resizeFunction = _.throttle(->
                    scope.$apply updateLayout
                , 65)

                # Update on element resizing
                $element.on 'resize', resizeFunction

                scope.$on '$destroy', ->
                    $element.off 'resize', resizeFunction

                # Apply page theme class to dashboard-controls
                $dashboard.addClass('dashboard-' + scope.page.theme)
                $dashboardControls.addClass('dashboard-' + scope.page.theme)

                # Set dashboard background color from theme
                themeSettings = configService.dashboard.properties.theme.options[scope.page.theme]
                if scope.page.theme? and themeSettings?
                    color = themeSettings.dashboardBackgroundColor
                    $('html').css('background-color', color)

                return

            #
            # Watch the dashboard page and update the layout
            #
            scope.$watch 'page', (page, oldValue) ->
                return if _.isUndefined(page)                
                updatePage()

            scope.$watch 'pageOverrides', (pageOverrides, previous) ->
                return if _.isEqual pageOverrides, previous
                resortWidgets()

                $timeout ->
                    $dashboardPageInner.masonry('reloadItems')
                    $dashboardPageInner.masonry()
                , 30
                return
            , true

            #
            # Cleanup
            #
            scope.$on '$destroy', ->
                # Uninitialize Masonry if still present
                if $dashboardPageInner.data('masonry')
                    $dashboardPageInner.masonry('destroy')

            return

    }
