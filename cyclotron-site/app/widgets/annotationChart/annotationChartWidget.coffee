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

#
# Annotation Chart Widget
#
cyclotronApp.controller 'AnnotationChartWidget', ($scope, configService, dashboardService, dataService) ->

    $scope.loading = false
    $scope.dataSourceError = false
    $scope.dataSourceErrorMessage = null

    $scope.widgetTitle = -> _.jsExec $scope.widget.title

    # Load data source
    dsDefinition = dashboardService.getDataSource($scope.dashboard, $scope.widget)
    $scope.dataSource = dataService.get(dsDefinition)

    widgetConfig = configService.widgets.annotationChart
    themeOptions = widgetConfig.themes[$scope.widget.theme]?.options || {}
    
    $scope.chartObject =
        type: 'AnnotationChart'
        options: _.assign _.cloneDeep(widgetConfig.options), themeOptions

    $scope.updateChart = (data) ->
        return unless $scope.widget.xAxis.column? and $scope.widget.series?

        chartData = 
            cols: []
            rows: []

        secondaryAxis = null

        # xAxis
        xAxisId = _.jsExec $scope.widget.xAxis.column

        chartData.cols.push {
            id: xAxisId
            label: 'xAxisLabel'
            type: 'datetime'
        }

        xAxisFormatter = switch $scope.widget.xAxis.format
            when 'epoch' then (d) ->
                moment.unix(d).toDate()
            when 'epochmillis' then (d) ->
                moment(d).toDate()
            when 'string' then (d) ->
                if $scope.widget.xAxis.formatString?
                    moment(d, $scope.widget.xAxis.formatString).toDate()
                else 
                    moment(d).toDate()
            else _.identity

        # Series
        _.each $scope.widget.series, (series, index) ->
            columnId = _.jsExec series.column
            label = _.jsExec series.label
            if !label? then label = _.titleCase columnId

            if series.secondaryAxis == true
                secondaryAxis = index

            chartData.cols.push { 
                id: columnId
                label: label
                type: 'number'
            }

            if series.annotationTitleColumn?
                id = _.jsExec series.annotationTitleColumn
                chartData.cols.push { 
                    id: id
                    label: columnId + '-title'
                    type: 'string'
                }

            if series.annotationTextColumn?
                id = _.jsExec series.annotationTextColumn
                chartData.cols.push { 
                    id: id
                    label: columnId + '-text'
                    type: 'string'
                }

        if secondaryAxis?
            scaleColumns = switch secondaryAxis
                when 0 then [0, 1] 
                else [secondaryAxis, 0]
            $scope.chartObject.options.scaleColumns = scaleColumns

        chartData.rows = _.map data, (row) ->
            {
                c: _.map chartData.cols, (column) ->
                    if column.type == 'datetime'
                        { v: xAxisFormatter(row[column.id]) }
                    else
                        { v: row[column.id] }
            }

        $scope.chartObject.data = chartData
        _.merge $scope.chartObject.options, _.compile($scope.widget.options, {})

        console.log $scope.chartObject

    # Load data from the data source
    $scope.loadData = ->
        # Reset scope variables
        $scope.loading = true
        $scope.dataSourceError = false
        $scope.dataSourceErrorMessage = null

        $scope.dataSource.getData(dsDefinition, (data, headers, isUpdate, diff) ->

            $scope.dataSourceError = false
            $scope.dataSourceErrorMessage = null

            # Filter the data with the widget filters if needed
            if $scope.widget.filters?
                data = dataService.filter(data, $scope.widget.filters)

            # Sort the data if the widget has sortBy
            if $scope.widget.sortBy?
                data = dataService.sort(data, $scope.widget.sortBy)

            # Check for no Data
            if _.isEmpty(data) && $scope.widget.noData?
                $scope.nodata = _.jsExec($scope.widget.noData)
            else
                $scope.nodata = null
                $scope.updateChart data

            $scope.loading = false

        , (errorMessage, status) ->
            $scope.loading = false

            # Error callback
            $scope.dataSourceError = true
            $scope.dataSourceErrorMessage = errorMessage
            $scope.nodata = null
        , ->
            $scope.loading = true
        )

    $scope.reload = ->
        $scope.dataSource.execute(true)

    $scope.handleError = (message) ->
        console.log 'Annotation Chart error: ' + message

    # Initialize
    if not _.isUndefined(dsDefinition)
        $scope.loadData()
