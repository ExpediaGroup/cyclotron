###
# Copyright (c) 2016-2018 the original author or authors.
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
# Manages Cyclotron.dashboardOverrides
#
cyclotronServices.factory 'dashboardOverridesService', ($localForage, $q, $window, configService, logService) ->
    
    getLocalStorageKey = (dashboard) ->
        'dashboardOverrides.' + dashboard.name

    resetOverrides = ->
        return { pages: [] }

    expandOverrides = (dashboard, dashboardOverrides) ->
        dashboardOverrides.pages ?= []
        _.each dashboard.pages, (page, index) ->
            if !dashboardOverrides.pages[index]?
                dashboardOverrides.pages.push { widgets: [] }
            dashboardOverrides.pages[index].widgets ?= []
            _.each page.widgets, (widget, widgetIndex) ->
                if !dashboardOverrides.pages[index].widgets[widgetIndex]?
                    dashboardOverrides.pages[index].widgets.push {}

        return dashboardOverrides

    return {
        
        # Load Dashboard Overrides for a Dashboard
        # Returns a promise after overrides have been initialized
        initializeDashboardOverrides: (dashboard) ->
            return $q (resolve, reject) ->

                $localForage.getItem(getLocalStorageKey(dashboard)).then (dashboardOverrides) ->
                    if _.isNull dashboardOverrides
                        dashboardOverrides = resetOverrides()
                        
                    # Pad out the overrides with empty pages/widgets
                    dashboardOverrides = expandOverrides dashboard, dashboardOverrides
                    
                    logService.debug 'Dashboard Overrides: ' + JSON.stringify(dashboardOverrides)
                    resolve dashboardOverrides

                .catch (error) ->
                    logService.error 'Error loading Dashboard Overrides:', error
                    reject error

        expandOverrides: (dashboard, dashboardOverrides) ->
            expandOverrides dashboard, dashboardOverrides

        resetAndExpandOverrides: (dashboard) ->
            dashboardOverrides = resetOverrides()
            expandOverrides dashboard, dashboardOverrides

        saveDashboardOverrides: (dashboard, dashboardOverrides) ->
            $localForage.setItem(getLocalStorageKey(dashboard), dashboardOverrides).then ->
                logService.debug 'Saved Dashboard Overrides to localstorage!'
            .catch (error) ->
                logService.error 'Error saving Dashboard Overrides:', error
        
    }
