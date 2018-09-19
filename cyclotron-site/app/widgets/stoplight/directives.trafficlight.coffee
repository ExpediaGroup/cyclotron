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

cyclotronDirectives.directive 'trafficlight', ($timeout) ->
    {
        restrict: 'C'
        scope:
            activeColor: '='

        link: (scope, element, attrs) ->
            $element = $(element)
            $widgetBody = $element.parent()
            $inner = $element.children('.trafficlight-inner')
            $protectors = $element.children('.protector')
            $lights = $inner.children('.light')

            sizer = ->
                height = $element.height()
                width = height / 3
                $element.width(width)
                $inner.css({
                    'border-radius': width/4 + 'px'
                    'border-width': width / 19
                })

                protectorWidth = width / 5
                protectorPadding = Math.floor(height / 12.0)
                protectorHeight = Math.floor(height - (protectorPadding * 4)) / 3.0
                if height < 150
                    protectorHeight *= 0.9

                if $widgetBody.width() < width + protectorWidth * 2
                    $protectors.hide()
                else 
                    $protectors.show()
                    $protectors.css({ 
                        'width': width + (protectorWidth * 2) + 'px'
                        'left': -protectorWidth + 'px'
                        'border-left': 'solid ' + protectorWidth + 'px transparent'
                        'border-right': 'solid ' + protectorWidth + 'px transparent'
                        'border-top': 'solid ' + protectorHeight + 'px #111'
                    })

                    $protectors.first().css('top', protectorPadding + 'px')
                        .next().css('top', (protectorHeight + 2 * protectorPadding) + 'px')
                        .next().css('top', (2 * protectorHeight + 3 * protectorPadding) + 'px')

                $lights.width(protectorHeight)
                $lights.height(protectorHeight)

                $lights.css('margin-bottom', (protectorPadding * .9) + 'px')
                $lights.first().css('margin-top', (protectorPadding - width / 15) + 'px')

                # Tweaks for very small stoplights
                if protectorPadding < 12
                    $lights.css({
                        'background-image': 'none'
                        'box-shadow': 'none'
                    })

                    $inner.find('.red').css('border-color', '#A52A2A')
                    $inner.find('.yellow').css('border-color', '#FFFF00')
                else
                    $inner.find('.red').css({
                        'background-image': 'radial-gradient(brown, transparent)',
                        'box-shadow': '0 0 ' + protectorPadding / 1.3 + 'px #111 inset, 0 0 10px red'
                        'border-color': 'red'
                    })
                    $inner.find('.yellow').css({
                        'background-image': 'radial-gradient(gold, transparent)'
                        'box-shadow': '0 0 ' + protectorPadding / 1.3 + 'px #111 inset, 0 0 10px yellow'
                        'border-color': 'yellow'
                    })
                    $inner.find('.green').css({
                        'background-image': 'radial-gradient(lime, transparent)'
                        'box-shadow': '0 0 ' + protectorPadding / 1.3 + 'px #111 inset, 0 0 10px green'
                    })

            # Update on parent resizing
            $widgetBody.on 'resize', _.debounce sizer, 100, { leading: false, maxWait: 300 }
            $timeout(sizer, 10)

            scope.$watch 'activeColor', (color) ->
                $lights.removeClass('active')
                $inner.find('.' + color).addClass('active')

            #
            # Cleanup
            #
            scope.$on '$destroy', ->
                $widgetBody.off 'resize'

    }
