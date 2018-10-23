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
# AWS Cloudwatch Data Source
#
# Queries the Amazon Web Service Cloudwatch API.
# Implements a limited but useful subset of functionality and attempts to parse the results into Cyclotron's format.
# For more control, the JSON Data Source should be used directly.
# 
# Always proxies requests through the Cyclotron service.
#
cyclotronDataSources.factory 'cloudwatchDataSource', ($q, $http, configService, dataSourceFactory, logService) ->

    getProxyRequest = (options) ->
        options = _.compile options, {}

        url = new URI options.url

        # Add CloudWatch parameters to URL
        if options.parameters?
            compiledParameters = _.compile(options.parameters, {})
            _.each compiledParameters, (value, key) ->
                switch key
                    when 'Dimensions'
                        index = 0
                        _.each value, (dimValue, dimName) ->
                            index += 1
                            url.addSearch 'Dimensions.member.' + index + '.Name', dimName
                            url.addSearch 'Dimensions.member.' + index + '.Value', dimValue
                    when 'Statistics'
                        if _.isArray(value)
                            _.each value, (statistic, index) ->
                                url.addSearch 'Statistics.member.' + (index + 1), statistic
                    else
                        url.addSearch key, value

        # Format: https://github.com/mikeal/request#requestoptions-callback
        proxyBody =
            url: url.toString()
            method: 'GET'
            json: true
            headers: 
                'Content-Type': 'application/json'

        if options.awsCredentials?
            # Add required properties for AWS request signing
            proxyBody.host = url.hostname()
            proxyBody.path = url.path() + url.search()
            proxyBody.awsCredentials = options.awsCredentials

        return proxyBody

    # Converts CloudWatch responses into Cyclotron format
    processResponse = (response, action, reject) ->
        # Convert the CloudWatch result based on the selected Action
        switch action
            when 'ListMetrics'
                return response.ListMetricsResponse.ListMetricsResult.Metrics;
            when 'GetMetricStatistics'
                return _.sortBy response.GetMetricStatisticsResponse.GetMetricStatisticsResult.Datapoints, 'Timestamp'
            else
                reject('Unknown Action value "' + action + '"')

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
                    data = processResponse result.body, _.jsExec(options.parameters?.Action), reject

                    if _.isNull data
                        logService.debug 'CloudWatch result is null.'
                        data = []

                    resolve {
                        '0':
                            data: data
                            columns: null
                    }
                else
                    error = result.body?.Error?.Code + ': ' + result.body?.Error?.Message
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


    dataSourceFactory.create 'CloudWatch', runner
