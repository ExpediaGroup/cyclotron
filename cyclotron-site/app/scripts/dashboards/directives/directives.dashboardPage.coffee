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

cyclotronDirectives.directive 'dashboardPage', ($compile, $window, $timeout, configService, layoutService, logService) ->
    {
        replace: true
        restrict: 'A'

        scope:
            page: '='
            dashboard: '='

        template: '<div class="dashboard-page dashboard-{{page.theme}} {{page.style}}">' +
            '<div class="dashboard-page-inner">' +
                '<div widget="widget" class="dashboard-widgetwrapper dashboard-{{widget.theme}}" ng-repeat="widget in page.widgets"></div>' + 
            '</div></div>'

        link: (scope, element, attrs) ->
            $element = $(element)
            $dashboardPageInner = $element.children('.dashboard-page-inner')
            $dashboardControls = $('.dashboard-controls')
            
            scope.controlTimer = null

            masonry = (element, layout) ->
                $dashboardPageInner.masonry({
                    itemSelector: '.dashboard-widgetwrapper'
                    columnWidth: layout.gridSquareWidth
                    gutter: layout.gutter
                })

            calculateMouseTarget = ->
                # Get all dimensions and the padding options
                
                controlOffset = $dashboardControls.offset()
                controlWidth = $dashboardControls.width()
                controlHeight = $dashboardControls.height()
                padX = configService.dashboard.controls.hitPaddingX
                padY = configService.dashboard.controls.hitPaddingY

                return unless $dashboardControls? and controlOffset?

                scope.controlTarget = {
                    top: controlOffset.top - padY
                    bottom: controlOffset.top + controlHeight + padY
                    left: controlOffset.left - padX
                    right: controlOffset.left + controlWidth + padX
                }

            makeControlsDisappear = ->
                $dashboardControls.removeClass 'active'

            makeControlsAppear = _.throttle(->
                # Make visible
                $dashboardControls.addClass 'active'

                # Set timer to remove the controls after some delay
                $timeout.cancel(scope.controlTimer) if scope.controlTimer?

                scope.controlTimer = $timeout(makeControlsDisappear, configService.dashboard.controls.duration)
            , 500, { leading: true })

            controlHitTest = (event) ->
                # Abort if outside the target
                if event.pageX < scope.controlTarget.left ||
                   event.pageX > scope.controlTarget.right ||
                   event.pageY < scope.controlTarget.top ||
                   event.pageY > scope.controlTarget.bottom
                    return

                makeControlsAppear()

            #
            # Configure Dashboard Controls
            #
            calculateMouseTarget()

            #
            # Bind mousemove event for entire document (remove during $destroy)
            #
            $(document).on 'mousemove', controlHitTest

            $(document).on 'scroll', calculateMouseTarget

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
                            
                    newLayout = layoutService.getLayout(newValue, $($window).width(), $($window).height())

                    # Optional persistent widget area of layout
                    newLayout.widget = scope.layout?.widget || {}
                    scope.layout = newLayout

                    # Set page margin if defined
                    if !_.isNullOrUndefined(scope.layout.margin)
                        $element.css('padding', scope.layout.margin + 'px')

                    $dashboardPageInner.css({ 
                        marginRight: '-' + scope.layout.gutter + 'px'
                        marginBottom: '-' + scope.layout.gutter + 'px'
                    })

                    # Enable/disable scrolling of the dashboard page
                    if !scope.layout.scrolling
                        $element.parents().addClass 'fullscreen'
                    else 
                        $element.parents().removeClass 'fullscreen'

                    # Store updated hit target for the dashboard controls
                    calculateMouseTarget()


                # Update everything
                updateLayout()

                resizeFunction = _.throttle(-> 
                    scope.$apply(updateLayout)
                , 65)

                # Update on window resizing
                $(window).on 'resize', resizeFunction

                scope.$on '$destroy', ->
                    $(window).off 'resize', resizeFunction

                # Apply page theme class to dashboard-controls
                $dashboardControls.addClass('dashboard-' + newValue.theme)

                # Set dashboard background color from theme
                themeSettings = configService.dashboard.properties.theme.options[newValue.theme]
                if newValue.theme? and themeSettings?
                    color = themeSettings.dashboardBackgroundColor
                    $('.dashboard, html').css('background-color', color)

                return

            #
            # Cleanup
            #
            scope.$on '$destroy', ->
                $(document).off 'mousemove', controlHitTest
                $(document).off 'scroll', calculateMouseTarget

                # Cancel timer
                $timeout.cancel(scope.controlTimer) if scope.controlTimer?

                # Uninitialize Masonry if still present
                if $dashboardPageInner.data('masonry')
                    $dashboardPageInner.masonry('destroy')

            return
    }
