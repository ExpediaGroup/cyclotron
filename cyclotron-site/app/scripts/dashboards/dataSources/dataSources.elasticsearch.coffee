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
# Elasticsearch Data Source
#
# Queries the Elasticsearch API.
# Implements a limited but useful subset of functionality and attempts to parse the results into Cyclotron's format.
# For more control, the JSON Data Source should be used directly.
#
# Always proxies requests through the Cyclotron service.
#
cyclotronDataSources.factory 'elasticsearchDataSource', ($q, $http, configService, dataSourceFactory, logService) ->

    getProxyRequest = (options) ->
        options = _.compile options, {}

        url = new URI options.url
            .segment options.index
            .segment options.method

        # Format: https://github.com/mikeal/request#requestoptions-callback
        proxyBody =
            url: url.toString()
            method: 'POST'
            body: options.request
            headers:
                'Content-Type': 'application/json'

        if options.options?
            compiledOptions = _.compile(options.options, {})
            _.assign(proxyBody, compiledOptions)

        if options.awsCredentials?
            # Add required properties for AWS request signing
            proxyBody.host = url.hostname()
            proxyBody.path = url.path()
            proxyBody.awsCredentials = options.awsCredentials

        return proxyBody

    # Converts Elasticsearch aggregations response to Cyclotron format
    # Supports nested aggregations (but not multiple sibling aggregations)
    processAggregations = (aggs, newBucketTemplate = {}) ->
        key = _.first _.keys aggs
        buckets = _.map aggs[key].buckets, (bucket) ->
            newBucket = _.clone newBucketTemplate
            newBucket[key] = bucket.key
            delete bucket.key

            subBucketKey = null

            # Copy values to newBucket
            _.forOwn bucket, (value, key) ->
                if _.isObject(value) and not _.isArray(value)
                    if value.buckets?
                        # This is a sub-aggregation; store the key for later
                        subBucketKey = key
                    else if value.value?
                        newBucket[key] = value.value
                else
                    newBucket[key] = value

                return true

            # Recursively Handle subBuckets
            if subBucketKey?
                subAggs = {}
                subAggs[subBucketKey] = bucket[subBucketKey]
                subBuckets = processAggregations subAggs, newBucket

                # Return subbuckets instead of current bucket
                return _.flatten subBuckets

            # Return updated bucket
            return newBucket

        # Flatten any subbuckets
        return _.flatten buckets

    processResponse = (response, responseAdapter, reject) ->
        # Auto-detect between hits/aggregations
        if responseAdapter == 'auto'
            if response.aggregations?
                responseAdapter = 'aggregations'
            else
                responseAdapter = 'hits'

        # Convert the Elasticsearch result based on the selected adapter
        switch responseAdapter
            when 'raw'
                return response
            when 'hits'
                return _.map response.hits?.hits, _.flattenObject
            when 'aggregations'
                return processAggregations response.aggregations
            else
                reject('Unknown responseAdapter value "' + responseAdapter + '"')

    runner = (options) ->
        $q (resolve, reject) ->

            # Runner Failure
            errorCallback = (error, status) ->
                if error == '' && status == 0
                    # CORS error
                    error = 'Cross-Origin Resource Sharing error with the server.'

                reject error

            # Successful Result
            successCallback = (result) ->
                if result.statusCode == 200
                    responseAdapter = _.jsExec options.responseAdapter

                    if result.body.responses?
                        # E.g. _msearch responses
                        data = _.map result.body.responses, (response) ->
                            processResponse response, responseAdapter, reject
                        data = _.flatten data
                    else
                        data = processResponse result.body, responseAdapter, reject

                    if _.isNull data
                        logService.debug 'Elasticsearch result is null.'
                        data = []

                    resolve {
                        '0':
                            data: data
                            columns: null
                    }
                else
                    error = result.body?.error
                    if !error? then error = 'Status code: ' + result.statusCode
                    logService.error error
                    reject error


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


    dataSourceFactory.create 'Elasticsearch', runner
