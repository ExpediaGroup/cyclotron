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
# Graphite Data Source
#
# Queries Graphite API for metrics.  Always proxies requests through the Cyclotron service.
#
cyclotronDataSources.factory 'graphiteDataSource', ($q, $http, configService, dataSourceFactory) ->

    getGraphiteUrl = (url) ->
        # Clean up of Graphite URL.  TODO: More robust support
        graphiteUrl = _.jsExec url
        if graphiteUrl.indexOf('http') != 0 && graphiteUrl.indexOf('!{') != 0
            graphiteUrl = 'http://' + graphiteUrl

        if graphiteUrl.lastIndexOf('/') < graphiteUrl.length - 1
            graphiteUrl += '/'
        graphiteUrl += 'render?format=json&'

        return graphiteUrl

    getProxyRequest = (options) ->
        # Format: https://github.com/mikeal/request#requestoptions-callback
        body =
            method: 'GET'
            json: true
            url: getGraphiteUrl options.url

        if options.from?
            body.url += 'from=' + _.jsExec(options.from) + '&'
        if options.until?
            body.url += 'until=' + _.jsExec(options.until) + '&'

        if options.targets?
            queryParams = _.map options.targets, (target) ->
                'target=' + encodeURIComponent(_.jsExec(target))

            body.url += queryParams.join '&'

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

            return errorCallback 'Error retrieving data from Graphite', -1 unless _.isObject result.body

            data = []
            
            # Translate from Graphite JSON format to Cyclotron format
            if !_.isEmpty result.body
                data = _.map _.head(result.body).datapoints, (datapoint) ->
                    return { _time: datapoint[1] * 1000 }

                _.each result.body, (target) ->
                    _.each target.datapoints, (datapoint, index) ->
                        data[index][target.target] = datapoint[0]

            q.resolve
                '0':
                    data: data
                    columns: null

        # Generate proxy URLs
        proxyUri = new URI(_.jsExec(options.proxy) || configService.restServiceUrl)
            .protocol ''     # Remove protocol to work with either HTTP/HTTPS
            .segment 'proxy' # Append /proxy endpoint
            .toString()

        # Do the request, wiring up success/failure handlers
        req = $http.post proxyUri, getProxyRequest(options)

        # Add callback handlers to promise
        req.success successCallback
        req.error errorCallback

        return q.promise

    dataSourceFactory.create 'Graphite', runner
