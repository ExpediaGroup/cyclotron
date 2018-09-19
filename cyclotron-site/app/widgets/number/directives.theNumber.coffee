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

cyclotronDirectives.directive 'theNumber', ($timeout) ->
    {
        restrict: 'C'
        scope:
            numberCount: '='
            isHorizontal: '='
            index: '='
            autoSize: '='

        link: (scope, element, attrs) ->
            $element = $(element)
            $widgetBody = $element.parent()

            sizer = ->
                widgetBodyHeight = $widgetBody.height()
                widgetBodyWidth = $widgetBody.width()

                return if widgetBodyHeight == 0

                numberWidth = widgetBodyWidth
                numberHeight = widgetBodyHeight

                if scope.numberCount == 2
                    if scope.isHorizontal
                        numberWidth = widgetBodyWidth / 2
                        numberHeight = widgetBodyHeight
                    else 
                        numberWidth = widgetBodyWidth
                        numberHeight = widgetBodyHeight / 2
                else if scope.numberCount == 3
                    if scope.index < 2
                        numberWidth = widgetBodyWidth / 2
                        numberHeight = widgetBodyHeight / 2
                    else
                        numberWidth = widgetBodyWidth
                        numberHeight = widgetBodyHeight / 2
                else if scope.numberCount == 4
                    numberWidth = widgetBodyWidth / 2
                    numberHeight = widgetBodyHeight / 2

                if scope.numberCount <= 4 && scope.autoSize != false

                    $element.addClass 'auto-sized'
                    $element.css 'width', Math.floor(numberWidth) + 'px'
                    $element.css 'height', Math.floor(numberHeight) + 'px'

                    $widgetBody.css('overflow-y', 'hidden')
                    h1 = $element.find('h1')
                    spans = $element.find('span')

                    if scope.isHorizontal
                        h1.css('display', 'inline-block')
                        spans.css('display', 'inline-block')

                    fontSize = Math.min(102, numberHeight / 2)
                    iterations = 0
                    currentWidth = 0
                    currentHeight = 0

                    sizeMe = ->
                        h1.css('font-size', fontSize + 'px')
                        h1.css('line-height', fontSize + 'px')
                        spans.css('font-size', fontSize * 0.75 + 'px')
                        iterations++

                        currentWidth = 0
                        if scope.isHorizontal
                            currentWidth = h1.width()
                        else
                            $element.children().each -> currentWidth += $(this).width()

                        currentHeight = 0
                        if scope.isHorizontal
                            $element.children().each -> currentHeight += $(this).height()
                        else
                            currentHeight = h1.height()

                    sizeMe()
                    while ((currentWidth + 25 >= numberWidth || h1.height() > fontSize * 2) or currentHeight > numberHeight) && iterations < 25
                        fontSize -= 4
                        sizeMe()

                    if scope.isHorizontal
                        iterations = 0
                        spanFontSize = Math.min(fontSize * 0.70, 40)
                        sizePrefixSuffix = ->
                            spans.css('font-size', spanFontSize + 'px')
                            iterations++
                            spanFontSize -= 4

                            # find max span width (prefix or suffix)
                            currentWidth = 0
                            spans.each -> currentWidth = Math.max(currentWidth, $(this).width())

                        sizePrefixSuffix()
                        sizePrefixSuffix() while currentWidth + 15 >= numberWidth && iterations < 15

                        # Set everything to block display now
                        h1.css('display', 'block')

                        # Vertical align
                        totalHeight = 0
                        $element.children().each -> totalHeight += $(this).height()
                        $element.css('padding-top', (numberHeight - totalHeight) / 2.0 + 'px')
                    else 
                        h1.css('line-height', numberHeight - fontSize / 2.0 + 'px')

                else
                    return

            # Update on window resizing
            resizeFunction = _.debounce sizer, 100, { leading: false, maxWait: 300 }
            $widgetBody.on 'resize', resizeFunction

            # Resize now
            $timeout(sizer, 10)

            #
            # Cleanup
            #
            scope.$on '$destroy', ->
                $widgetBody.off 'resize', resizeFunction
                return
    }
