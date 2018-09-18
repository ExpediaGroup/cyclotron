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
# Home controller.
#
cyclotronApp.controller 'DashboardController', ($scope, $stateParams, $localForage, $location, $timeout, $window, $q, $uibModal, analyticsService, configService, cyclotronDataService, dashboardOverridesService, dashboardService, dataService, downloadService, loadService, logService, parameterService, userService) ->

    preloadTimer = null
    rotateTimer = null
    indexHistory = []

    $scope.currentPage = []
    $scope.currentPageIndex = -1
    $scope.paused = true
    $scope.firstLoad = true
    $scope.firstUrlUpdate = true
    $scope.firstParameterSync = true

    $scope.restServiceUrl = configService.restServiceUrl

    # Parse URL for Dashboard name, page
    i = $stateParams.dashboard.indexOf('/')
    if i > 0
        $scope.originalDashboardName = $stateParams.dashboard.substring(0, i)
        $scope.originalDashboardPageName = _.slugify $stateParams.dashboard.substring(i + 1)
    else
        $scope.originalDashboardName = $stateParams.dashboard
        $scope.originalDashboardPageName = null

    # Create Cyclotron global
    # Load URL querystring into Cyclotron.parameters
    $window.Cyclotron =
        version: configService.version
        currentUser: userService.currentUser()
        currentUsername: userService.cachedUsername
        currentUserPassword: userService.cachedPassword
        dataSources: {}
        functions: 
            forceUpdate: -> $scope.$apply()
            
            exportData: (format, data, name = $scope.originalDashboardName) ->
                return unless data?
                downloadService.download name, format, data

            recordEvent: (eventData) ->
                analyticsService.recordEvent 'custom', eventData
                

        parameters: _.clone $location.search()
        data: cyclotronDataService

    $scope.updateUrl = ->
        currentPage = $scope.dashboard.pages[$scope.currentPageIndex]
        pageName = dashboardService.getPageName(currentPage, $scope.currentPageIndex)

        $scope.dashboardDisplayName = _.jsExec($scope.dashboard.displayName) || $scope.dashboard.name
        loadService.setTitle $scope.dashboardDisplayName + ' | ' + pageName + ' | Cyclotron'
        if currentPage.name? || $scope.currentPageIndex != 0
            $location.path '/' + $scope.dashboard.name + '/' + _.slugify pageName
        else
            $location.path '/' + $scope.dashboard.name

        # Save values accessible to Dashboards
        Cyclotron.dashboardName = $scope.dashboard.name
        Cyclotron.pageName = pageName

        if $scope.firstUrlUpdate
            $location.replace()
            $scope.firstUrlUpdate = false

    #
    # Increments the page index and loads the next page into the dashboard (hidden)
    #
    $scope.preload = (specificIndex) ->
        # Avoid preloading twice
        return if $scope.currentPage.length > 1
        logService.debug 'Preloading next page'

        # Load a specific page if provided
        # Else increment the page index and load the current page
        if specificIndex? && _.isNumber(specificIndex)
            $scope.currentPageIndex = specificIndex
        else
            $scope.currentPageIndex = dashboardService.rotate($scope.dashboard, $scope.currentPageIndex)

        # Load the page
        $scope.currentPage.push($scope.dashboard.pages[$scope.currentPageIndex])

        # Store the current page index in the history
        indexHistory.push $scope.currentPageIndex
        if indexHistory.length > 100
            indexHistory = _.last(indexHistory, 100)

    #
    # Rotates the dashboard:
    # Removes the current page, so the preloaded page appears
    #
    $scope.rotate = ->          
        pageNumber = $scope.currentPageIndex + 1
        logService.debug 'Rotating to page', pageNumber
        $window.Cyclotron.parameters.page = pageNumber

        # Remove the current page
        if $scope.currentPage.length > 1
            $scope.currentPage.splice(0, 1)

        $scope.updateUrl()

        $window.Cyclotron.currentPage =
            widgets: {}

        # Track analytics
        analyticsService.recordPageView $scope.dashboardWrapper, $scope.currentPageIndex, $scope.firstLoad

        # Don't enable timers if paused
        return if $scope.paused

        latestPage = _.last($scope.currentPage)

        # Set the next preload timer for duration (in seconds)
        clearTimeout(preloadTimer) if preloadTimer?
        preloadTimer = setTimeout(_.ngApply($scope, $scope.preload), (latestPage.duration - $scope.dashboard.preload) * 1000)

        # Schedule next rotation
        clearTimeout(rotateTimer) if rotateTimer?
        rotateTimer = setTimeout(_.ngApply($scope, $scope.rotate), latestPage.duration * 1000)

    # Returns true if it is possible to move backwards in the dashboard pages
    $scope.canMoveBack = ->
        return false unless $scope.dashboard? && $scope.dashboard.pages?
        return $scope.dashboard.pages.length > 1

    # Returns true if it is possible to move forwards in the dashboard pages
    $scope.canMoveForward = ->
        return false unless $scope.dashboard? && $scope.dashboard.pages?
        return $scope.dashboard.pages.length > 1

    # Move forward in the dashboard
    $scope.moveForward = ->
        return unless $scope.canMoveForward()
        logService.debug 'User moving forward'

        # Preload the next page
        $scope.preload() unless $scope.currentPage.length > 1

        # Rotate to the next page
        $scope.rotate()

    $scope.moveBack = ->
        return unless $scope.canMoveBack()
        logService.debug 'User moving backward'

        if indexHistory.length > 1
            # Pop the current page off
            indexHistory.pop()

            # Get the previous page index
            $scope.currentPageIndex = _.last(indexHistory)
        else
            $scope.currentPageIndex = $scope.currentPageIndex - 1
            if $scope.currentPageIndex < 0
                $scope.currentPageIndex = $scope.dashboard.pages.length - 1

        # Set the previous page and re-enable rotation
        $scope.currentPage = [$scope.dashboard.pages[$scope.currentPageIndex]]
        $scope.rotate()

    $scope.goToPage = (pageNumber) ->
        if pageNumber > $scope.dashboard.pages.length
            pageNumber = 1

        $window.Cyclotron.parameters.page = pageNumber
        $scope.preload(pageNumber - 1)
        $scope.rotate()

    # Stop rotation of dashboard
    $scope.pause = ->
        $scope.paused = true

        # Cancel pending timers
        clearTimeout(preloadTimer) if preloadTimer?
        clearTimeout(rotateTimer) if rotateTimer?

    # Enable rotation of dashboard
    $scope.play = ->
        return unless $scope.canMoveForward()
        $scope.paused = false
        $scope.rotate()

    # Toggles between paused/playing
    $scope.togglePause = ->
        if $scope.paused == true
            $scope.play()
        else
            $scope.pause()

    toggleLikeHelper = ->
        if $scope.isLiked
            dashboardService.unlike($scope.dashboardWrapper).then ->
                $scope.isLiked = false
        else
            dashboardService.like($scope.dashboardWrapper).then ->
                $scope.isLiked = true

    $scope.toggleLike = ->
        if userService.authEnabled and !userService.isLoggedIn()
            $scope.login(true).then toggleLikeHelper
        else
            toggleLikeHelper()

    handleQueryStringChanges = (parameters, oldParameters) ->
        return if _.isEqual(parameters, oldParameters)
        logService.debug 'Updating Cyclotron.parameters from querystring'

        _.assign($window.Cyclotron.parameters, parameters)

        # Remove deleted parameters
        deletedKeys = _.difference(_.keys(oldParameters), _.keys(parameters))
        _.each deletedKeys, (key) ->
            logService.debug 'Removing parameter from Cyclotron.parameters: ' + key
            delete Cyclotron.parameters[key]
            return

        if parameters.page != oldParameters.page
            $scope.goToPage(parameters.page)

    handleParameterChanges = (parameters, oldParameters) ->
        return if _.isEqual(parameters, oldParameters)
        logService.debug 'Updating querystring from Cyclotron.parameters'

        # Remove deleted parameters from the URL
        deletedKeys = _.difference(_.keys(oldParameters), _.keys(parameters))
        _.each deletedKeys, (key) ->
            logService.debug 'Removing parameter from URL: ' + key
            $location.search(key, null)
            return

        # Save any persistent parameters
        parameterService.savePersistentParameters parameters, $scope.dashboard

        exportOptions = {}
        deeplinkOptions = {}

        _.each parameters, (value, key) ->
            parameterDefinition = _.find $scope.dashboard.parameters, { name: key }
            defaultValue = parameterDefinition?.defaultValue

            showInUrl = true
            if parameterDefinition?.showInUrl == false then showInUrl = false

            stringify = (v) ->
                if moment.isMoment(value)
                    v.toISOString()
                else
                    v

            if key == 'page'
                $location.search(key, null)
            else if defaultValue? and stringify(_.jsExec(defaultValue)) == stringify(value)
                $location.search(key, null)
                deeplinkOptions[key] = stringify(value)
            else if !showInUrl
                $location.search(key, null)
                deeplinkOptions[key] = stringify(value)
                exportOptions[key] = stringify(value) 
            else if key == 'live'
                $location.search key, stringify(value)
                deeplinkOptions[key] = stringify(value)
            else 
                $location.search key, stringify(value)
                deeplinkOptions[key] = stringify(value)
                exportOptions[key] = stringify(value) 

            if parameterDefinition? and not _.isEqual value, oldParameters[key]
                changeHandler = _.jsEval parameterDefinition.changeEvent
                if _.isFunction changeHandler
                    changeHandler key, value, oldParameters[key]

            return

        # Replace URL on initial load, to avoid creating an extra browser history item
        if $scope.firstParameterSync
            $location.replace()
            $scope.firstParameterSync = false

        # Create export options from non-default parameters
        $scope.exportUrl = new URI('/export')
            .segment $scope.dashboard.name
            .search exportOptions
            .toString()

        # Save deeplink options for later
        $scope.deeplinkOptions = deeplinkOptions

    #
    # Initialization methods
    #
    $scope.loadDashboard = (deferred = $q.defer()) ->

        q = dashboardService.getDashboard($scope.originalDashboardName, $window.Cyclotron.parameters.rev)
        q.then (dashboardWrapper) ->

            if dashboardWrapper.deleted                
                $uibModal.open {
                    templateUrl: '/partials/410.html'
                    scope: $scope
                    controller: 'GenericErrorModalController'
                    backdrop: 'static'
                    keyboard: false
                }
                return

            # The dashboard wrapper contains the rev, date, author, etc.
            $scope.dashboardWrapper = Cyclotron.dashboard = dashboardWrapper
            $scope.isLiked = userService.likesDashboard dashboardWrapper

            # Set defaults then save to the scope
            dashboard = dashboardWrapper.dashboard            

            dashboardService.setDashboardDefaults(dashboard)
            $scope.dashboard = dashboard

            # Optionally disable analytics
            if dashboard.disableAnalytics == true
                configService.analytics ?= {}
                configService.analytics.enable = false

            dependenciesLoaded = -> 
                # Check if a new revision of the Dashboard has been loaded
                if $scope.latestRevision and $scope.latestRevision < $scope.dashboardWrapper.rev
                    # Update current page if needed
                    originalPage = $scope.currentPage[$scope.currentPage.length-1]
                    newPage = $scope.dashboard.pages[$scope.currentPageIndex]
                    if !angular.equals(originalPage, newPage)
                        logService.debug 'Replacing the current page with a new revision'
                        $scope.currentPage[$scope.currentPage.length-1] = newPage

                $scope.latestRevision = $scope.dashboardWrapper.rev

                # Resolve promise
                deferred.resolve()

                # Schedule a continuous reload of the Dashboard
                $timeout(->
                    $scope.loadDashboard().then $scope.subsequentLoad
                , $scope.reloadInterval)

                return

            # Clean old CSS first
            loadService.removeLoadedCss()

            # Load any external/inline CSS styles defined in the dashboard
            _.each dashboard.styles, (s) ->
                if _.isEmpty(s.path)
                    loadService.loadCssInline s.text
                else
                    loadService.loadCssUrl s.path

            # Load external/inline scripts sequentially before continuing
            # Recursive sequential loader
            hasAsynchLoaded = false
            load = (list) ->
                if _.isEmpty list
                    # If the asynch was used, need to use $scope.$apply..
                    if hasAsynchLoaded
                        $scope.$apply(dependenciesLoaded)
                    else
                        dependenciesLoaded()
                else
                    currentScript = _.head list
                    tail = _.tail list
                    nextInvocation = _.wrap(tail, load)

                    if currentScript.singleLoad == true && $scope.firstLoad == false
                        # Skip it
                        nextInvocation()
                    else if _.isEmpty(currentScript.path)
                        eval.call($window, currentScript.text)
                        nextInvocation()
                    else
                        hasAsynchLoaded = true
                        $script(currentScript.path, nextInvocation)

            # Load external scripts
            load(dashboard.scripts)

        q.catch (error) ->
            switch error.status
                when 401
                    $scope.login(true).then ->
                        $scope.loadDashboard(deferred)
                    return
                when 403
                    $scope.dashboardEditors = error.data.data.editors
                    $scope.dashboardName = $scope.originalDashboardName

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
                    if $scope.firstLoad
                        # Display error message if error occurred on the first load
                        $uibModal.open {
                            templateUrl: '/partials/500.html'
                            scope: $scope
                            controller: 'GenericErrorModalController'
                            backdrop: 'static'
                            keyboard: false
                        }
                    else 
                        # Keep retrying
                        $timeout($scope.loadDashboard, $scope.reloadInterval)

            deferred.reject()

        return deferred.promise

    # Method to be called after the first load of the Dashboard
    $scope.initialLoad = ->

        # Load theme css(s) 
        themes = dashboardService.getThemes $scope.dashboard
        _.each themes, (theme) ->
            loadService.loadCssUrl('/css/app.themes.' + theme + '.css', true)

        # Initialize dashboard overrides
        dashboardOverridesService.initializeDashboardOverrides($scope.dashboard).then (dashboardOverrides) ->
            # Store for Dashboard use
            $window.Cyclotron.dashboardOverrides = $scope.dashboardOverrides = dashboardOverrides

            $scope.$watch 'dashboardOverrides', (updatedOverrides, previousOverrides) ->
                return if _.isEqual updatedOverrides, previousOverrides
                dashboardOverridesService.saveDashboardOverrides($scope.dashboard, updatedOverrides)
            , true

            $scope.resetDashboardOverrides = ->
                $window.Cyclotron.dashboardOverrides = $scope.dashboardOverrides = dashboardOverridesService.resetAndExpandOverrides $scope.dashboard

            # Initialize parameters
            parameterService.initializeParameters($scope.dashboard).then ->

                # Watch querystring for changes
                $scope.$watch (-> $location.search()), handleQueryStringChanges

                # Watch Parameters for changes
                $scope.$watch (-> $window.Cyclotron.parameters), handleParameterChanges, true
                
                # Preload any data sources with preload: true
                preloadDataSources = _.filter $scope.dashboard.dataSources, { preload: true }

                _.each preloadDataSources, (dataSourceDefinition) ->
                    logService.info 'Preloading data source', dataSourceDefinition.name
                    dataSource = dataService.get(dataSourceDefinition)
                    dataSource.getData(dataSourceDefinition, _.noop, _.noop, _.noop)
                    return

                # Only load if there are any pages
                if $scope.dashboard.pages.length > 0
                    # Navigate to a particular page if specified
                    if $window.Cyclotron.parameters.page?
                        $scope.goToPage parseInt($window.Cyclotron.parameters.page)
                    else if !_.isEmpty $scope.originalDashboardPageName
                        pageNames = _.pluck $scope.dashboard.pages, 'name'
                        pageIndex = _.findIndex pageNames, (name) ->
                            name? and _.slugify(name) == $scope.originalDashboardPageName

                        if pageIndex >= 0
                            $scope.goToPage 1 + pageIndex
                        else if $scope.originalDashboardPageName.match(/page-\d+$/)
                            $scope.goToPage parseInt($scope.originalDashboardPageName.substring(5))
                        else
                            $scope.goToPage 1
                    else
                        $scope.goToPage 1

                # Start Dashboard Rotation            
                if $window.Cyclotron.parameters.autoRotate == "true" or $scope.dashboard.autoRotate == true
                    # ?autoRotate=true/false will override the dashboard setting.
                    # There is also a dashboard property which can disable rotation.
                    # Only enable rotation if there are multiple pages
                    if $scope.dashboard.pages.length > 1
                        $scope.paused = false
                        $scope.rotate()
                
                $scope.firstLoad = false

    # Method to be called after reloading the dashboard (compared to $scope.initialLoad)
    $scope.subsequentLoad = ->
        # Expand overrides to add defaults for any added widgets
        dashboardOverridesService.expandOverrides $scope.dashboard, $scope.dashboardOverrides

    # Initial load - load dashboard and initialize rotation
    $scope.reloadInterval = if $window.Cyclotron.parameters.live == 'true' then 1500 else 60000

    # Helper functions
    $window.Cyclotron.goToPage = $scope.goToPage
    $window.Cyclotron.getDeeplink = -> 
        new URI()
            .search $scope.deeplinkOptions
            .toString()

    # Load the dashboard
    $scope.loadDashboard().then $scope.initialLoad

    #
    # Hot Key Bindings
    #
    $('body').bind('keydown', 'left', _.ngNonPropagatingHandler($scope, $scope.moveBack))
    $('body').bind('keydown', 'pageup', _.ngNonPropagatingHandler($scope, $scope.moveBack))
    $('body').bind('keydown', 'right', _.ngNonPropagatingHandler($scope, $scope.moveForward))
    $('body').bind('keydown', 'pagedown', _.ngNonPropagatingHandler($scope, $scope.moveForward))
    $('body').bind('keydown', 'space', _.ngNonPropagatingHandler($scope, $scope.togglePause))
