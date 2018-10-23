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
# Top-level Dashboard directive
# 
# Renders a series of Widgets and manages page-level interactivity.  Expects the following
# scope variables:
#     page: Page to render
#     pageOverrides: Overrides for the current page
#     pageNumber: Index of the Page in the Dashboard (zero-indexed)
#     dashboard: Entire Dashboard object
#
cyclotronDirectives.directive 'dashboard', ($compile, $window, $timeout, configService, layoutService, logService) ->
    {
        restrict: 'C'

        link: (scope, element, attrs) ->
            $element = $(element)
            $dashboardSidebar = $element.children '.dashboard-sidebar'
            $dashboardControls = $element.children '.dashboard-controls'

            controlTimer = null
            controlTarget = null

            calculateMouseTarget = ->
                # Get all dimensions and the padding options
                
                controlOffset = $dashboardControls.offset()
                controlWidth = $dashboardControls.width()
                controlHeight = $dashboardControls.height()
                padX = configService.dashboard.controls.hitPaddingX
                padY = configService.dashboard.controls.hitPaddingY

                return unless $dashboardControls? and controlOffset?

                controlTarget = {
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
                $timeout.cancel(controlTimer) if controlTimer?

                controlTimer = $timeout(makeControlsDisappear, configService.dashboard.controls.duration)
            , 500, { leading: true })

            controlHitTest = (event) ->
                return unless controlTarget?
                # Abort if outside the target
                if event.pageX < controlTarget.left ||
                   event.pageX > controlTarget.right ||
                   event.pageY < controlTarget.top ||
                   event.pageY > controlTarget.bottom
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

            $(window).on 'resize', _.debounce(calculateMouseTarget, 500, { leading: false })

            #
            # Cleanup
            #
            scope.$on '$destroy', ->
                $(document).off 'mousemove', controlHitTest
                $(document).off 'scroll', calculateMouseTarget
                $(window).off 'resize', calculateMouseTarget

                # Cancel timer
                $timeout.cancel(controlTimer) if controlTimer?

            return
    }
