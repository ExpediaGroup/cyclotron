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
# Gui Editor controller.
#
cyclotronApp.controller 'GuiEditorController', ($scope, $state, $stateParams, $location, $hotkey, $uibModal, $window, configService, userService, dashboardService, tagService, aceService) ->

    # Store some configuration settings for the Editor
    $scope.dashboardProperties = configService.dashboard.properties
    $scope.themes = configService.themes
    $scope.widgets = configService.widgets

    $scope.ldapSearch = {
        editors: {
            results: []
            searchCount: 0
            currentId: 0
        }
        viewers: {
            results: []
            searchCount: 0
            currentId: 0
        }
    }

    $scope.emptyObject = {}

    # Certain properties are handled specially
    $scope.dashboardExcludes = ['name', 'pages', 'dataSources', 'scripts', 'parameters', 'styles']

    # Configuration
    $scope.editor = {
        initialized: false
        isNew: true
        isDirty: false
        hasEditPermission: true
        dashboard: dashboardService.newDashboard()
        dashboardWrapper:
            tags: []
        cleanDashboardWrapper: null
        showRevisions: false
    }

    $scope.isValidDashboardName = ->
        return false if _.isUndefined($scope.editor.dashboard.name)
        /^[A-Za-z0-9-_ ]*$/.test($scope.editor.dashboardName)

    $scope.isLatestRevision = ->
        $scope.editor.latestRevision == $scope.editor.revision

    $scope.canPreview = ->
        !$scope.editor.isNew && !$scope.editor.dashboardWrapper.deleted

    $scope.isDirty = ->
        $scope.editor.isDirty or $scope.editor.latestRevisionDeleted

    $scope.canSave = ->
        # Requires the editor to be initialized, 
        # the user to have permission (or auth to be disabled)
        # and the dashboard must have been modified.
        $scope.editor.initialized and
            $scope.editor.hasEditPermission and
            $scope.isDirty() and
            !$scope.isSaving and
            !$scope.hasDuplicateDataSourceName()

    $scope.canExport = ->
        !$scope.editor.isNew and $scope.isLatestRevision()

    $scope.canDelete = ->
        return false if $scope.editor.isNew or $scope.editor.latestRevisionDeleted
        $scope.editor.hasEditPermission and $scope.isLatestRevision()

    $scope.canPush = ->
        return false unless userService.isLoggedIn()
        return false if $scope.editor.isNew or $scope.editor.isDirty
        return false if $scope.editor.dashboardWrapper.deleted
        return true

    $scope.canEncrypt = ->
        userService.isLoggedIn() && $scope.editor.initialized

    $scope.canClone = ->
        return !$scope.editor.isNew && userService.isLoggedIn()

    $scope.canJsonEdit = ->
        not ($state.current.data.editJson == false)

    $scope.hasDuplicateDataSourceName = ->
        dataSources = $scope.editor.dashboard.dataSources
        return false unless dataSources?

        groups = _.groupBy dataSources, (dataSource) -> dataSource.name?.toLowerCase()

        _.any groups, (values, key) ->
            values.length > 1
    
    $scope.isDuplicateDataSourceName = (dataSource) ->
        name = dataSource.name?.toLowerCase()
        duplicates = _.filter $scope.editor.dashboard.dataSources, (ds) ->
            ds.name?.toLowerCase() == name

        return duplicates.length > 1

    $scope.dashboardUrl = (preview = false) ->
        params = []
        url = '/' + $scope.editor.dashboard.name 
        if preview == true
            params.push 'live=true'
        if !$scope.isLatestRevision()
            params.push 'rev=' + $scope.editor.revision

        # Join params to URL
        if params.length > 0
            url = url + '?' + params.join('&')

        url

    $scope.previewButtonText = ->
        if $scope.isLatestRevision()
            'Preview'
        else
            'Preview Revision #' + $scope.editor.revision

    $scope.getVisitCategory = ->
        dashboardService.getVisitCategory $scope.editor.dashboardWrapper

    # Loads a dashboard into the editor
    $scope.loadDashboard = (dashboardWrapper) ->
        $scope.editor.dashboardWrapper = dashboardWrapper
        $scope.editor.dashboard = dashboardWrapper.dashboard
        $scope.editor.revisionDate = moment(dashboardWrapper.date).format("MM/DD HH:mm:ss")
        $scope.editor.isDirty = false
        $scope.editor.isNew = false
        $scope.editor.hasEditPermission = userService.hasEditPermission(dashboardWrapper)
        $scope.editor.likeCount = dashboardWrapper.likes?.length
        $scope.ldapSearch.editors.results = dashboardWrapper.editors
        $scope.ldapSearch.viewers.results = dashboardWrapper.viewers

    $scope.switchRevision = ->
        # Load the specific revision into the editor
        if $scope.editor.revision == $scope.editor.latestRevision
            $scope.loadDashboard $scope.editor.cleanDashboardWrapper
            $location.search('rev', null)
        else
            q = dashboardService.getRevision $stateParams.dashboardName, $scope.editor.revision
            q.then (dashboardWrapper) ->
                $scope.loadDashboard dashboardWrapper
                $location.search('rev', $scope.editor.revision)

    $scope.combinedDataSourceProperties = (dataSource) ->
        general = _.omit configService.dashboard.properties.dataSources.properties, 'type'

        allDataSources = configService.dashboard.properties.dataSources.options

        if dataSource.type? and allDataSources[dataSource.type]?
            specific = allDataSources[dataSource.type].properties
            return _.defaults specific, general
        else
            return $scope.emptyObject

    $scope.combinedWidgetProperties = (widget) ->
        general = _.omit configService.dashboard.properties.pages.properties.widgets.properties, 'widget'

        if widget.widget? and widget.widget.length > 0
            specific = configService.widgets[widget.widget].properties
            return _.defaults specific, general
        else
            return $scope.emptyObject

    $scope.getDataSourceName = (item, index) ->
        if item.name?.length > 0
            return _.titleCase(item.type) + ': ' + item.name
        else
            return 'Data Source ' + index

    $scope.getPageName = dashboardService.getPageName

    $scope.getWidgetName = dashboardService.getWidgetName

    $scope.getParameterName = (item, index) ->
        if item.name?.length > 0
            return item.name
        else 
            return 'Parameter ' + (index + 1)

    $scope.getScriptOrStyleName = (item, index, label) ->
        if item.name?.length > 0
            return item.name
        if item.path?
            name = _.last item.path.split('/')
            if name.length == 0 then name = item.path
        else if item.text?.length > 0
            name = item.text.substring(0, 32)
            if item.text.length > 32 then name += '...'
        else 
            name = label + ' ' + (index + 1)

        return name

    $scope.selectWidget = ->
        sample = _.cloneDeep $scope.widgets[$scope.editor.selectedItem.widget].sample
        if sample?
            if _.isFunction sample
                # Execute the function to get a new sample Widget
                $scope.editor.selectedItem = _.defaults $scope.editor.selectedItem, sample()
            else
                $scope.editor.selectedItem = _.defaults $scope.editor.selectedItem, sample

    $scope.goToSubState = (state, item, index) ->
        $scope.editor.currentEditor = state
        $scope.editor.selectedItem = item
        $scope.editor.selectedItemIndex = index

        if state == 'edit.page'
            $scope.editor.selectedPageIndex = index

        $state.go(state)

    $scope.returnFromJsonEditor = ->
        $state.go($scope.editor.currentEditor)

    $scope.moveRevisionLeft = ->
        return if $scope.editor.revision == 1
        $scope.editor.revision--
        $scope.switchRevision()

    $scope.moveRevisionRight = ->
        return if $scope.editor.revision == $scope.editor.latestRevision
        $scope.editor.revision++
        $scope.switchRevision()

    $scope.searchLdap = (query, type) ->
        return unless query.length > 2
        currentSearchId = ++$scope.ldapSearch[type].searchCount

        userService.search(query).then (results) ->
            # Ignore results if a more-recent search is already displayed
            return if currentSearchId < $scope.ldapSearch[type].currentId

            results = _.map results, (result) ->  {
                displayName: result.displayName
                category: result.category
                dn: result.dn
                sAMAccountName: result.sAMAccountName
                mail: result.mail
            }

            # Combine users stored in the editors/viewers list with the results
            # Related: https://github.com/angular-ui/ui-select/issues/192
            _.each $scope.editor.dashboardWrapper[type], (selectedEditorOrViewer) ->
                _.remove results, (result) -> result.dn == selectedEditorOrViewer.dn
                results.push selectedEditorOrViewer

            $scope.ldapSearch[type].results = results
            $scope.ldapSearch[type].currentId = currentSearchId

    #
    # Dashboard operations 
    #

    $scope.clone = ->
        return unless $scope.canClone()

        $scope.editor.isNew = true
        $scope.editor.isDirty = true
        $scope.editor.hasEditPermission = true
        $scope.editor.dashboard.description = 'Cloned from ' + $scope.editor.dashboard.name + ', revision ' + $scope.editor.dashboardWrapper.rev
        $scope.editor.dashboardWrapper.deleted = false
        $scope.editor.dashboardWrapper.rev = 1
        $scope.editor.dashboard.name += ' CLONE'
        alertify.log("Cloned Dashboard", 2500)


    $scope.push = ->
        return unless $scope.canPush()

        modalInstance = $uibModal.open {
            templateUrl: '/partials/editor/pushDashboard.html'
            scope: $scope
            controller: 'PushDashboardController'
        }

    $scope.encrypt = ->
        return unless $scope.canEncrypt()

        modalInstance = $uibModal.open {
            templateUrl: '/partials/editor/encryptString.html'
            scope: $scope
            controller: 'EncryptStringController'
        }

    $scope.delete = ->
        return unless $scope.canDelete()

        # Confirmation dialog
        modalInstance = $uibModal.open {
            templateUrl: '/partials/editor/delete.html'
            controller: 'DeleteDashboardController'
            resolve: {
                dashboardName: -> $scope.editor.dashboardWrapper.name
            }
        }

        modalInstance.result.then ->
            q = dashboardService.delete($scope.editor.dashboardWrapper.name)
            q.then (dashboardWrapper) ->
                $scope.editor.dashboardWrapper = dashboardWrapper
                $scope.editor.cleanDashboardWrapper = _.cloneDeep dashboardWrapper
                $scope.editor.latestRevision = dashboardWrapper.rev
                $scope.editor.latestRevisionDeleted = true
                $scope.editor.isDirty = true

    $scope.save = ->
        # Ensure Dashboard has been modified
        return unless $scope.isDirty()
            
        if not $scope.isLoggedIn()
            # Login then attempt to save again
            $scope.login(true).then ->
                $scope.editor.hasEditPermission = userService.hasEditPermission $scope.editor.dashboardWrapper
                $scope.save()
        else if $scope.canSave()
            $scope.isSaving = true
            try 
                # Create or Update the Dashboard, then reload
                if ($scope.editor.isNew)

                    if !$scope.editor.dashboard.name? or $scope.editor.dashboard.name == ''
                        alertify.error('Dashboard Name property is missing', 10000)
                        $scope.isSaving = false
                        return 

                    dashboardName = _.slugify($scope.editor.dashboard.name)
                    $scope.editor.dashboard.name = dashboardName
                    $scope.editor.dashboardWrapper.name = dashboardName
                    $scope.editor.dashboardWrapper.dashboard = $scope.editor.dashboard

                    dashboardService.save($scope.editor.dashboardWrapper).then ->
                        $state.go('edit.details', { dashboardName: dashboardName})
                        $scope.editor.isNew = false
                        $scope.editor.hasEditPermission = userService.hasEditPermission $scope.editor.dashboardWrapper
                    .catch (e) ->
                        $scope.isSaving = false

                else
                    dashboardToSave = _.cloneDeep $scope.editor.dashboardWrapper
                    dashboardService.update(dashboardToSave).then ->
                        $scope.editor.latestRevision = $scope.editor.revision = ++dashboardToSave.rev
                        $scope.editor.latestRevisionDeleted = false
                        
                        $scope.editor.dashboardWrapper.rev = $scope.editor.latestRevision
                        $scope.editor.dashboardWrapper.deleted = false
                        $scope.editor.dashboardWrapper.lastUpdatedBy = userService.currentUser()
                        $scope.editor.cleanDashboardWrapper = dashboardToSave
                        $scope.editor.cleanDashboardWrapper.rev = $scope.editor.latestRevision
                        $scope.editor.cleanDashboardWrapper.deleted = false
                        $scope.editor.cleanDashboardWrapper.lastUpdatedBy = userService.currentUser()

                        $scope.editor.hasEditPermission = userService.hasEditPermission $scope.editor.dashboardWrapper
                        $scope.editor.isDirty = false
                        $scope.isSaving = false
                        $location.search('rev', null)
                    .catch (e) ->
                        $scope.isSaving = false        
               
            catch e
                $scope.isSaving = false

                # Possibly a javascript parsing error on the eval
                alertify.error(e.toString(), 10000)

    $scope.newPage = ->
        dashboardService.addPage $scope.editor.dashboard

    $scope.removePage = (index) ->
        dashboardService.removePage $scope.editor.dashboard, index

    $scope.removeWidget = (index) ->
        dashboardService.removeWidget $scope.editor.dashboard, index, $scope.editor.selectedPageIndex

    $scope.newDataSource = (dataSourceName) ->
        dashboardService.addDataSource $scope.editor.dashboard, dataSourceName

    $scope.removeDataSource = (index) ->
        dashboardService.removeDataSource $scope.editor.dashboard, index

    $scope.newParameter = ->
        dashboardService.addParameter $scope.editor.dashboard

    $scope.removeParameter = (index) ->
        dashboardService.removeParameter $scope.editor.dashboard, index

    $scope.newScript = ->
        dashboardService.addScript $scope.editor.dashboard

    $scope.removeScript = (index) ->
        dashboardService.removeScript $scope.editor.dashboard, index

    $scope.newStyle = ->
        dashboardService.addStyle $scope.editor.dashboard

    $scope.removeStyle = (index) ->
        dashboardService.removeStyle $scope.editor.dashboard, index

    #
    # Initialization
    #

    initialize = ->
        if _.isEmpty $stateParams.dashboardName
            $scope.goToSubState('edit.details', $scope.editor.dashboard, 0)
            $scope.editor.initialized = true
        else 
            # Get the latest revision
            q = dashboardService.getDashboard($stateParams.dashboardName)
            q.then (dashboardWrapper) ->
                $scope.editor.latestRevision = dashboardWrapper.rev
                $scope.editor.latestRevisionDeleted = dashboardWrapper.deleted
                $scope.editor.cleanDashboardWrapper = _.cloneDeep dashboardWrapper

                if $location.search().rev?
                    $scope.editor.revision = $location.search().rev
                    $scope.editor.showRevisions = true
                    $scope.switchRevision()
                else
                    # Load the latest revision into the editor
                    $scope.loadDashboard dashboardWrapper
                    $scope.editor.revision = dashboardWrapper.rev

                $scope.editor.initialized = true

            q.catch (error) ->
                $scope.editor.isDirty = false
                switch error.status
                    when 401
                        $scope.login(true).then ->
                            initialize()
                    when 403
                        $scope.dashboardEditors = error.data.data.editors
                        $scope.dashboardName = $stateParams.dashboardName

                        modalInstance = $uibModal.open {
                            templateUrl: '/partials/viewPermissionDenied.html'
                            scope: $scope
                            controller: 'GenericErrorModalController'
                            backdrop: 'static'
                            keyboard: false
                        }

    initialize()

    $scope.$watch 'editor.dashboardWrapper', (modified) ->
        return unless modified?
        $scope.editor.isDirty = !angular.equals($scope.editor.cleanDashboardWrapper, modified)
    , true

    $scope.$watch 'isLoggedIn()', ->
        $scope.editor.hasEditPermission = userService.hasEditPermission($scope.editor?.dashboardWrapper)

    # Load default tag autocomplete
    tagService.getTags (tags) ->
        $scope.allTags = tags

    $('.tagEditor').on "change", (e) -> $scope.editor.isDirty = true

    # Ensure ?rev is persisted across state changes
    $scope.$on '$stateChangeSuccess', ->
        return unless $scope.editor.revision?
        if $scope.editor.revision == $scope.editor.latestRevision
            $location.search('rev', null)
        else
            $location.search('rev', $scope.editor.revision)

    # Hotkeys
    saveHandler = (event) ->
        event.preventDefault()
        $scope.save()
    $hotkey.bind 'Command + S', saveHandler
    $hotkey.bind 'Ctrl + S', saveHandler


    # Prevent leaving the page dirty
    $scope.$on '$stateChangeStart', (event, toState) ->
        return if !$scope.editor.isDirty || toState.name.substring(0, 5) == 'edit.'
        answer = confirm('You have unsaved changes, are you sure you want to leave.')
        if !answer then event.preventDefault()

    $window.onbeforeunload = ->
        if $scope.editor.isDirty
            return 'You have unsaved changes, are you sure you want to leave.'

    $scope.$on '$destroy', ->
        $window.onbeforeunload = undefined

    return
