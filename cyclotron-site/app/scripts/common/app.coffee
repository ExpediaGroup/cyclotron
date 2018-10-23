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

# Browser compatibility based on Modernizr 
# Requires jQuery, so this doesn't work for IE8.. (with jQuery 2.x)
$ -> 
    browserCompatible = true

    # Disable browser check with ?browsercheck=false
    if window.location.search.toLowerCase().indexOf("browsercheck=false") < 0
        _.forIn Modernizr, (value, key) ->
            return if key.substring(0) == '_'
            if value == false then browserCompatible = false

    if (browserCompatible == false)
        console.log('Browser Compatibility: ' + browserCompatible)
        if window.JSON then console.log(JSON.stringify(Modernizr))
        $('body').removeClass('ng-cloak')
        $('#browserError').removeClass('hidden')
        $('body section').remove()
    else
        $('#browserError').remove()

# Cyclotron main application
cyclotronApp = angular.module 'cyclotronApp', [
    'ngAnimate'
    'ngResource'
    'ngSanitize'
    'ngTranscludeMod'
    'ngNumeraljs'
    'cyclotronApp.directives'
    'cyclotronApp.services'
    'cyclotronApp.dataSources'
    'ui.router'
    'ui.select'
    'ui.bootstrap'
    'ui.ace'
    'dndLists'
    'drahak.hotkeys'
    'googlechart'
    'LocalForageModule'
    'tableSort'
    'uiSwitch'
]

cyclotronDirectives = angular.module 'cyclotronApp.directives', []
cyclotronDataSources = angular.module 'cyclotronApp.dataSources', ['ngResource']
cyclotronServices = angular.module 'cyclotronApp.services', ['ngResource']

