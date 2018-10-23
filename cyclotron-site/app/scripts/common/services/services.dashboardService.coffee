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

cyclotronServices.factory 'dashboardService', ($http, $resource, $q, analyticsService, configService, userService) ->

    baseUrl = configService.restServiceUrl.replace(/:(?!\/\/)/gi, '\\:')

    defaultActions =
        get:
            method: 'GET'
        save:
            method: 'POST'
        save2:
            method: 'POST'
            isArray: true
        update:
            method: 'PUT'
        updateArray:
            method: 'PUT'
            isArray: true
        query:
            method: 'GET'
            isArray: true
        remove:
            method: 'DELETE'
        'delete':
            method: 'DELETE'
        'delete2':
            method: 'DELETE'
            isArray: true

    dashboardResource = $resource(baseUrl + '/dashboards/:name', {}, defaultActions)
    revisionsResource = $resource(baseUrl + '/dashboards/:name/revisions', {}, defaultActions)
    revisionResource = $resource(baseUrl + '/dashboards/:name/revisions/:rev', {}, defaultActions)
    tagsResource = $resource(baseUrl + '/dashboards/:name/tags', {}, defaultActions)
    likesResource = $resource(baseUrl + '/dashboards/:name/likes', {}, defaultActions)
    
    beautifyOptions = {
        indent_size: 4
    }

    pageRegex = /\"?pages\"?\s*:/

    newDashboardTemplate = ->
        _.cloneDeep(configService.dashboard.sample)

    newPageTemplate = ->
        _.cloneDeep(configService.page.sample)

    newWidgetTemplate = (widgetName) ->
        return { widget: "" } unless widgetName?
        
        template = _.cloneDeep(configService.widgets[widgetName].sample) || {}
        template.widget = widgetName
        return template

    newDataSourceTemplate = (dataSourceType, index) ->
        template = {
            name: 'datasource_' + index
        }

        template.type = dataSourceType if dataSourceType?

        return template

    newParameterTemplate = ->
        _.cloneDeep(configService.dashboard.properties.parameters.sample)

    newScriptTemplate = ->
        _.cloneDeep(configService.dashboard.properties.scripts.sample)

    newStyleTemplate = ->
        _.cloneDeep(configService.dashboard.properties.styles.sample)


    # Stores the frequency increments for each page.
    frequencyCount = {}

    # Sorted replacement for JSON.stringify..
    # Handles objects, arrays, and values
    # Does not stringify functions
    superStringify = (obj) ->
        if _.isArray(obj)
            # Handle arrays
            inner = _.reduce(obj, (inner, el) ->
                if inner != '' then inner += ','
                inner += superStringify(el)
            , '')

            return '[' + inner + ']'
        
        if _.isObject(obj)
            # Handle Objects
            pairs = _.reject(_.pairs(obj), (p) -> _.isFunction(p[1]))
            sortedPairs = _.sortBy(pairs, (p) -> p[0])

            inner = _.reduce(sortedPairs, (inner, p) ->
                if inner != '' then inner += ','
                inner += '"' + p[0] + '": ' + superStringify(p[1])
            , '')

            return '{' + inner + '}'

        # Stringify values
        return JSON.stringify obj

    ###############
    # Service methods
    ###############

    service = {}

    #
    # Dashboard REST api
    #
    service.dashboards = ->
        dashboardResource

    service.getTrendingDashboards = ->
        analyticsService.getTopDashboards moment().subtract(3, 'days')

    service.getDashboards = (query) ->
        deferred = $q.defer()

        p = dashboardResource.query({ q: query }).$promise

        p.then (dashboards) ->
            deferred.resolve dashboards

        p.catch (error) ->
            alertify.error(error?.data || 'Cannot connect to cyclotron-svc (getDashboards)', 2500)
            deferred.reject error

        return deferred.promise

    service.getDashboard = (dashboardName, rev) ->
        deferred = $q.defer()

        p = (if _.isEmpty(rev)
            dashboardResource.get {
                name: dashboardName
                session: userService.currentSession()?.key
            }
        else
            revisionResource.get {
                name: dashboardName
                rev: rev
                session: userService.currentSession()?.key
            }
        ).$promise

        p.then (dashboard) ->
            deferred.resolve dashboard

        p.catch (error) ->
            deferred.reject error

        return deferred.promise

    service.save = (dashboard) ->
        deferred = $q.defer()

        doSave = ->
            p = dashboardResource.save({ session: userService.currentSession()?.key }, dashboard).$promise

            p.then ->
                analyticsService.recordEvent 'createDashboard', { dashboardName: dashboard.name }
                alertify.log('Created Dashboard', 2500)
                deferred.resolve()

            p.catch (error) ->
                if error.status == 401
                    alertify.error('Session expired, please login again')
                    alertify.error('Cannot create Dashboard')
                    userService.setLoggedOut()
                else 
                    alertify.error(error.data, 2500)
                deferred.reject error

        if userService.hasEditPermission(dashboard)
            doSave()
        else 
            # No permissions for self... confirm
            alertify.confirm ('The Edit Permissions have been modified to exclude yourself.  Are you sure you want to save these changes?'), (e) ->
                if e 
                    doSave()
                else
                    deferred.reject('Cancelled')

        return deferred.promise

    service.update = (dashboard) ->
        deferred = $q.defer()

        doUpdate = ->
            p = dashboardResource.update({
                name: dashboard.name
                session: userService.currentSession()?.key
            }, dashboard).$promise

            p.then ->
                analyticsService.recordEvent 'modifyDashboard', { dashboardName: dashboard.name, rev: dashboard.rev }
                alertify.log 'Saved Dashboard', 2500
                deferred.resolve()

            p.catch (error) ->
                switch error.status
                    when 401
                        alertify.error('Session expired, please login again')
                        alertify.error('Dashboard not saved')
                        userService.setLoggedOut()
                    when 403
                        alertify.error('You don\'t have permission to edit this Dashboard')
                    else 
                        alertify.error(error.data, 2500)
                deferred.reject error

        if userService.hasEditPermission(dashboard)
            doUpdate()
        else 
            # Removing permissions for self...confirm
            alertify.confirm ('The Edit Permissions have been modified to exclude yourself.  Are you sure you want to save these changes?'), (e) ->
                if e 
                    doUpdate()
                else
                    deferred.reject 'Cancelled'

        return deferred.promise

    service.delete = (name) ->
        deferred = $q.defer()

        p = dashboardResource.delete({ 
            name: name
            session: userService.currentSession()?.key
        }).$promise

        p.then (dashboard) ->
            analyticsService.recordEvent 'deleteDashboard', { dashboardName: dashboard.name }
            alertify.log('Deleted Dashboard', 2500)
            deferred.resolve dashboard

        p.catch (error) ->
            switch error.status
                when 401
                    alertify.error('Session expired, please login again')
                    alertify.error('Dashboard not deleted')
                    userService.setLoggedOut()
                when 403
                    alertify.error("You don't have permission to delete this Dashboard")
                else
                    alertify.error(error.data, 2500)
            deferred.reject error

        return deferred.promise

    service.getRevisions = (dashboardName) ->
        deferred = $q.defer()

        p = revisionsResource.query({name: dashboardName}).$promise

        p.then (dashboards) ->
            deferred.resolve dashboards

        p.catch (error) ->
            alertify.error(error?.data || 'Cannot connect to cyclotron-svc (getRevisions)', 2500)
            deferred.reject error

        return deferred.promise

    service.getRevisionDiff = (dashboardName, rev1, rev2) ->
        deferred = $q.defer()

        url = configService.restServiceUrl + '/dashboards/' + dashboardName + '/revisions/' + rev1 + '/diff/' + rev2
        $http.get(url).then (response) ->
            # Returns formatted HTML diff
            deferred.resolve response.data
        .catch (error) ->
            alertify.error(error?.data || 'Cannot connect to cyclotron-svc (getRevisionDiff)', 2500)
            deferred.reject error

        return deferred.promise

    service.getRevision = (dashboardName, rev) ->
        deferred = $q.defer()

        p = revisionResource.get({
            name: dashboardName
            rev: rev
            session: userService.currentSession()?.key 
        }).$promise 

        p.then (revision) ->
            deferred.resolve revision

        p.catch (error) ->
            alertify.error(error?.data || 'Cannot connect to cyclotron-svc (getRevision)', 2500)
            deferred.reject error
            
        return deferred.promise

    service.like = (dashboard) ->
        p = likesResource.save2({ 
            name: dashboard.name
            session: userService.currentSession()?.key
        }, null).$promise

        p.then ->
            analyticsService.recordEvent 'like', { dashboardName: dashboard.name }
            alertify.log('Starred Dashboard', 2500)
            return

        p.catch (error) ->
            switch error.status
                when 401
                    alertify.error('Session expired, please login again')
                    userService.setLoggedOut()
                else
                    alertify.error(error.data, 2500)

    service.unlike = (dashboard) ->
        p = likesResource.delete2({ 
            name: dashboard.name
            session: userService.currentSession()?.key
        }).$promise

        p.then ->
            analyticsService.recordEvent 'unlike', { dashboardName: dashboard.name }
            alertify.log('Unstarred Dashboard', 2500)
            return

        p.catch (error) ->
            switch error.status
                when 401
                    alertify.error('Session expired, please login again')
                    userService.setLoggedOut()
                else
                    alertify.error(error.data, 2500)

    #
    # Push the dashboard to any specified Cyclotron endpoint.
    #
    service.pushToService = (dashboardWrapper, serviceUri, sessionKey) ->
        targetResource = $resource(serviceUri + '/dashboards/:name', { session: sessionKey}, defaultActions)
        targetResource.update({ name: dashboardWrapper.name }, dashboardWrapper).$promise

    #
    # Process all dashboard properties, applying defaults or inheriting 
    # parent values.  Uses a breadth-first iterator to ensure that each
    # level is completely processed before descending to its children.
    #
    service.setDashboardDefaults = (dashboard) ->

        queue = []

        setDefaults = ->
            # Pop from the queue and deconstruct into variables
            [obj, properties, parent] = queue.shift()

            _.each properties, (property, name) ->
                
                if !obj[name]?
                    # Inherit from the parent object
                    if property.inherit == true && parent?
                        obj[name] = parent[name]
                    
                    # Set default value (if there is one)
                    else if property.default?
                        obj[name] = property.default

                # Recursion
                if property.type == 'propertyset'
                    queue.push [obj[name], property.properties, obj]

                else if property.type == 'propertyset[]' || property.type == 'pages' || property.type == 'datasources'
                    _.each obj[name], (o) ->
                        queue.push [o, property.properties, obj]
                        return

                return

        # Set any missing dashboard defaults
        queue.push [dashboard, configService.dashboard.properties, null]

        # Run until finished
        setDefaults() until queue.length == 0

        return dashboard

    service.getThemes = (dashboard) ->
        themes = []
        if dashboard.theme? then themes.push dashboard.theme
        return themes if _.isNullOrUndefined(dashboard.pages)

        _.each dashboard.pages, (page) ->
            themes.push page.theme
            return if _.isNullOrUndefined(page.widgets)
            _.each page.widgets, (widget) ->
                themes.push widget.theme

        return _.unique _.compact themes


    # Convert the text of a dashboard to an object
    service.parse = (dashboardText) ->
        # Remove newlines/carriage returns/tabs
        dashboardText = dashboardText.replace(/\r\n|\n\r|\t\t|\t\t\t/g, ' ')
        dashboardText = dashboardText.replace(/\r|\n|\t/g, ' ')

        # Eval the text to parse it as a JavaScript object 
        eval('(' + dashboardText + ')')

    # Pretty-prints a dashboard (or part of a dashboard) as JSON
    service.toString = (dashboard) ->
        return '' unless dashboard?

        dashboard2 = angular.copy(dashboard)
        js_beautify (superStringify dashboard2), beautifyOptions

    # Create a new dashboard
    service.newDashboard = ->
        newDashboardTemplate()

    # Adds a new page
    service.addPage = (dashboard) ->
        dashboard.pages = [] unless dashboard.pages?
        dashboard.pages.push newPageTemplate()

        return dashboard

    # Removes a page
    service.removePage = (dashboard, pageIndex) ->
        if dashboard.pages? and pageIndex >= 0
            dashboard.pages.splice(pageIndex, 1)

        return dashboard

    # Adds a data source to the dashboard
    service.addDataSource = (dashboard, dataSourceType) ->
        dashboard.dataSources = [] unless dashboard.dataSources?

        # Add the new data source to the array
        dashboard.dataSources.push newDataSourceTemplate dataSourceType, dashboard.dataSources.length

        return dashboard

    # Removes a data source from the dashboard
    service.removeDataSource = (dashboard, dataSourceIndex) ->
        if dashboard.dataSources? and dataSourceIndex >= 0
            dashboard.dataSources.splice(dataSourceIndex, 1)

        return dashboard

    # Adds a parameter to the dashboard
    service.addParameter = (dashboard) ->
        dashboard.parameters = [] unless dashboard.parameters?
        dashboard.parameters.push newParameterTemplate()

        return dashboard

    # Removes a parameter from the dashboard
    service.removeParameter = (dashboard, parameterIndex) ->
        # Remove any matching parameters by object equality
        if dashboard.parameters? and parameterIndex >= 0
            dashboard.parameters.splice(parameterIndex, 1)

        return dashboard

    # Adds a script to the dashboard
    service.addScript = (dashboard) ->
        dashboard.scripts = [] unless dashboard.scripts?
        dashboard.scripts.push newScriptTemplate()

        return dashboard

    # Removes a script from the dashboard
    service.removeScript = (dashboard, index) ->
        if dashboard.scripts? and index >= 0
            dashboard.scripts.splice(index, 1)

        return dashboard

    # Adds a style to the dashboard
    service.addStyle = (dashboard) ->
        dashboard.styles = [] unless dashboard.styles?
        dashboard.styles.push newStyleTemplate()

        return dashboard

    # Removes a style from the dashboard
    service.removeStyle = (dashboard, index) ->
        if dashboard.styles? and index >= 0
            dashboard.styles.splice(index, 1)

        return dashboard

    # Adds a widget to the last page in the dashboard, or a specified pageIndex
    service.addWidget = (dashboard, widgetName, pageIndex) ->

        # Add a page if none exists
        if (not dashboard.pages) || (dashboard.pages.length == 0)
            service.addPage(dashboard)

        page = if pageIndex?
            dashboard.pages[pageIndex]
        else
            _.last(dashboard.pages)

        if not page.widgets then page.widgets = []
        page.widgets.push newWidgetTemplate(widgetName)

        return dashboard

    # Removes a widget from a page in the dashboard
    service.removeWidget = (dashboard, widgetIndex, pageIndex) ->
        if dashboard.pages? and widgetIndex >= 0 and pageIndex >= 0 and pageIndex < dashboard.pages.length
            page = dashboard.pages[pageIndex]
            page.widgets.splice(widgetIndex, 1)

        return dashboard

    #
    # Rotate a dashboard
    # Takes a dashboard and the current index, and 
    # returns the index of the next page
    # This modifies the frequencyCount property of pages in the dashboard,
    # but otherwise does not modify the dashboard object.
    #
    service.rotate = (dashboard, currentPageIndex) ->

        doRotate = ->
            # Increment the page index
            ++currentPageIndex

            # Reset to 0 if end reached
            if currentPageIndex == dashboard.pages.length
                currentPageIndex = 0

            # Get the potential next page
            page = dashboard.pages[currentPageIndex]

            # Increment the frequencyCount of the next page
            if frequencyCount[currentPageIndex]?
                ++frequencyCount[currentPageIndex]
            else 
                frequencyCount[currentPageIndex] = 1

            if frequencyCount[currentPageIndex] > page.frequency 
                frequencyCount[currentPageIndex] = 1

            # Continue rotating if the page frequency hasn't yet been met
            if frequencyCount[currentPageIndex] != page.frequency
                doRotate()

        doRotate()
        return currentPageIndex

    # Gets the data source definition for a widget.  If it does not have a data source
    # or it is not valid, undefined will be returned.  Normally, returns widget.dataSource.
    #
    # Supports dashboard shared data sources: if DataSourceDefinition is a string, 
    # the named Dashboard Data Source with the same name will be returned.
    service.getDataSource = (dashboard, widget, propertyName = 'dataSource') ->

        return if _.isNullOrUndefined(widget)
        return if _.isNullOrUndefined(dashboard)
        return if not widget[propertyName]?

        dataSourceDefinition = widget[propertyName]

        # Retrieve common dataSources if it is a string
        if _.isString(dataSourceDefinition) && dashboard.dataSources?
            # Name format:
            # name[resultName] 
            # resultName and the enclosing brackets are optional
            dataSourceNameParts = /([^\[]*)(\[(.*?)\])?/.exec(dataSourceDefinition)
            dataSourceDefinition = _.find(dashboard.dataSources, { name: dataSourceNameParts[1] })

            if dataSourceNameParts[3]?
                # Clone and set the resultSet
                dataSourceDefinition = _.cloneDeep(dataSourceDefinition)
                dataSourceDefinition.resultSet = dataSourceNameParts[3]

        return if not dataSourceDefinition?
        return if not dataSourceDefinition.type?

        # Return the data source definition
        return dataSourceDefinition

    # Sets the tags for a dashboard
    # Expects an array of tags (strings)
    service.updateTags = (dashboardName, tags) ->
        tagsResource.updateArray({name: dashboardName}, tags)

    service.getPageName = (page, index) ->
        if page?.name?
            pageName = page.name.trim()

        if _.isEmpty(pageName)
            'Page ' + (index + 1)
        else
            pageName

    service.getWidgetName = (widget, index) ->
        if !widget.widget? || widget.widget == ''
            return 'Widget ' + (index + 1)
        if widget?.name?.length > 0
            return _.titleCase(widget.widget) + ': ' + widget.name
        else if widget.title?.length > 0
            return _.titleCase(widget.widget) + ': ' + widget.title
        else
            return  _.titleCase(widget.widget)

    service.getVisitCategory = (dashboard) ->
        return null unless dashboard?
        visits = dashboard.visits
        icon = 'fa-user'
        text = switch
            when visits >= 10000 
                icon = 'fa-users'
                '10,000+'
            when visits >= 1000 then '1,000+'
            when visits >= 100 then '100+'
            when visits >= 10 then '10+'
            else visits

        return {
            number: visits
            text: text
            icon: icon
        }

    return service
