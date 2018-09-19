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

cyclotronServices.factory 'analyticsService', ($http, $q, $localForage, $location, configService, logService, userService) ->

    # Helper for API methods that take optional dashboardId/startDate/endDate
    analyticsHelper = (name, endpoint, dashboardId, startDate, endDate) ->
        parameters = { }

        if dashboardId? then parameters.dashboard = dashboardId
        if startDate? then parameters.startDate = startDate.toISOString()
        if endDate? then parameters.endDate = endDate.toISOString()

        # Calculate appropriate resolution from the time range
        if startDate?

            # Default end date is now
            if startDate? and !endDate?
                endDate = moment()

            duration = endDate.diff(startDate, 'hours')
            if duration > 72 
                parameters.resolution = 'day'
            else if duration > 4 
                parameters.resolution = 'hour'
            else
                parameters.resolution = 'minute'

        $http.get(configService.restServiceUrl + '/analytics/' + endpoint, { params: parameters })
        .then (result) ->
            _.each result.data, (row) ->
                # Convert date strings to Date objects
                if row.date? then row.date = new Date(row.date)
            result.data

        .catch (error) ->
            alertify.error 'Cannot connect to cyclotron-svc (' + name + ')', 2500
            
    exports = {

        # Generated identifier for this "visit", e.g. dashboard viewing session
        visitId: uuid.v4()

        # Unique user identifier (when logged-out)
        uid: null

        currentDashboard: null

        currentPage: null

        isExporting: $location.search().exporting == 'true'

        getPageViewsOverTime: (dashboardId, startDate, endDate) ->
            analyticsHelper 'getPageViewsOverTime', 'pageviewsovertime', dashboardId, startDate, endDate

        getVisitsOverTime: (dashboardId, startDate, endDate) ->
            analyticsHelper 'getVisitsOverTime', 'visitsovertime', dashboardId, startDate, endDate

        getUniqueVisitors: (dashboardId, startDate, endDate) ->
            analyticsHelper 'getUniqueVisitors', 'uniquevisitors', dashboardId, startDate, endDate

        getBrowsers: (dashboardId, startDate, endDate) ->
            analyticsHelper 'getBrowsers', 'browsers', dashboardId, startDate, endDate

        getWidgets: (dashboardId, startDate, endDate) ->
            analyticsHelper 'getWidgets', 'widgets', dashboardId, startDate, endDate

        getPageViewsPerPage: (dashboardId, startDate, endDate) ->
            analyticsHelper 'getPageViewsPerPage', 'pageviewsbypage', dashboardId, startDate, endDate

        getDataSourcesByType: (dashboardId, startDate, endDate) ->
            analyticsHelper 'getDataSourcesByType', 'datasourcesbytype', dashboardId, startDate, endDate

        getDataSourcesByName: (dashboardId, startDate, endDate) ->
            analyticsHelper 'getDataSourcesByName', 'datasourcesbyname', dashboardId, startDate, endDate

        getDataSourcesByError: (dashboardId, startDate, endDate) ->
            analyticsHelper 'getDataSourcesByError', 'datasourcesbyerrormessage', dashboardId, startDate, endDate

        getTopDashboards: (startDate, endDate) ->
            analyticsHelper 'getTopDashboards', 'topdashboards', null, startDate, endDate
    
        getStatistics: ->
            $http.get(configService.restServiceUrl + '/statistics')
            .then (result) ->
                result.data
            .catch (error) ->
                alertify.error 'Cannot connect to cyclotron-svc (getStatistics)', 2500
    }

    # Unique user identifier for anonymous users, stored in local storage
    # Used *only* for analytics

    # Promise to avoid sending analytics without a UID value
    uidLoaded = $q.defer()

    $localForage.getItem('uid').then (existingUid) ->
        if not existingUid?
            # Generate new uid
            exports.uid = uuid.v4()
            $localForage.setItem 'uid', exports.uid
        else 
            exports.uid = existingUid

        uidLoaded.resolve()

    # Record a Page View (occurance of a page being viewed)
    exports.recordPageView = (dashboard, pageIndex, newVisit = false) ->
        return unless configService.analytics.enable

        exports.currentDashboard = dashboard
        exports.currentPage = pageIndex

        # Exclude hidden widgets
        widgets = _.reject dashboard.dashboard.pages[pageIndex].widgets, { hidden: true }

        req = 
            visitId: exports.visitId
            dashboard: 
                _id: dashboard._id
                name: dashboard.name
            rev: dashboard.rev
            page: pageIndex
            widgets: _.pluck widgets, 'widget'
            browser:
                name: bowser.name
                version: bowser.version

        uidLoaded.promise.then ->
            if (userService.authEnabled && userService.isLoggedIn())
                req.user = 
                    _id: userService.currentUser()._id
                    sAMAccountName: userService.currentUser().sAMAccountName
                    name: userService.currentUser().name
            else
                # Anonymous: track the UID
                req.uid = exports.uid 

                # Also send cached UserId if it exists
                if userService.cachedUserId?
                    req.user = 
                        _id: userService.cachedUserId
                
            logService.debug 'Page View Analytics:', req
            $http.post(configService.restServiceUrl + '/analytics/pageviews?newVisit=' + newVisit + '&' + 'exporting=' + exports.isExporting, req)

    # Record the execution of a Data Source
    exports.recordDataSource = (dataSource, success, duration, details = {}) ->
        return unless configService.analytics.enable and not exports.isExporting

        details = _.merge(details, _.pick(dataSource, [ 'url', 'proxy', 'refresh' ]))
        
        req = 
            visitId: exports.visitId
            dashboard: 
                _id: exports.currentDashboard._id
                name: exports.currentDashboard.name
            rev: exports.currentDashboard.rev
            page: exports.currentPage
            dataSourceName: dataSource.name
            dataSourceType: dataSource.type
            success: success
            duration: duration
            details: details

        logService.debug 'Data Source Analytics:', req

        $http.post(configService.restServiceUrl + '/analytics/datasources', req)

    # Generic schema for recording events
    exports.recordEvent = (type, details = {}) ->
        return unless configService.analytics.enable
        req = 
            eventType: type
            visitId: exports.visitId
            details: details

        if exports.currentDashboard?
            req.dashboard = 
                _id: exports.currentDashboard._id
                name: exports.currentDashboard.name

        uidLoaded.promise.then ->
            if (userService.authEnabled && userService.isLoggedIn())
                req.user = 
                    _id: userService.currentUser()._id
                    sAMAccountName: userService.currentUser().sAMAccountName
                    name: userService.currentUser().name
            else
                # Anonymous: track the UID
                req.uid = exports.uid 

                # Also send cached UserId if it exists
                if userService.cachedUserId?
                    req.user = 
                        _id: userService.cachedUserId

            logService.debug 'Event Analytics:', req
            $http.post(configService.restServiceUrl + '/analytics/events', req)

    return exports
