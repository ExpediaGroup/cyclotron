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

cyclotronDirectives.directive 'widgetBody', ($timeout) -> 
    {
        restrict: 'C'

        link: (scope, element, attrs) ->
            $widgetBody = $(element)
            $widget = $widgetBody.parent()

            sizer = ->
                $title = $widget.find '.title'
                $footer = $widget.find '.widget-footer'
                widgetBodyHeight = $widget.outerHeight() - $title.outerHeight() - $footer.outerHeight()
                widgetBodyHeight -= parseInt($widgetBody.css('marginTop')) + parseInt($widgetBody.css('marginBottom'))
                $widgetBody.height Math.floor(widgetBodyHeight)

                if scope.widgetLayout?
                    scope.widgetLayout.widgetBodyHeight = widgetBodyHeight

            # Update on window resizing
            $widget.add('.title, .widget-footer').on 'resize', _.debounce(->
                scope.$apply ->
                    sizer()
            , 120, { leading: false, maxWait: 500 })

            # Run now & again in 100ms
            sizer()
            timer = $timeout sizer, 100

            scope.$on '$destroy', ->
                $timeout.cancel timer
                $widget.off 'resize'

            return
    }
