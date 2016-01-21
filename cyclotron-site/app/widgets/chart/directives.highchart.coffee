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

# Set default options when Highcharts is loaded
# Can be overridden in a Dashboard script
Highcharts.setOptions {
    global:
        useUTC: false
    lang:
        numericSymbols: ['k', 'm', 'b', 't', 'qd', 'qt']
    tooltip:
        shared: true
}

Highcharts.dateFormats = 
    W: (timestamp) -> moment(timestamp).isoWeek()
    L: (timestamp) -> moment(timestamp).format('[Week] w (M/D - ') + moment(timestamp).add(6, 'days').format('M/D)')

# Inspired by: https://github.com/rootux/angular-highcharts-directive
cyclotronDirectives.directive 'highchart', (configService) ->
    {
        restrict: 'CA',
        replace: false,
        scope:
            chart: '='
            theme: '='
            addshift: '='

        link: (scope, element, attrs) ->
            $element = $(element)
            $parent = $element.parent()

            resize = ->
                # Set height
                parentHeight = $parent.height()

                title = $parent.children('h1')
                if title.length
                    $element.height(parentHeight - title.height())
                else
                    $element.height(parentHeight)

                # Set highcharts size
                if scope.chartObj?
                    scope.chartObj.setSize($parent.width(), $element.height(), false)
 
            chartDefaults =
                chart:
                    renderTo: element[0]
                    height: attrs.height || null
                    width: attrs.width || null

            chartConfig = configService.widgets.chart
            
            # Update when charts data changes
            scope.$watch('chart', (chart) ->
                return unless chart

                # Resize the container div (highcharts auto-sizes to the container div)
                resize()

                # Create or Update
                if scope.chartObj? && _.isEqual(_.omit(scope.currentChart, 'series'), _.omit(chart, 'series'))

                    seriesToRemove = []

                    # Update each series with new data
                    _.each scope.chartObj.series, (aSeries) ->
                        newSeries = _.find chart.series, { name: aSeries.name }

                        # Remove the series from the chart if it doesn't exist anymore.
                        if !newSeries?
                            seriesToRemove.push aSeries
                            return

                        if scope.addshift
                            # Get original series array from the scope
                            originalSeries = _.find scope.chartSeries, { name: aSeries.name }

                            willShift = originalSeries.data.length == newSeries.data.length

                            # Push new points to the right and shift from the left
                            newPoints = _.reject newSeries.data, (newPoint) ->
                                _.any originalSeries.data, (oldPoint) ->
                                    _.isEqual(oldPoint, newPoint)
                            
                            _.each newPoints, (newPoint) ->
                                aSeries.addPoint(newPoint, false, willShift, true)

                        else
                            aSeries.setData(newSeries.data, false)
                            

                    # Add new series to the chart
                    _.each chart.series, (toSeries, index) ->
                        existingSeries = _.find scope.chartObj.series, { name: toSeries.name }

                        if !existingSeries?
                            scope.chartObj.addSeries(toSeries, false)

                    # Remove any missing series
                    _.each seriesToRemove, (aSeries) ->
                        aSeries.remove(false)

                    # Redraw at once
                    scope.chartObj.redraw()

                else
                    # Clean up old chart if exists
                    if scope.chartObj?
                        scope.chartObj.destroy()

                    newChart = _.cloneDeep(chart)
                    scope.currentChart = chart

                    # Apply theme if set
                    if scope.theme?
                        Highcharts.setOptions(chartConfig.themes[scope.theme])

                    # Apply defaults 
                    _.merge(newChart, chartDefaults, _.default)

                    scope.chartSeries = newChart.series
                    scope.chartObj = new Highcharts.Chart(newChart)

            , true)

            #
            # Resize when layout changes
            #
            resizeFunction = -> 
                scope.$apply ->
                    _.delay(resize, 100)
                    _.delay(resize, 450)

            $(window).on 'resize', resizeFunction


            #
            # Cleanup
            #
            scope.$on '$destroy', ->
                $(window).off 'resize', resizeFunction
                if scope.chartObj?
                    scope.chartObj.destroy() 
                    delete scope.chartObj

            return
    }