cyclotronApp.config ($stateProvider, $urlRouterProvider, $locationProvider, $controllerProvider, $compileProvider, $provide, uiSelectConfig) ->

    # Improve performance
    $compileProvider.debugInfoEnabled false

    uiSelectConfig.theme = 'select2'

    # Save some providers for later
    cyclotronApp.controllerProvider = $controllerProvider
    cyclotronApp.compileProvider = $compileProvider
    cyclotronApp.provide = $provide

    # Replace the usual services with these providers to allow lazy loading transparently.
    cyclotronApp.controller = $controllerProvider.register
    cyclotronDirectives.directive = $compileProvider.directive
    cyclotronDataSources.factory = $provide.factory
    cyclotronServices.factory = $provide.factory

    cyclotronApp.loadedScripts = []

    # Helper that returns a dependency function for the route provider
    # The function loads all dependencies and resolves a promise
    lazyLoad = (jsDependencies, cssDependencies) ->
        ['$q', '$rootScope', ($q, $rootScope) ->
            deferred = $q.defer()
            cyclotronApp.loadedScripts ?= []

            # Load stylesheets
            if cssDependencies?
                _.each cssDependencies, _.loadCssFile

            # Load scripts
            # Work around the relative paths
            unloadedScripts = _.filter jsDependencies, (url) ->
                tail = _.last url.split('/')
                if _.contains cyclotronApp.loadedScripts, tail
                    return false

                cyclotronApp.loadedScripts.push tail
                return true

            if unloadedScripts.length > 0

                load = (list) ->
                    if _.isEmpty list
                        $rootScope.$apply -> 
                            deferred.resolve()
                    else
                        currentScript = _.head(list)
                        nextInvocation = _.wrap(_.tail(list), load)

                        $script(currentScript, nextInvocation)
                        
                # Load external scripts
                load(unloadedScripts)
            else
                deferred.resolve()

            return deferred.promise
        ]

    # Attempts to load a cached session
    loadExistingSession = ['userService', (userService) ->
        userService.loadExistingSession()
    ]

    loadExistingSessionWithoutAlerts = ['userService', (userService) ->
        userService.loadExistingSession(true)
    ]

    #
    # Application Router
    #

    # Rewrite URLs to be cleaner
    $urlRouterProvider.when(/\/edit\/(.*?)\/(?!analytics).*?/i, '/edit/$1')
    $urlRouterProvider.when('/edit/:dashboardName/analytics', '/analytics/:dashboardName')
    $urlRouterProvider.when('/export/:dashboardName/:junk', '/export/:dashboardName')
    $urlRouterProvider.when('/export', '/export/')

    $stateProvider
        .state('home', {
            url: '/'
            templateUrl: '/partials/home.html'
            controller: 'HomeController'
            data:
                title: 'Cyclotron'
            resolve:
                session: loadExistingSession
                deps: lazyLoad ['/js/app.mgmt.js'], ['/css/app.mgmt.css']
        })
        .state('help', {
            url: '/help'
            templateUrl: '/partials/help.html'
            controller: 'HelpController'
            data:
                title: 'Cyclotron | Help'
            resolve:
                session: loadExistingSession
                deps: lazyLoad ['/js/app.mgmt.js'], ['/css/app.mgmt.css']
        })
        .state('analytics', {
            url: '/analytics'
            templateUrl: '/partials/analytics.html'
            controller: 'AnalyticsController'
            data:
                title: 'Cyclotron | Analytics'
            resolve:
                session: loadExistingSession
                deps: lazyLoad ['/js/app.mgmt.js'], ['/css/app.mgmt.css']
        })
        .state('dashboardAnalytics', {
            url: '/analytics/{dashboardName:.*}'
            templateUrl: '/partials/dashboardAnalytics.html'
            controller: 'DashboardAnalyticsController'
            data:
                title: 'Cyclotron | Dashboard Analytics'
            resolve:
                session: loadExistingSession
                deps: lazyLoad ['/js/app.mgmt.js'], ['/css/app.mgmt.css']
        })
        .state('export', {
            url: '/export/{dashboardName:.*}'
            templateUrl: '/partials/export.html'
            controller: 'ExportController'
            data:
                title: 'Cyclotron | Export'
            resolve:
                session: loadExistingSession
                deps: lazyLoad ['/js/app.mgmt.js'], ['/css/app.mgmt.css']
        })
        .state('edit', {
            abstract: true
            url: '/edit/{dashboardName:.*}'
            templateUrl: '/partials/editor/guiEditor.html'
            controller: 'GuiEditorController'
            data:
                title: 'Cyclotron | Edit'    
            resolve:
                session: loadExistingSession
                deps: lazyLoad ['/js/app.mgmt.js'], ['/css/app.mgmt.css']
        })
        .state('edit.details', {
            url: ''
            templateUrl: '/partials/editor/details.html'
            data:
                title: 'Cyclotron | Edit | Details'
        })
        .state('edit.json', {
            url: ''
            templateUrl: '/partials/editor/jsonEditor.html'
            data:
                title: 'Cyclotron | Edit | JSON'
        })
        .state('edit.dataSources', {
            url: ''
            templateUrl: '/partials/editor/dataSources.html'
            data:
                title: 'Cyclotron | Edit | Data Sources'
        })
        .state('edit.dataSource', {
            url: ''
            templateUrl: '/partials/editor/dataSource.html'
            controller: 'DataSourceEditorController'
            data:
                title: 'Cyclotron | Edit | Data Sources'
        })
        .state('edit.pages', {
            templateUrl: '/partials/editor/pages.html'
            data:
                title: 'Cyclotron | Edit | Pages'
        })
        .state('edit.page', {
            templateUrl: '/partials/editor/page.html'
            controller: 'PageEditorController'
            data:
                title: 'Cyclotron | Edit | Pages'
        })
        .state('edit.widget', {
            templateUrl: '/partials/editor/widget.html'
            data:
                title: 'Cyclotron | Edit | Widget'
        })
        .state('edit.parameters', {
            url: ''
            templateUrl: '/partials/editor/parameters.html'
            data:
                title: 'Cyclotron | Edit | Parameters'
        })
        .state('edit.parameter', {
            url: ''
            templateUrl: '/partials/editor/parameter.html'
            data:
                title: 'Cyclotron | Edit | Parameters'
        })
        .state('edit.scripts', {
            url: ''
            templateUrl: '/partials/editor/scripts.html'
            data:
                title: 'Cyclotron | Edit | Scripts'
        })
        .state('edit.script', {
            url: ''
            templateUrl: '/partials/editor/script.html'
            data:
                title: 'Cyclotron | Edit | Scripts'
        })
        .state('edit.styles', {
            url: ''
            templateUrl: '/partials/editor/styles.html'
            data:
                title: 'Cyclotron | Edit | Styles'
        })
        .state('edit.style', {
            url: ''
            templateUrl: '/partials/editor/style.html'
            data:
                title: 'Cyclotron | Edit | Styles'
        })
        .state('dashboardHistory', {
            url: '/history/{dashboardName:.*}'
            templateUrl: '/partials/dashboardHistory.html'
            controller: 'DashboardHistoryController'
            data:
                title: 'Cyclotron | Dashboard History'
            resolve:
                session: loadExistingSession
                deps: lazyLoad ['/js/app.mgmt.js'], ['/css/app.mgmt.css']
        })
        .state('dashboard', {
            url: '/{dashboard:.+}'
            templateUrl: '/partials/dashboard.html'
            controller: 'DashboardController'
            data:
                title: 'Cyclotron'
                reloadOnSearch: false
            resolve:
                session: loadExistingSessionWithoutAlerts
                deps: lazyLoad ['/js/app.dashboards.js', '/js/app.widgets.js'], ['/css/app.dashboards.css']
        })

    # For any unmatched url, redirect to home
    $urlRouterProvider.otherwise('/')
    $urlRouterProvider.deferIntercept()

    $locationProvider.html5Mode {
        enabled: true
        requireBase: false
    }
    $locationProvider.hashPrefix = '!'

