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
# Home controller - Home page containing the Dashoard list and editor
#
cyclotronApp.controller 'HomeController', ($scope, $location, $uibModal, configService, dashboardService, tagService, userService) ->

    #
    # Scope Variables
    #

    $scope.cyclotronVersion = configService.version
    $scope.changelogLink ?= configService.changelogLink

    $scope.showSplash = true
    $scope.loading = false
    $scope.mode = 'home'

    $scope.sortByField = 'name'
    $scope.sortByReverse = false

    $scope.search = 
        allTags: []
        allHints: []
        hints: []
        query: []

    $scope.currentPage = 1
    $scope.itemsPerPage = 25

    $scope.userDashboards = []
    $scope.userLikedDashboards = []
    $scope.userRecentDashboards = []
    $scope.trendingDashboards = []

    $scope.smallLimit = 10
    $scope.largeLimit = 30

    $scope.userDashboardsLimit = $scope.smallLimit
    $scope.trendingDashboardsLimit = $scope.smallLimit

    $scope.toggleLimit = (limit) ->
        if $scope[limit] == $scope.smallLimit
            $scope[limit] = $scope.largeLimit
        else
            $scope[limit] = $scope.smallLimit

    $scope.isTag = (hint) -> 
        _.contains $scope.search.allTags, hint

    $scope.isAdvanced = (hint) ->
        _.contains $scope.search.advanced, hint

    $scope.selectTag = (tag) ->
        # Only used when selecting tags from the Search Results
        $scope.search.query = _.union($scope.search.query, [tag])

    # Load search autocomplete
    $scope.getSearchHints = ->
        tagService.getSearchHints (searchHints) ->
            $scope.search.allHints = searchHints
            $scope.getAdvancedSearchHints()

    $scope.getAdvancedSearchHints = ->
        $scope.search.advanced = _.sortBy ['is:deleted', 'is:starred', 'include:deleted']

        if userService.authEnabled and userService.isLoggedIn()
            username = userService.currentUser().sAMAccountName
            $scope.search.advanced.push 'starredby:' + username
            $scope.search.advanced.push 'lastupdatedby:' + username
            $scope.search.advanced.push 'createdby:' + username

        $scope.search.hints = $scope.search.advanced.concat $scope.search.allHints

    $scope.canEdit = (dashboard) -> 
        return true unless $scope.isLoggedIn()
        if dashboard? then dashboard._canView else true

    $scope.canDelete = (dashboard) -> 
        return false unless $scope.isLoggedIn() 
        if dashboard? then dashboard._canEdit else true

    $scope.loginAlert = ->
        alertify.error('Please login to enable', 2500)

    $scope.loadDashboards = ->
        $scope.dashboards = null
        return unless $scope.search.query.length > 0

        $scope.showSplash = false
        $scope.mode = 'home'
        $scope.loading = true

        p = dashboardService.getDashboards $scope.search.query.join(',')
        p.then (dashboards) ->
            $scope.dashboards = $scope.augmentDashboards dashboards
            $scope.resultsCount = $scope.dashboards.length
            $scope.loading = false

        p.catch (response) ->
            if response.status == 500
                $uibModal.open {
                    templateUrl: '/partials/500.html'
                    scope: $scope
                    controller: 'GenericErrorModalController'
                    backdrop: 'static'
                    keyboard: false
                }

    $scope.augmentDashboards = (dashboards) ->
        _.each dashboards, (dashboard) ->
            # Update permissions based on current user
            dashboard._canEdit = userService.hasEditPermission dashboard
            dashboard._canView = userService.hasViewPermission dashboard

            # Update Liked status and total count
            dashboard._liked = userService.likesDashboard dashboard
            dashboard.likeCount = dashboard.likes.length

            # Assign a category based on number of visits
            dashboard.visitCategory = dashboardService.getVisitCategory dashboard
            
            return

        return dashboards

    $scope.getUserDashboards = ->
        p = dashboardService.getDashboards('ownedby:' + userService.cachedUsername)
        p.then (dashboards) ->
            $scope.userDashboards = $scope.augmentDashboards dashboards
        p.catch (response) ->
            $scope.userDashboards = []

        q = dashboardService.getDashboards('starredby:' + userService.cachedUsername)
        q.then (dashboards) ->
            $scope.userLikedDashboards = $scope.augmentDashboards dashboards
        q.catch (response) ->
            $scope.userLikedDashboards = []
    
    $scope.getTrendingDashboards = ->
        p = dashboardService.getTrendingDashboards()
        p.then (dashboards) ->
            $scope.trendingDashboards = $scope.augmentDashboards dashboards
        p.catch (response) ->
            $scope.trendingDashboards = []

    toggleLikeHelper = (dashboard) ->
        if dashboard._liked
            dashboardService.unlike(dashboard).then ->
                dashboard._liked = false
                dashboard.likeCount--
        else
            dashboardService.like(dashboard).then ->
                dashboard._liked = true
                dashboard.likeCount++

    $scope.toggleLike = (dashboard) ->
        if userService.authEnabled and !userService.isLoggedIn()
            $scope.login(true).then ->
                toggleLikeHelper(dashboard)
        else
            toggleLikeHelper(dashboard)

    $scope.delete = (dashboardName) ->
        # Confirmation dialog
        modalInstance = $uibModal.open {
            templateUrl: '/partials/editor/delete.html'
            controller: 'DeleteDashboardController'
            resolve: {
                dashboardName: -> dashboardName
            }
        }

        modalInstance.result.then ->
            q = dashboardService.delete(dashboardName)
            q.then ->
                _.remove $scope.dashboards, { name: dashboardName }

                tagIndex = $scope.searchOptions.tags.indexOf(dashboardName)
                if (tagIndex > -1)
                    $scope.searchOptions.tags.splice(tagIndex, 1);

    $scope.loadQueryString = (q) ->
        $scope.search.query = if _.isEmpty q 
            [] 
        else 
            _.uniq q.split ','

    $scope.tagSorter = (dashboard) ->
        if _.isEmpty dashboard.tags
            '~'
        else
            dashboard.tags.join '.'

    $scope.sortBy = (field, descending) ->
        if $scope.sortByField == field
            $scope.sortByReverse = !$scope.sortByReverse
        else
            $scope.sortByField = field
            $scope.sortByReverse = descending

        if $scope.sortByReverse == true
            field = '-' + field
        $location.search 's', field

    $scope.setPageSize = (size) ->
        $scope.itemsPerPage = size

    #
    # Initialization
    #

    # Parse query params / default to none
    q = $location.search()?.q
    if q? and q.length > 0
        $scope.loadQueryString(q)
        $scope.loadDashboards()

    # Parse sort by
    s = $location.search()?.s
    if s? and s.length > 0
        if s.indexOf('-') == 0
            $scope.sortByReverse = true
            s = s.substr 1
        else
            $scope.sortByReverse = false

        $scope.sortByField = s
        
    # Load all tags
    tagService.getTags (tags) ->
        $scope.search.allTags = tags

        # Reload the query search after loading tags
        # This will enable tag icons in search terms (if they are tags)
        if q? and q.length > 0
            $scope.loadQueryString(q)

        # Watch for Search changes
        $scope.$watch 'search.query', (query, oldQuery) ->
            return unless _.isArray query
            return if _.isEqual(query, oldQuery)
            
            if _.isEmpty query
                $location.search 'q', null
                $scope.showSplash = true
            else 
                $location.search 'q', query.join(',')

            $scope.loadDashboards()

    # Load search hints
    $scope.getSearchHints()

    # Update displayed permissions after logging in/out
    $scope.$watch 'isLoggedIn()', ->
        $scope.augmentDashboards $scope.dashboards
        $scope.getAdvancedSearchHints()
        $scope.getUserDashboards()
        $scope.getTrendingDashboards()

    # Update search.query after using the back/forward buttons
    $scope.$watch (-> $location.search()), (newSearch, oldSearch) ->
        return if _.isEqual newSearch.q, oldSearch,q
        $scope.loadQueryString(newSearch.q)
