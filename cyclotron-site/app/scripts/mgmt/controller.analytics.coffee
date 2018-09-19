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
# Analytics controller
#
cyclotronApp.controller 'AnalyticsController', ($scope, $uibModal, analyticsService) ->

    $scope.smallLimit = 10
    $scope.largeLimit = 20

    $scope.uniqueVisitorLimit = $scope.smallLimit
    $scope.browserLimit = $scope.smallLimit
    $scope.topDashboardsLimit = $scope.smallLimit
    $scope.dataSourcesLimit = $scope.smallLimit
    $scope.dataSourceTypeLimit = $scope.smallLimit
    $scope.widgetTypeLimit = $scope.smallLimit

    $scope.toggleLimit = (limit) ->
        if $scope[limit] == $scope.smallLimit
            $scope[limit] = $scope.largeLimit
        else
            $scope[limit] = $scope.smallLimit

    $scope.pageViewsOptions = 
        x_accessor: 'date'
        y_accessor: 'pageViews'
        mouseover: (d, i) ->
            d.pageViews + ' page view' + (if d.pageViews == 1 then '' else 's')  + ' | ' + moment(d.date).format('MMM Do HH:mm')

    $scope.visitsOptions = 
        x_accessor: 'date'
        y_accessor: 'visits'
        mouseover: (d, i) ->
            d.visits + ' visit' + (if d.visits == 1 then '' else 's')  + ' | ' + moment(d.date).format('MMM Do HH:mm')

    $scope.browserOptions =
        data:
            type: 'pie'

    $scope.widgetOptions =
        data:
            type: 'pie'

    $scope.dataSourceTypesOptions =
        data:
            type: 'pie'
        
    $scope.showVisitors = false
    $scope.selectedTimespan = 'day'

    $scope.toggleVisitors = ->
        $scope.showVisitors = not $scope.showVisitors

    # Analytics over time
    $scope.loadLifetimeData = ->

        analyticsService.getStatistics().then (statistics) ->
            $scope.statistics = statistics

    # Analytics relative to a startDate
    $scope.loadTimeseriesData = ->
        timeSpan = $scope.selectedTimespan.split('_')
        if timeSpan.length == 1 then timeSpan.unshift 1
        startDate = moment().subtract(timeSpan[0], timeSpan[1])

        analyticsService.getTopDashboards(startDate).then (dashboards) ->
            $scope.topDashboards = dashboards

        analyticsService.getPageViewsOverTime(null, startDate).then (pageViews) ->
            $scope.pageViews = pageViews

        analyticsService.getVisitsOverTime(null, startDate).then (visits) ->
            $scope.visits = visits

        analyticsService.getUniqueVisitors(null, startDate).then (visitors) ->
            $scope.uniqueVisitorCount = visitors.length
            $scope.uniqueVisitors = visitors

        analyticsService.getBrowsers(null, startDate).then (browsers) ->
            $scope.browsers = browsers

            # Pie chart
            sorted = _.sortBy(browsers, 'pageViews')
            filteredBrowsers = _.take(browsers, 6)
            otherPageViews = _.reduce(_.drop(browsers, 6), ((total, browser) -> total + browser.pageViews), 0)
            filteredBrowsers.push { nameVersion: 'Other', pageViews: otherPageViews }
            $scope.browserOptions.data.keys = { value: _.pluck filteredBrowsers, 'nameVersion' }
            reducedBrowsers = _.reduce filteredBrowsers, (result, browser) ->
                result[browser.nameVersion] = browser.pageViews
                return result
            , {}

            $scope.browsersPie = [reducedBrowsers]

        analyticsService.getDataSourcesByType(null, startDate).then (dataSourcesByType) ->
            $scope.dataSourcesByType = dataSourcesByType

            $scope.dataSourceTypesOptions.data.keys = { value: _.pluck dataSourcesByType, 'dataSourceType' }
            reducedTypes = _.reduce dataSourcesByType, (result, type) ->
                result[type.dataSourceType] = type.count
                return result
            , {}

            $scope.dataSourcesPie = [reducedTypes]

        analyticsService.getWidgets(null, startDate).then (widgets) ->
            widgets = _.reject widgets, (widget) -> _.isEmpty(widget.widget)
            $scope.widgets = widgets
            
            $scope.widgetOptions.data.keys = { value: _.pluck widgets, 'widget' }
            reducedWidgets = _.reduce widgets, (result, widget) ->
                result[widget.widget] = widget.widgetViews
                return result
            , {}

            $scope.widgetsPie = [reducedWidgets]

        analyticsService.getDataSourcesByName(null, startDate).then (dataSources) ->
            $scope.dataSources = dataSources

    # Initialize
    $scope.loadLifetimeData()

    $scope.$watch 'selectedTimespan', (timespan) ->
        $scope.loadTimeseriesData()