cyclotronApp.run ($rootScope, $urlRouter, $location, $state, $stateParams, $uibModal, analyticsService, configService, userService) ->

    #
    # Authentication-related scope variables
    #
    $rootScope.isLoggedIn = userService.isLoggedIn
    $rootScope.isAdmin = userService.isAdmin
    $rootScope.currentUser = userService.currentUser

    $rootScope.analyticsEnabled = -> configService.analytics?.enable == true

    $rootScope.login = (isModal = false) ->
        options =
            templateUrl: '/partials/login.html'
            controller: 'LoginController'

        if isModal
            options.backdrop = 'static'
            options.keyboard = false

        modalInstance = $uibModal.open options
        modalInstance.result

    $rootScope.logout = userService.logout

    $rootScope.$on 'login', (event) ->
        analyticsService.recordEvent 'login', {  }

    $rootScope.$on 'logout', (event) ->
        analyticsService.recordEvent 'logout', {  }
        
    $rootScope.userTooltip = ->
        return '' unless userService.authEnabled
        'Logged In: ' + userService.currentUser().name

    $rootScope.userGravatar = ->
        return '' unless userService.authEnabled
        'http://www.gravatar.com/avatar/' + userService.currentUser().emailHash + '?r=g&d=mm&s=24'

    # Global Router State Variables
    $rootScope.$state = $state
    $rootScope.$stateParams = $stateParams

    # Set the page title based on the route.
    $rootScope.page_title = 'Cyclotron'
    $rootScope.$on '$stateChangeSuccess', (event, toState, fromState) ->
        if toState?
            $rootScope.$state = toState
            $rootScope.$stateParams = $stateParams
            $rootScope.page_title = toState.data.title

    # Custom urlRouter listener
    $rootScope.$on '$locationChangeSuccess', (event, newUrl, oldUrl) ->
        # Prevent $urlRouter's default handler from firing
        event.preventDefault()

        if $state.current.name != 'dashboard'
            $urlRouter.sync()

    $rootScope.$on '$stateChangeError', (event, toState, toParams, fromState, fromParams, error) ->
        console.log('$stateChangeError', event, toState, toParams, fromState, fromParams, error)

    # Configures $urlRouter's listener after custom listener
    $urlRouter.listen()
