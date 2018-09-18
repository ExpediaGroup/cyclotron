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

cyclotronDirectives.directive 'tableFixedHeader', ($window, configService) ->
    {
        restrict: 'EAC'

        link: (scope, element, attrs) ->

            return unless attrs.tableFixedHeader? && scope.$eval(attrs.tableFixedHeader) == true

            #
            # Initialize
            #
            $table = $(element)
            $tableHeaders = null

            $widgetBody = $table.parents '.widget-body'
            $container = $('<div id="container"></div>').appendTo $widgetBody

            pos =
                originalTop: 0
                originalLeft: $table.position().left

            $container.css({
                'overflow': 'hidden'
                'position': 'absolute'
                'top': 0
                'left': $table.position().left
            }).hide()

            # Clone table for fixed header
            $clonedTable = $table.clone().empty()

            $clonedTable.css({
                'position': 'relative'
                
            }).appendTo($container)

            # Add fixed layout if there are no column groups
            if scope.columnGroups.length == 0
                $clonedTable.css 'table-layout', 'fixed'

            #
            # Handle resize events
            #
            resize = ->
                $tableHeaders = $table.children 'thead'
                $headerRows = $tableHeaders.children 'tr'
                pos.originalTop = $widgetBody.position().top
                pos.originalLeft = $table.offset().left

                $container.css {
                    width: $widgetBody[0].clientWidth
                    height: $tableHeaders.height()
                    top: pos.originalTop
                }

                $clonedTable
                    .empty()
                    .width($table.outerWidth())
                    .append($tableHeaders.clone())
                    .find('tr').each (index) ->
                        height = $headerRows.eq(index).height()
                        $(this).css('height', height)
                        $(this).find('th').each (thIndex) ->
                            originalHeader = $headerRows.eq(index).find('th').eq(thIndex)
                            $(this).css {
                                width: originalHeader.width()
                            }

            $widgetBody.on 'resize', _.throttle(resize, 250, { leading: false, maxWait: 500 })

            scope.$watchGroup ['sortBy', 'sortedRows'], _.throttle(resize, 200, { leading: false, trailing: true })

            #
            # Handle scroll events
            #
            $widgetBody.on 'scroll', _.debounce(->
                scrollTop = $widgetBody.scrollTop()
                elementTop = $tableHeaders.offset().top
                diff = pos.originalTop - elementTop

                $container.css 'top', pos.originalTop

                if scrollTop > 0
                    $clonedTable.css({
                        'left': -$widgetBody.scrollLeft()
                    })

                    if not scope.visible
                        resize()
                        $container.show()
                        scope.visible = true
                else
                    $container.hide()
                    scope.visible = false
            , 120, { leading: false, maxWait: 200 })

            #
            # Cleanup
            #
            scope.$on '$destroy', ->
                if $container?
                    $container.remove()
                    $container = null

                $widgetBody.off 'resize'
                $widgetBody.off 'scroll'
                return

            return
    }
