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

cyclotronDirectives.directive 'theNumber', ($timeout) ->
    {
        restrict: 'C'
        scope:
            singleNumber: '='
            orientation: '='

        link: (scope, element, attrs) ->
            $element = $(element)
            $widgetBody = $element.parent()

            scope.isHorizontal = (scope.orientation == 'horizontal')
            if scope.singleNumber == true then scope.isHorizontal = !scope.isHorizontal
            
            sizer = ->
                numbers = $widgetBody.find('.the-number')
                widgetBodyHeight = $widgetBody.height()
                widgetBodyWidth = $widgetBody.width()

                return if widgetBodyHeight == 0
                
                if scope.singleNumber == true

                    numbers.addClass('singleNumber')
                    $widgetBody.css('overflow-y', 'hidden')
                    h1 = numbers.find('h1')
                    spans = numbers.find('span')

                    if scope.isHorizontal
                        h1.css('display', 'inline-block')
                        spans.css('display', 'inline-block')

                    fontSize = Math.min(102, widgetBodyHeight / 2)
                    iterations = 0
                    currentWidth = 0

                    sizeMe = ->
                        h1.css('font-size', fontSize + 'px')
                        h1.css('line-height', fontSize + 'px')
                        spans.css('font-size', fontSize*.75 + 'px')
                        iterations++

                        currentWidth = 0
                        if scope.isHorizontal
                            currentWidth = h1.width()
                        else
                            numbers.children().each -> currentWidth += $(this).width()
                    sizeMe()
                    while (currentWidth + 25 >= widgetBodyWidth || h1.height() > fontSize * 2) && iterations < 15
                        fontSize -= 4
                        sizeMe()

                    if scope.isHorizontal
                        iterations = 0
                        spanFontSize = Math.min(fontSize*.70, 40)
                        sizePrefixSuffix = ->
                            spans.css('font-size', spanFontSize + 'px')
                            iterations++
                            spanFontSize -= 4

                            # find max span width (prefix or suffix)
                            currentWidth = 0
                            spans.each -> currentWidth = Math.max(currentWidth, $(this).width())

                        sizePrefixSuffix()
                        sizePrefixSuffix() while currentWidth + 15 >= widgetBodyWidth && iterations < 10

                        # Set everything to block display now
                        h1.css('display', 'block')

                        # Vertical align
                        totalHeight = 0
                        numbers.children().each -> totalHeight += $(this).height()
                        $element.css('padding-top', (widgetBodyHeight - totalHeight) / 2.0 + 'px')

                    else 
                        h1.css('line-height', widgetBodyHeight - fontSize/2.0 + 'px')

                else
                    return
                    #numberHeight = widgetBodyHeight / numbers.length
                    #numberHeight = Math.max(numberHeight, 32)
                    #numbers.height(numberHeight)
                    #numbers.css('line-height', Math.floor(numberHeight*.8) + 'px')
                    #numbers.css('font-size', Math.floor(numberHeight*.8) + 'px')

            # Update on window resizing
            $widgetBody.on 'resize', _.throttle(->
                scope.$apply ->
                    sizer()
            , 80)

            $timeout(sizer, 10)

            #
            # Cleanup
            #
            scope.$on '$destroy', ->
                $widgetBody.off 'resize'
                return
    }
