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
# Splunk Data Source
#
# Runs a Splunk job. Always proxies requests through the Cyclotron service.
#
# Properties:
#   url: The REST service endpoint
#   query: The Splunk query to execute
#
# Notes:
#   Splunk can return preview results for some queries.  When this happens, the 
#   response is not valid JSON.  This Data Source fixes the response, parses it into a
#   JSON array, and selects the final result.  All the preview results are ignored.
#
cyclotronDataSources.factory 'splunkDataSource', ($q, $http, configService, dataSourceFactory, logService) ->

    getSplunkUrl = (options) ->
        # Using 'json_rows' mode since 'json' is not actually valid JSON
        searchOptions =
            search: 'search ' + _.jsExec options.query
            output_mode: 'json_rows'

        if options.earliest? then searchOptions.earliest_time = _.jsExec options.earliest
        if options.latest? then searchOptions.latest_time = _.jsExec options.latest

        uri = URI(_.compile(options.url, options))
            .search searchOptions
            .toString()

        return uri

    getProxyRequest = (options) ->
        # Format: https://github.com/mikeal/request#requestoptions-callback
        {
            method: 'GET'
            json: false
            url: getSplunkUrl options
            strictSSL: false
            auth:
                username: _.jsExec options.username
                password: _.jsExec options.password
        }

    runner = (options) ->

        q = $q.defer()

        # Runner Failure
        errorCallback = (error, status) ->
            if error == '' && status == 0
                # CORS error
                error = 'Cross-Origin Resource Sharing error with the server.'

            q.reject error

        # Successful Result
        successCallback = (proxyResult) ->

            data = []
            fields = null
            
            # Fix malformed JSON and parse into an array
            try
                body = '[' + proxyResult.body.replace(/}{/g, '},{') + ']'
                results = JSON.parse body

                # Select the final result (non-preview)
                splunkResult = _.find(results, { preview: false }) || _.first(results)
            catch e
                logService.error 'Unexpected response from Splunk: ' + proxyResult.body
                splunkResult = null

            if !_.isEmpty results

                return errorCallback 'Error retrieving data from Splunk', -1 unless _.isObject splunkResult

                errorMessages = _(splunkResult.messages)
                    .filter (message) -> message.type == 'ERROR' or message.type == 'FATAL'
                    .pluck 'text'
                    .value()

                if !_.isEmpty errorMessages
                    return errorCallback 'Splunk Error: ' + errorMessages.join(', '), -1 

                # Translate from Splunk JSON_rows format to Cyclotron format
                if !_.isEmpty(splunkResult)
                    fields = splunkResult.fields
                    data = _.map splunkResult.rows, (row) -> 
                        _.zipObject fields, row

            # Return the data
            q.resolve
                '0':
                    data: data
                    columns: fields

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

    dataSourceFactory.create 'Splunk', runner
