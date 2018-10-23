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

cyclotronDirectives.directive 'metricsGraphics', ->
    {
        restrict: 'EAC'
        scope: 
            data: '='
            options: '='

        link: (scope, element) ->

            $element = $(element)
            chartWidth = $element.width()

            # Generate random element ID
            if _.isEmpty $element.prop('id')
                scope.id = 'mg-' + uuid.v4()
                $element.prop 'id', scope.id

            redraw = ->
                return unless scope.data?

                options = 
                    title: null
                    height: 200
                    width: chartWidth
                    target: '#' + scope.id
                    data: scope.data
                    interpolate: 'cardinal'
                    interpolate_tension: 0.95

                # Apply passed options
                _.assign options, scope.options

                # Wrap mouseover
                if options.mouseover?
                    getMouseoverText = options.mouseover
                    options.mouseover = (d, i) ->
                        text = getMouseoverText(d, i)
                        d3.select('#' + scope.id + ' svg .mg-active-datapoint').text(text)

                MG.data_graphic options
            
            scope.$watch 'data', (newData) ->
                redraw()

            $element.resize _.debounce ->
                chartWidth = $element.width()
                redraw()
            , 100, { leading: false, maxWait: 300 }
    }
