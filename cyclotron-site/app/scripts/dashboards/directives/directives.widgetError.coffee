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

cyclotronDirectives.directive 'widgetError', ($timeout) -> 
    {
        restrict: 'C'
        replace: false
        templateUrl: '/partials/widgetError.html'

        link: (scope, element, attrs) ->
            $widgetError = $(element)
            $errorContainer = $widgetError.find('.widget-error-container')
            $widget = $widgetError.parent()
            $bang = $widgetError.find('.fa-exclamation')
            $reload = $widgetError.find('.widget-reload')
            $message = $widgetError.find('.widget-error-message')

            sizer = ->
                $title = $widget.find('.title')
                $footer = $widget.find('.widget-footer')
                widgetBodyHeight = $widget.height() - $title.height() - $footer.height()
                $widgetError.height(Math.floor(widgetBodyHeight))

                # Resize Exclamation mark
                bangSize = Math.floor(widgetBodyHeight / 2)
                $bang.css('font-size', Math.min(90, bangSize) + 'px')

                # Resize Reload
                reloadSize = Math.min(13, Math.floor(widgetBodyHeight / 4))
                $reload.css('font-size', reloadSize)

                # Show/Hide message
                if scope.widget.showWidgetErrors
                    errorMessageLength = $widgetError.width() * widgetBodyHeight / 512

                    if _.isObject(scope.widgetContext.dataSourceErrorMessage)
                        if scope.widgetContext.dataSourceErrorMessage.message?
                            scope.errorMessage = scope.widgetContext.dataSourceErrorMessage.message
                    else 
                        scope.errorMessage = scope.widgetContext.dataSourceErrorMessage
                        
                    if not _.isString(scope.errorMessage)
                        scope.errorMessage = JSON.stringify scope.errorMessage

                    if errorMessageLength < 30
                        scope.shortErrorMessage = null
                    else if scope.errorMessage.length < errorMessageLength
                        scope.shortErrorMessage = scope.errorMessage
                    else 
                        scope.shortErrorMessage = scope.errorMessage.substring(0, errorMessageLength - 3) + '...'

                # Vertical align
                topPadding = (widgetBodyHeight - $errorContainer.height()) / 3
                $errorContainer.css('margin-top', topPadding + 'px')

            # Update on window resizing
            $widget.add('.title, .widget-footer').on 'resize', _.throttle(->
                scope.$apply ->
                    sizer()
            , 120, { leading: false, maxWait: 500 })

            # Run now & again in 100ms
            sizer()
            timer = $timeout(sizer, 100)

            scope.$on '$destroy', ->
                $timeout.cancel timer

            return
    }
