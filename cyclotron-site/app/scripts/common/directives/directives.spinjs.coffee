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

cyclotronDirectives.directive 'spinjs', ->
    {
        restrict: 'CA'

        link: (scope, element, attrs) ->
            elementWidth = $(element).parent().width()

            if elementWidth < 300
                radius = elementWidth / 10.0
                length = radius * 0.666
            else
                # Max dimensions
                radius = 30
                length = 20

            opts =
                # The number of lines to draw
                lines: 13

                # The length of each line
                length: length

                # The line thickness
                width: 10

                # The radius of the inner circle
                radius: radius

                # Corner roundness (0..1)
                corners: 1 

                # The rotation offset
                rotate: 0

                # 1: clockwise, -1: counterclockwise
                direction: 1
                color: '#888'

                # Rounds per second
                speed: .77

                # Afterglow percentage
                trail: 60

                # Whether to render a shadow
                shadow: false

                # Whether to use hardware acceleration
                hwaccel: false

                # The CSS class to assign to the spinner
                className: 'spinner'

                # The z-index (defaults to 2000000000)
                zIndex: 9000

                # Position relative to parent in px
                top: 'auto'
                left: 'auto'

            spinner = new Spinner(opts).spin()
            element.append(spinner.el)

            #scope.$on '$destroy', ->
            #    spinner = null
            #    element.remove()
            #    return
    }
