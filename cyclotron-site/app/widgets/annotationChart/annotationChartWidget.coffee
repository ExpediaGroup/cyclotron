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

#
# Annotation Chart Widget
#
cyclotronApp.controller 'AnnotationChartWidget', ($scope, configService, cyclotronDataService, dashboardService, dataService, logService) ->

    $scope.annotations = 
        data: []
        popoverOpen: false

    widgetConfig = configService.widgets.annotationChart
    themeOptions = widgetConfig.themes[$scope.widget.theme]?.options || {}

    # Load events
    $scope.rangeChangeEventHandler = _.jsEval $scope.widget.events?.rangechange
    if !_.isFunction($scope.rangeChangeEventHandler) then $scope.rangeChangeEventHandler = null
    
    $scope.chartObject =
        type: 'AnnotationChart'
        options: _.assign _.cloneDeep(widgetConfig.options), themeOptions

    $scope.xAxisFormatter = switch $scope.widget.xAxis.format
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

    # Evaluates a list of series objects and stores in $scope.series
    # Auto-assigns missing annotation columns
    $scope.updateSeries = ->
        $scope.series = _.map $scope.widget.series, (series) ->
            newSeries = _.compile series, {}
            newSeries.id = newSeries.column

            if !newSeries.label? 
                newSeries.label = _.titleCase newSeries.id

            # Assign Annotation column ids
            newSeries.annotationTitleId = _.jsExec(series.annotationTitleColumn) || newSeries.id + '-title'
            newSeries.annotationTextId = _.jsExec(series.annotationTextColumn) || newSeries.id + '-text'

            return newSeries

    $scope.updateChart = (data) ->
        return unless $scope.widget.xAxis.column? and $scope.widget.series?

        logService.debug 'Updating Annotation Chart'
        $scope.chartObject.options.rev += 1

        annotationEditing = $scope.widget.annotationEditing == true

        chartData = 
            cols: []
            rows: []

        secondaryAxis = null

        # xAxis
        $scope.xAxisId = _.jsExec $scope.widget.xAxis.column

        # Evaluates series for the chart
        $scope.updateSeries()

        # Merge Annotation Data from CyclotronData (if available)
        if $scope.widget.annotationEditing == true and $scope.annotations.data?.length > 0
            _.each $scope.annotations.data, (annotationDatum) ->
                match = _.find data, (d) -> d[$scope.xAxisId] == annotationDatum.x
                if match?
                    # Merge data from annotation
                    _.merge match, annotationDatum

        # X-Axis
        chartData.cols.push {
            id: $scope.xAxisId
            label: 'xAxisLabel'
            type: 'datetime'
        }

        optionsSeries = {}

        # Series
        _.each $scope.series, (series, index) ->
            if series.secondaryAxis == true
                secondaryAxis = index

            chartData.cols.push { 
                id: series.id
                label: series.label
                type: 'number'
            }

            chartData.cols.push { 
                id: series.annotationTitleId
                label: series.id + '-title'
                type: 'string'
            }

            chartData.cols.push { 
                id: series.annotationTextId
                label: series.id + '-text'
                type: 'string'
            }

            optionsSeries[index] = {}
            if series.lineDashStyle?
                optionsSeries[index].lineDashStyle = series.lineDashStyle

        if secondaryAxis?
            scaleColumns = switch secondaryAxis
                when 0 then [0, 1] 
                else [secondaryAxis, 0]
            $scope.chartObject.options.scaleColumns = scaleColumns

        # Load data into Google format
        chartData.rows = _.map data, (row) ->
            {
                c: _.map chartData.cols, (column) ->
                    if column.type == 'datetime'
                        { v: $scope.xAxisFormatter(row[column.id]) }
                    else
                        { v: row[column.id] }
            }

        $scope.chartObject.data = chartData
        _.merge $scope.chartObject.options, _.compile($scope.widget.options, {})

        # Move focusTarget into "options"."chart"."focusTarget"
        # Undocumented option -- most options from linechart can be applied under "chart" 
        if $scope.chartObject.options.focusTarget?
            $scope.chartObject.options.chart.focusTarget = $scope.chartObject.options.focusTarget

        $scope.chartObject.options.chart.series = optionsSeries

        # Override focusTarget if Annotation Editing is enabled
        if $scope.widget.annotationEditing == true
            $scope.chartObject.options.chart.focusTarget = 'datum'

    $scope.reload = ->
        $scope.dataSource.execute(true)

    $scope.handleError = (message) ->
        logService.error 'Annotation Chart error: ' + message

    $scope.selectItem = (selectedItem) ->
        if _.isUndefined(selectedItem) or $scope.widget.annotationEditing != true or _.isEmpty($scope.widget.annotationKey)
            $scope.selectedPoint = null
            return

        seriesId = $scope.chartObject.data.cols[selectedItem.column].id
        selectedSeries = _.find $scope.series, { id: seriesId }
        
        $scope.selectedPoint = 
            x: $scope.data[selectedItem.row][$scope.xAxisId]
            series: selectedSeries
            value: $scope.chartObject.data.rows[selectedItem.row].c[selectedItem.column].v

        # Check for existingAnnotation with the same X value
        existingAnnotation = _.find $scope.annotations.data, { x: $scope.selectedPoint.x }

        # Annotation might exist for a different series..check the series ids
        if existingAnnotation? and (existingAnnotation[selectedSeries.annotationTitleId]? or existingAnnotation[selectedSeries.annotationTextId]?)
            $scope.annotations.isUpdate = true
            $scope.annotations.verb = 'Edit'
            $scope.annotations.newAnnotationTitle = existingAnnotation[selectedSeries.annotationTitleId]
            $scope.annotations.newAnnotationText = existingAnnotation[selectedSeries.annotationTextId]
        else 
            $scope.annotations.isUpdate = false
            $scope.annotations.verb = 'Add'

        $scope.selectedPoint.existingAnnotation = existingAnnotation

    $scope.saveAnnotation = ->
        key = _.jsExec $scope.widget.annotationKey
        series = $scope.selectedPoint.series
        matchingKeys = { x: $scope.selectedPoint.x }

        if $scope.selectedPoint.existingAnnotation?
            # Update local annotation in place
            $scope.selectedPoint.existingAnnotation[series.annotationTitleId] = $scope.annotations.newAnnotationTitle
            $scope.selectedPoint.existingAnnotation[series.annotationTextId] = $scope.annotations.newAnnotationText

            cyclotronDataService.upsert(key, matchingKeys, $scope.selectedPoint.existingAnnotation).then ->

                logService.debug 'Annotation Chart: edited existing annotation'
                $scope.selectedPoint = null
                $scope.annotations.popoverOpen = false
                $scope.annotations.newAnnotationTitle = null
                $scope.annotations.newAnnotationText = null

                $scope.updateChart $scope.data

        else
            newAnnotation =
                x: $scope.selectedPoint.x

            newAnnotation[series.annotationTitleId] = $scope.annotations.newAnnotationTitle
            newAnnotation[series.annotationTextId] = $scope.annotations.newAnnotationText

            cyclotronDataService.append(key, newAnnotation).then ->

                $scope.annotations.data.push newAnnotation

                logService.debug 'Annotation Chart: appended new annotation'
                $scope.selectedPoint = null
                $scope.annotations.popoverOpen = false
                $scope.annotations.newAnnotationTitle = null
                $scope.annotations.newAnnotationText = null

                $scope.updateChart $scope.data

            .catch(logService.error)

    $scope.deleteAnnotation = ->
        key = _.jsExec $scope.widget.annotationKey
        series = $scope.selectedPoint.series
        matchingKeys = { x: $scope.selectedPoint.x }

        # Update local annotation in place
        delete $scope.selectedPoint.existingAnnotation[series.annotationTitleId]
        delete $scope.selectedPoint.existingAnnotation[series.annotationTextId]

        cyclotronDataService.remove(key, matchingKeys).then ->
            cyclotronDataService.upsert(key, matchingKeys, $scope.selectedPoint.existingAnnotation).then ->

                # Remove from data array
                dataRow = _.find $scope.data, (d) -> d[$scope.xAxisId] == $scope.selectedPoint.x
                if dataRow?
                    delete dataRow[series.annotationTitleId]
                    delete dataRow[series.annotationTextId]

                logService.debug 'Annotation Chart: deleted existing annotation'
                $scope.selectedPoint = null
                $scope.annotations.popoverOpen = false
                $scope.annotations.newAnnotationTitle = null
                $scope.annotations.newAnnotationText = null

                $scope.updateChart $scope.data

    $scope.rangeChange = (start, end) ->
        if $scope.rangeChangeEventHandler?
            $scope.rangeChangeEventHandler { start, end }

    # Load Data Source
    dsDefinition = dashboardService.getDataSource $scope.dashboard, $scope.widget
    $scope.dataSource = dataService.get dsDefinition
    
    # Initialize
    if $scope.dataSource?
        $scope.dataVersion = 0
        $scope.widgetContext.loading = true

        # Data Source (re)loaded
        $scope.$on 'dataSource:' + dsDefinition.name + ':data', (event, eventData) ->
            return unless eventData.version > $scope.dataVersion
            $scope.dataVersion = eventData.version

            $scope.widgetContext.dataSourceError = false
            $scope.widgetContext.dataSourceErrorMessage = null

            data = eventData.data[dsDefinition.resultSet].data
            data = $scope.filterAndSortWidgetData(data)

            # Check for no data
            if data?
                $scope.data = data
                $scope.updateChart data

            $scope.widgetContext.loading = false

        # Data Source error
        $scope.$on 'dataSource:' + dsDefinition.name + ':error', (event, data) ->
            $scope.widgetContext.dataSourceError = true
            $scope.widgetContext.dataSourceErrorMessage = data.error
            $scope.widgetContext.nodata = null
            $scope.widgetContext.loading = false

        # Data Source loading
        $scope.$on 'dataSource:' + dsDefinition.name + ':loading', ->
            $scope.widgetContext.loading = true
        
        
        if $scope.widget.annotationEditing == true and !_.isEmpty($scope.widget.annotationKey)
            # Load annotations from CyclotronData
            cyclotronDataService.getBucketData($scope.widget.annotationKey).then (annotationData) ->
                $scope.annotations.data = annotationData || []

                # Initialize the Data Source
                $scope.dataSource.init dsDefinition
        else
            # Initialize the Data Source
            $scope.dataSource.init dsDefinition
