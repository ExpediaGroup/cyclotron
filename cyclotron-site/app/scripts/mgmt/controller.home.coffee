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
# Home controller - Home page containing the Dashoard list and editor
#
cyclotronApp.controller 'HomeController', ($scope, $location, $modal, configService, dashboardService, tagService, userService) ->

    #
    # Scope Variables
    #

    $scope.cyclotronVersion = configService.version
    $scope.changelogLink ?= configService.changelogLink

    $scope.showSplash = true
    $scope.loading = false

    $scope.search = 
        allTags: []
        hints: []
        query: []

    $scope.isTag = (hint) -> 
        _.contains $scope.search.allTags, hint

    $scope.selectTag = (tag) ->
        # Only used when selecting tags from the Search Results
        $scope.search.query = _.union($scope.search.query, [tag])

    # Load search autocomplete
    $scope.getSearchHints = ->
        tagService.getSearchHints (searchHints) ->
            $scope.search.hints = searchHints

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
        $scope.loading = true

        p = dashboardService.getDashboards $scope.search.query.join(',')
        p.then (dashboards) ->
            $scope.dashboards = dashboards
            $scope.updateDashboardVisits()
            $scope.updateDashboardPermissions()
            $scope.loading = false

        p.catch (response) ->
            if response.status == 500
                $modal.open {
                    templateUrl: '/partials/500.html'
                    scope: $scope
                    controller: 'GenericErrorModalController'
                    backdrop: 'static'
                    keyboard: false
                }

    $scope.updateDashboardVisits = ->
        _.each $scope.dashboards, (dashboard) ->
            dashboard.visitCategory = dashboardService.getVisitCategory dashboard
            return

    $scope.updateDashboardPermissions = ->
        _.each $scope.dashboards, (dashboard) ->
            dashboard._canEdit = userService.hasEditPermission dashboard
            dashboard._canView = userService.hasViewPermission dashboard
            return

    $scope.delete = (dashboardName) ->
        # Confirmation dialog
        modalInstance = $modal.open {
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
            _.uniq q.split(',')

    #
    # Initialization
    #

    # Parse query params / default to none
    q = $location.search()?.q
    if q? and q.length > 0
        $scope.loadQueryString(q)
        $scope.loadDashboards()

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
    $scope.$watch 'isLoggedIn()', $scope.updateDashboardPermissions

    # Update search.query after using the back/forward buttons
    $scope.$watch (-> $location.search()), (newSearch, oldSearch) ->
        return if _.isEqual newSearch.q, oldSearch,q
        $scope.loadQueryString(newSearch.q)
