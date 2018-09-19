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
            $title = $parent.children('h1')

            # Reference to Highcharts Chart object
            highchartsObj = null

            resize = ->
                # Set height
                parentHeight = $parent.height()

                if $title.length
                    $element.height(parentHeight - $title.height())
                else
                    $element.height(parentHeight)

                # Set highcharts size
                if highchartsObj?
                    highchartsObj.setSize($parent.width(), $element.height(), false)
 
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
                if highchartsObj? && _.isEqual(_.omit(scope.currentChart, 'series'), _.omit(chart, 'series'))

                    seriesToRemove = []

                    # Update each series with new data
                    _.each highchartsObj.series, (aSeries) ->
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
                        existingSeries = _.find highchartsObj.series, { name: toSeries.name }

                        if !existingSeries?
                            highchartsObj.addSeries(toSeries, false)

                    # Remove any missing series
                    _.each seriesToRemove, (aSeries) ->
                        aSeries.remove(false)

                    # Redraw at once
                    highchartsObj.redraw()

                else
                    # Clean up old chart if exists
                    if highchartsObj?
                        highchartsObj.destroy()

                    newChart = _.cloneDeep(chart)
                    scope.currentChart = chart

                    # Apply theme if set
                    if scope.theme?
                        Highcharts.setOptions(chartConfig.themes[scope.theme])

                    # Apply defaults 
                    _.merge(newChart, chartDefaults, _.default)

                    scope.chartSeries = newChart.series
                    highchartsObj = new Highcharts.Chart(newChart)

            , true)

            #
            # Resize when layout changes
            #
            resizeFunction = _.debounce resize, 100, { leading: false, maxWait: 300 }
            $(window).on 'resize', resizeFunction

            #
            # Cleanup
            #
            scope.$on '$destroy', ->
                $(window).off 'resize', resizeFunction
                if highchartsObj?
                    highchartsObj.destroy()
                    highchartsObj = null

            return
    }
