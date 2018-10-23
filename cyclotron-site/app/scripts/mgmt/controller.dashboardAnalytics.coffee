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
# Analytics controller -- for Dashboard analytics
#
cyclotronApp.controller 'DashboardAnalyticsController', ($scope, $stateParams, $uibModal, analyticsService, dashboardService) ->

    $scope.dashboardName = $stateParams.dashboardName

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

    $scope.viewsPerPageOptions =
        data:
            type: 'bar'
            names:
                pageViews: 'Page Views'
            keys: 
                value: ['pageViews']
        axis: 
            x: 
                type: 'category'
        
    $scope.showVisitors = false
    $scope.selectedTimespan = 'day'

    $scope.toggleVisitors = ->
        $scope.showVisitors = not $scope.showVisitors

    # Analytics relative to a startDate
    $scope.loadTimeseriesData = ->
        return unless $scope.dashboard.visits > 0

        timeSpan = $scope.selectedTimespan.split('_')
        if timeSpan.length == 1 then timeSpan.unshift 1
        startDate = moment().subtract(timeSpan[0], timeSpan[1])

        analyticsService.getUniqueVisitors($scope.dashboardId, startDate).then (visitors) ->
            $scope.uniqueVisitorCount = visitors.length
            $scope.uniqueVisitors = visitors

        analyticsService.getBrowsers($scope.dashboardId, startDate).then (browsers) ->
            $scope.browserOptions.data.keys = { value: _.pluck browsers, 'nameVersion' }
            reducedBrowsers = _.reduce browsers, (result, browser) ->
                result[browser.nameVersion] = browser.pageViews
                return result
            , {}

            $scope.browsers = [reducedBrowsers]

        analyticsService.getWidgets($scope.dashboardId, startDate).then (widgets) ->
            $scope.widgetOptions.data.keys = { value: _.pluck widgets, 'widget' }
            reducedWidgets = _.reduce widgets, (result, widget) ->
                result[widget.widget] = widget.widgetViews
                return result
            , {}

            $scope.widgets = [reducedWidgets]

        analyticsService.getDataSourcesByName($scope.dashboardId, startDate).then (dataSources) ->
            $scope.dataSources = dataSources

        analyticsService.getPageViewsPerPage($scope.dashboardId, startDate).then (viewsPerPage) ->
            categories = []

            _.each viewsPerPage, (page) -> 
                categories.push('Page ' + (page.page + 1))
            $scope.viewsPerPage = viewsPerPage
            $scope.viewsPerPageOptions.axis.x.categories = categories

        analyticsService.getPageViewsOverTime($scope.dashboardId, startDate).then (pageViews) ->
            $scope.pageViews = pageViews

        analyticsService.getVisitsOverTime($scope.dashboardId, startDate).then (visits) ->
            $scope.visits = visits

    # Initialize
    $scope.initialize = ->
        q = dashboardService.getDashboard $scope.dashboardName
        q.then (dashboard) ->

            $scope.dashboard = dashboard
            $scope.dashboardId = dashboard._id

            $scope.createdDate = '?'
            $scope.lastModifiedDate = moment(dashboard.date).format('MM/DD HH:mm:ss')
            $scope.longModifiedDate = moment(dashboard.date).format('MM/DD/YYYY HH:mm:ss')
                
            q2 = dashboardService.getRevision dashboard.name, 1

            q2.then (rev) ->
                $scope.rev1 = rev
                $scope.createdDate = moment(rev.date).format('MM/DD HH:mm:ss')
                $scope.longCreatedDate = moment(rev.date).format('MM/DD/YYYY HH:mm:ss')

                # Add watcher on the timespan control
                $scope.$watch 'selectedTimespan', (timespan) ->
                    $scope.loadTimeseriesData()

        q.catch (error) ->
            switch error.status
                when 401
                    $scope.login(true).then ->
                        $scope.initialize()
                    return
                when 403
                    $scope.dashboardEditors = error.data.data.editors
                    $scope.dashboardName = $scope.dashboardName

                    $uibModal.open {
                        templateUrl: '/partials/viewPermissionDenied.html'
                        scope: $scope
                        controller: 'GenericErrorModalController'
                        backdrop: 'static'
                        keyboard: false
                    }
                when 404
                    $uibModal.open {
                        templateUrl: '/partials/404.html'
                        scope: $scope
                        controller: 'GenericErrorModalController'
                        backdrop: 'static'
                        keyboard: false
                    }
                else
                    
                    $uibModal.open {
                        templateUrl: '/partials/500.html'
                        scope: $scope
                        controller: 'GenericErrorModalController'
                        backdrop: 'static'
                        keyboard: false
                    }

    $scope.initialize()
    
