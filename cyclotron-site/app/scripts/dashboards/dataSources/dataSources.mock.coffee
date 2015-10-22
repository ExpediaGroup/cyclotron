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
# Mock Data Source
# Injected by the DataService as needed
# Supports one property, 'format', that determines whether the mock data 
# should be object-based or row-based.
#
cyclotronDataSources.factory 'mockDataSource', ($rootScope, dataService) ->
    {
        # Called with the actual options, returns the data source object
        initialize: (options) ->
            cache = null
            clients = []
            firstLoad = true

            # Ducati initializations
            gb = 2500
            rn = 70
            grossBookings = -> Math.floor(gb + (Math.random() * 5000 - 2500))
            roomNights = -> Math.floor(rn + (Math.random() * 170 - 70))
            startTime = moment().startOf('minute')
            ducati = (num) ->
                return {
                    id: num
                    _time: moment(startTime).add(num, 'minutes').unix()
                    grossbookingvalue: grossBookings()
                    roomnightcount: roomNights()
                }

            execute = ->

                if !options.format? || options.format == 'object'
                    cache = [ 
                        {color: "red", number: 1, state: "WA", status: "green"}
                        {state: "CA", color: "green", number: 41, status: "green"}
                        {state: "CA", color: "red", number: 2, status: "green"}
                        {color: "red", number: 15, state: "WA", country: "USA", status: "green"}
                        {color: "blue", number: 23, state: "CO", status: "yellow"}
                        {color: "black", number: 45, state: "WA", status: "red"}
                        {color: "green", number: 32, state: "WA", status: "yellow"}
                        {color: "green", number: 99, state: "WA", status: "yellow"}
                        {color: "black", number: 1, state: "WA", status: "red"}
                        {color: "black", number: 45, state: "CA", status: "red"}
                        {color: "white", number: 24, state: "AK", status: "red"}
                        {color: "white", number: 16, state: "AK", status: "yellow"}
                    ]

                else if options.format == 'pie'
                    cache = [ 
                        {browser: "Firefox", percent: 45, isSliced: true},
                        {browser: "IE", percent: 26.8, isSliced: false},
                        {browser: "Chrome", percent: 12.8, isSliced: false},
                        {browser: "Safari", percent: 8.5, isSliced: false},
                        {browser: "Opera", percent: 6.2, isSliced: false},
                        {browser: "Other", percent: 0.7, isSliced: false}
                    ]

                else if options.format == 'ducati'
                    if cache?
                        cache.push ducati(_.last(cache).id + 1)
                        cache = _.tail(cache)
                    else
                        cache = (ducati(num) for num in [0..10])

                if options.filters?
                    # Filter the result set
                    cache = dataService.filter(cache, options.filters)

                if options.sortBy?
                    # Sort the result set
                    cache = dataService.sort(cache, options.sortBy)

                firstLoad = false

            return {
                execute: (toggleSpinners) ->
                    if toggleSpinners? && toggleSpinners == true
                        # Notify each client that it is currently loading
                        _.each clients, (client) ->
                            if client.loadingCallback? && _.isFunction(client.loadingCallback)
                                client.loadingCallback()
                            return

                    $rootScope.$apply ->
                        isUpdate = !firstLoad
                        execute()
                        _.each clients, (client) ->
                            client.callback(cache, null, isUpdate)
                            return

                getData: (dataSourceDefinition, callback, errorCallback, loadingCallback) ->

                    # Abort if the callback is not valid
                    return unless _.isFunction(callback)

                    # Store arguments for future data refreshes
                    clients.push {
                        callback
                        errorCallback
                        loadingCallback
                        dataSourceDefinition
                    }

                    # Check the cache for a previously-retrieved result
                    if cache?
                        # Invoke callback
                        callback(cache, null, false)

                    else if options.deferred == true
                        callback(null)
                        return

                    # Generate the cache if it doesn't exist
                    else if not cache?

                        # Generate cache
                        execute() 
                        
                        # Invoke callback
                        callback(cache, null, false)

                        # Schedule refresh
                        if options.refresh?
                            setInterval(->
                                $rootScope.$apply ->
                                    execute()
                                    _.each clients, (client) -> client.callback(cache, null, true)
                            , options.refresh * 1000)

            }
    }
