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

    widgetConfig = configService.widgets.annotationChart
    themeOptions = widgetConfig.themes[$scope.widget.theme]?.options || {}
    
    $scope.chartObject =
        type: 'AnnotationChart'
        options: _.assign _.cloneDeep(widgetConfig.options), themeOptions

    $scope.widgetTitle = -> _.jsExec $scope.widget.title

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

    $scope.reload = ->
        $scope.dataSource.execute(true)

    $scope.handleError = (message) ->
        console.log 'Annotation Chart error: ' + message

    # Load Data Source
    dsDefinition = dashboardService.getDataSource $scope.dashboard, $scope.widget
    $scope.dataSource = dataService.get dsDefinition
    
    # Initialize
    if $scope.dataSource?
        $scope.dataVersion = 0
        $scope.loading = true

        # Data Source (re)loaded
        $scope.$on 'dataSource:' + dsDefinition.name + ':data', (event, eventData) ->
            return unless eventData.version > $scope.dataVersion
            $scope.dataVersion = eventData.version

            $scope.dataSourceError = false
            $scope.dataSourceErrorMessage = null

            data = eventData.data[dsDefinition.resultSet].data
            
            # Filter the data if the widget has "filters"
            if $scope.widget.filters?
                data = dataService.filter(data, $scope.widget.filters)

            # Sort the data if the widget has "sortBy"
            if $scope.widget.sortBy?
                data = dataService.sort(data, $scope.widget.sortBy)

            # Check for no data
            if _.isEmpty(data) && $scope.widget.noData?
                $scope.nodata = _.jsExec($scope.widget.noData)
            else
                $scope.nodata = null
                $scope.updateChart data

            $scope.loading = false

        # Data Source error
        $scope.$on 'dataSource:' + dsDefinition.name + ':error', (event, data) ->
            $scope.dataSourceError = true
            $scope.dataSourceErrorMessage = data.error
            $scope.nodata = null
            $scope.loading = false

        # Data Source loading
        $scope.$on 'dataSource:' + dsDefinition.name + ':loading', ->
            $scope.loading = true
        
        # Initialize the Data Source
        $scope.dataSource.init dsDefinition
