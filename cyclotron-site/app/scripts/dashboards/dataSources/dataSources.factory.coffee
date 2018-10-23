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
# Data Source Factory
#
# Implements the standard boilerplate Data Source functionality.
# To be used by other, specific Data Sources.  Data Sources must provide
# 1) Data Source Name
# 2) Runner method which gets data and returns a promise.  
#    The promise must be resolved with either the data results, 
#    or failed with an error message.
#
# Filters, Sorting, Post-Processor, Refreshes, Execute(), etc. are all handled automatically by this factory
#
# Support multiple result sets per Data Source.  Implementations using this factory which do not
# allow multiple result sets should return a result set named '0'.
#
cyclotronDataSources.factory 'dataSourceFactory', ($rootScope, $interval, configService, dataService, analyticsService, logService) ->

    {
        create: (dataSourceType, runner, analyticsDetails) ->

            {
                initialize: (options) ->
                    logService.debug 'Initializing Data Source:', options.name

                    cachedResult = null
                    q = null
                    clients = []
                    firstLoad = true
                    dataVersion = 0

                    # Shared state for each Data Source
                    state = {}
                    
                    # Load Pre-Processor
                    preProcessor = _.jsEval options.preProcessor
                    if !_.isFunction(preProcessor) then preProcessor = null

                    # Load Post-Processor
                    postProcessor = _.jsEval options.postProcessor
                    if !_.isFunction(postProcessor) then postProcessor = null

                    # Load Error Handler
                    errorHandler = _.jsEval options.errorHandler
                    if !_.isFunction(errorHandler) then errorHandler = null

                    broadcastLoading = ->
                        $rootScope.$broadcast('dataSource:' + options.name + ':loading')

                        # Deprecated client callbacks
                        _.each clients, (client) ->
                            if client.loadingCallback? && _.isFunction(client.loadingCallback)
                                client.loadingCallback()
                            return

                    broadcastError = (error) ->
                        $rootScope.$broadcast('dataSource:' + options.name + ':error', { error: error })

                        # Invoke the errorCallback for each client
                        _.each clients, (client) -> 
                            client.errorCallback(error) if _.isFunction(client.errorCallback)

                    broadcastData = ->
                        logService.debug 'Broadcasting Data Source:', options.name

                        # Broadcast results
                        $rootScope.$broadcast('dataSource:' + options.name + ':data', { 
                            data: cachedResult
                            isUpdate: !firstLoad 
                            version: dataVersion
                        })

                        # Deprecated client callbacks
                        _.each clients, (client) ->
                            resultSet = client.dataSourceDefinition.resultSet
                            client.callback(
                                cachedResult?[resultSet]?.data, 
                                cachedResult?[resultSet]?.columns, 
                                !firstLoad)
                            return

                    startRunner = ->
                        logService.info dataSourceType, 'Data Source "' + options.name + '" Started'
                        startTime = performance.now()

                        currentOptions = _.compile options, options
                        if preProcessor?
                            preProcessedResult = preProcessor currentOptions
                            if _.isObject preProcessedResult
                                currentOptions = preProcessedResult

                        sendAnalytics = (success, details = {}) ->
                            endTime = performance.now()

                            # Optionally get Data Source-specific analytics details
                            if _.isFunction(analyticsDetails)
                                details = _.merge details, analyticsDetails(currentOptions)

                            if _.isObject details.errorMessage
                                details.errorMessage = JSON.stringify details.errorMessage

                            analyticsService.recordDataSource currentOptions, success, (endTime - startTime), details

                        # Define failure callback
                        runnerError = (error) ->
                            logService.error dataSourceType, 'Data Source "' + options.name + '" Failed'
                            sendAnalytics false, { errorMessage: error }

                            if errorHandler?
                                # Invoke error handler and if it returns a new string, make that the error message
                                try
                                    newError = errorHandler(error)
                                    if _.isString newError
                                        error = newError
                                catch e
                                    # Error handler throwing an error, make that the error message
                                    error = e

                            cachedResult = null
                            q = null

                            broadcastError error

                        # Define success callback
                        # Expects: result: { resultSetName: { data: [], columns: [] } }
                        runnerSuccess = (result) ->
                            logService.info dataSourceType, 'Data Source "' + currentOptions.name + '" Completed'
                            sendAnalytics true

                            # Save cache
                            cachedResult = result

                            # Process the result sets
                            _.forIn result, (resultSet, resultSetName) ->
                                if !resultSet.columns? then resultSet.columns = null

                                if currentOptions.filters?
                                    # Filter the result set(s)
                                    resultSet.data = dataService.filter resultSet.data, currentOptions.filters

                                if currentOptions.sortBy?
                                    # Sort the result set(s)
                                    resultSet.data = dataService.sort resultSet.data, currentOptions.sortBy

                                # Save updates prior to postProcessor, in case the postProcessor
                                # triggers code that attempts to access the results.
                                cachedResult[resultSetName] = resultSet
                                
                                if postProcessor?
                                    postProcessedResult = postProcessor resultSet.data, resultSetName

                                    # Post-Processor can either update the current dataset,
                                    # or return a new array that replaces it
                                    if _.isArray postProcessedResult
                                        cachedResult[resultSetName].data = postProcessedResult
                                    else
                                        logService.error 'The Post-Processor for "' + currentOptions.name + '" did not return an array; ignoring and using original result.'

                                return 

                            # Increment Data Version
                            dataVersion = dataVersion + 1

                            # Broadcast results
                            broadcastData()

                            firstLoad = false

                        # Start and attach success/fail handlers
                        q = runner(currentOptions, state)
                        q.then runnerSuccess, runnerError

                        return q

                    return {
                        # Initialization method:  called by Widgets to kick-start the Data Source
                        #  - If data has been loaded before, re-broadcasts it
                        #  - Starts executing, unless already loading or deferred
                        #  - Schedules automatic refresh if configured
                        init: (dataSourceDefinition) ->
                            # Set the default result set if not specified
                            dataSourceDefinition.resultSet ?= '0'

                            # Check the cache for a previously-retrieved result
                            if cachedResult?
                                broadcastData()

                            else if options.deferred == true and firstLoad == true
                                return

                            else if !q?
                                # Start executing and return a promise
                                startRunner()

                                # Schedule refresh if needed
                                if options.refresh?
                                    $interval startRunner, options.refresh * 1000

                        # Get the latest resultset for this Data Source.  
                        # Optional resultSet can be provided, otherwise the default is used.
                        # Returns null if the data is not loaded yet.
                        getCachedData: (resultSet) ->
                            resultSet ?= '0'
                            return cachedResult?[resultSet]?.data

                        # Get the most-recent promise, which will be resolved with 
                        # data when it is finished loading.
                        getPromise: -> q

                        execute: (toggleSpinners) ->
                            if toggleSpinners? && toggleSpinners == true
                                broadcastLoading()

                            startRunner()

                        # Deprecated for use by Widgets: replaced by $broadcast
                        getData: (dataSourceDefinition, callback, errorCallback, loadingCallback) ->

                            # Abort if the callback is not valid
                            return unless _.isFunction(callback)

                            # Set the default result set if not specified
                            dataSourceDefinition.resultSet ?= '0'

                            # Store arguments for future data refreshes
                            clients.push { 
                                callback
                                errorCallback
                                loadingCallback
                                dataSourceDefinition
                            }

                            # Check the cache for a previously-retrieved result
                            if cachedResult?
                                # Invoke callback with cached data
                                callback(
                                    cachedResult[dataSourceDefinition.resultSet]?.data, 
                                    cachedResult[dataSourceDefinition.resultSet]?.columns, 
                                    false)

                            else if options.deferred == true and firstLoad == true
                                callback(null)

                            else if !q?
                                # Start executing and return a promise
                                startRunner()

                                # Schedule refresh if needed
                                if options.refresh?
                                    $interval startRunner, options.refresh * 1000


                            # Else, the existing q will invoke all callbacks when it completes.
                            # All subsequent calls will return the cache
                            # Refresh is scheduled once and invokes all callbacks every time it completes

                    }
            }
    }
