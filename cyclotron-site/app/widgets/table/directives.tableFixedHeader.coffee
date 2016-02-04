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

            $parent = $table.parent()
            $container = $('<div id="container"></div>').appendTo($parent)

            $container.css({
                'overflow': 'hidden'
                'position': 'absolute'
                'top': 0
                'left': $table.position().left
            }).hide()

            pos =
                originalTop: 0
                originalLeft: $table.position().left

            $clonedTable = $table.clone().empty()

            $clonedTable.css({
                'position': 'relative'
                'top': '0'
            }).appendTo($container)

            #
            # Handle resize events
            #
            resize = ->
                $tableHeaders = $table.find('thead')
                $headerRows = $tableHeaders.find('tr')
                pos.originalTop = $parent.offset().top
                pos.originalLeft = $table.position().left

                $container.css({
                    width: $parent[0].clientWidth
                    height: $tableHeaders.height()
                })

                $clonedTable
                    .empty()
                    .width($table.outerWidth())
                    .append($tableHeaders.clone())
                    .find('tr').each (index) ->
                        height = $headerRows.eq(index).height()
                        $(this).css('height', height)
                        $(this).find('th').each (thIndex) ->
                            originalHeader = $headerRows.eq(index).find('th').eq(thIndex)
                            $(this).css('width', originalHeader.width())

            $parent.on 'resize', _.throttle(resize, 200, { leading: false, trailing: true })

            scope.$watch 'sortBy+sortedRows', _.throttle(resize, 200, { leading: false, trailing: true })

            #
            # Handle scroll events
            #
            $parent.on 'scroll', ->
                scrollTop = $parent.scrollTop()
                elementTop = $tableHeaders.offset().top
                diff = pos.originalTop - elementTop

                if (diff > 0 && scrollTop > diff && scrollTop <= (diff + $table.height() - $tableHeaders.height()))
                    $clonedTable.css({
                        'left': -$parent.scrollLeft()
                    })

                    if not scope.visible
                        resize()
                        $container.show()
                        scope.visible = true
                else
                    $container.hide()
                    scope.visible = false

            #
            # Cleanup
            #
            scope.$on '$destroy', ->
                if $container?
                    $container.remove()
                    $container = null

                $parent.off 'resize'
                $parent.off 'scroll'
                return

            return
    }
