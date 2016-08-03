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
                '<div class="dashboard-widgetwrapper dashboard-{{widget.theme}}" ng-repeat="widget in page.widgets"' +
                ' widget="widget" page="page" page-overrides="pageOverrides" widget-index="$index" layout="layout" dashboard="dashboard" post-layout="postLayout()"></div>' + 
            '</div></div>'

        link: (scope, element, attrs) ->
            $element = $(element)
            $dashboard = $element.parents('.dashboard')
            $dashboardPageInner = $element.children('.dashboard-page-inner')
            $dashboardControls = $dashboard.find '.dashboard-controls'
            $dashboardSidebar = $dashboard.find '.dashboard-sidebar'
            
            masonry = (element, layout) ->
                $dashboardPageInner.masonry({
                    itemSelector: '.dashboard-widgetwrapper'
                    columnWidth: layout.gridSquareWidth
                    gutter: layout.gutter
                })

            #
            # Watch the dashboard page and update the layout
            #
            scope.$watch 'page', (newValue, oldValue) ->
                if _.isUndefined(newValue) then return

                # Update the layout -- this triggers all widgets to update
                # Masonry will be called after all widgets have redrawn
                updateLayout = ->
                    scope.postLayout = _.after newValue.widgets.length, ->
                        if (newValue.enableMasonry != false)
                            masonry(element, scope.layout)
                        return

                    containerWidth = $dashboard.innerWidth()
                    containerHeight = $($window).height()
                    scope.layout = layoutService.getLayout(newValue, containerWidth, containerHeight)

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
                $dashboard.addClass('dashboard-' + newValue.theme)
                $dashboardControls.addClass('dashboard-' + newValue.theme)

                # Set dashboard background color from theme
                themeSettings = configService.dashboard.properties.theme.options[newValue.theme]
                if newValue.theme? and themeSettings?
                    color = themeSettings.dashboardBackgroundColor
                    $('html').css('background-color', color)

                return

            #
            # Cleanup
            #
            scope.$on '$destroy', ->
                # Uninitialize Masonry if still present
                if $dashboardPageInner.data('masonry')
                    $dashboardPageInner.masonry('destroy')

            return

    }
