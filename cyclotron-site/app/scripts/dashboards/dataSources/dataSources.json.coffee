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
# JSON Data Source
#
# Performs an HTTP action (GET, POST, etc), with various options.  
# 
# All options documented here are available: https://github.com/mikeal/request#requestoptions-callback
#
# Always uses a proxy.
#
# Properties:
#   url: The JSON REST service endpoint
#   postProcessor: A javascript function to be run after data is loaded.  
#                  Can inspect or modify data before it is sent to the Widgets
#
cyclotronDataSources.factory 'jsonDataSource', ($q, $http, configService, dataSourceFactory) ->

    getProxyRequest = (options) ->
        url = new URI(_.jsExec options.url)

        if options.queryParameters?
            # Get and update existing query params (if any)
            queryParams = url.search(true)
            _.forIn options.queryParameters, (value, key) ->
                queryParams[_.jsExec(key)] = _.jsExec value

            url.search queryParams

        # Format: https://github.com/mikeal/request#requestoptions-callback
        body =
            url: url.toString()
            method: options.method || 'GET'
            json: true

        if options.options?
            compiledOptions = _.compile(options.options, {})
            _.assign(body, compiledOptions)

        return body

    runner = (options) ->

        q = $q.defer()

        # Runner Failure
        errorCallback = (error, status) ->
            if error == '' && status == 0
                # CORS error
                error = 'Cross-Origin Resource Sharing error with the server.'

            q.reject error

        # Successful Result
        successCallback = (result) ->

            q.resolve
                '0':
                    data: result.body
                    columns: null

        # Do the request, wiring up success/failure handlers
        proxyUrl = (_.jsExec(options.proxy) || configService.restServiceUrl) + '/proxy'

        req = $http.post proxyUrl, getProxyRequest(options)
        
        # Add callback handlers to promise
        req.success successCallback
        req.error errorCallback

        return q.promise

    dataSourceFactory.create 'JSON', runner
