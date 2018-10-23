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
# Prometheus Data Source
#
# Queries Prometheus API for metrics.  Always proxies requests through the Cyclotron service.
#
cyclotronDataSources.factory 'prometheusDataSource', ($q, $http, configService, dataSourceFactory) ->

    getPrometheusUrl = (url) ->
        # Clean up of Prometheus URL.  TODO: More robust support
        prometheusUrl = _.jsExec url
        if prometheusUrl.indexOf('http') != 0 && prometheusUrl.indexOf('!{') != 0
            prometheusUrl = 'http://' + prometheusUrl

        if prometheusUrl.lastIndexOf('/') < prometheusUrl.length - 1
            prometheusUrl += '/'
        prometheusUrl += 'api/v1/query_range?'

        return prometheusUrl

    getDate = (date) ->
        if moment.isMoment(date) 
            return date.toISOString()
        else
            return _.jsExec(date)

    getProxyRequest = (options) ->
        # Format: https://github.com/mikeal/request#requestoptions-callback
        body =
            method: 'GET'
            json: true
            url: getPrometheusUrl options.url

        start = getDate(options.start || moment().subtract(24, 'hours').startOf('second'))
        end = getDate(options.end || moment().endOf('second'))
        step = options.step || '1m'

        body.url += 'query=' + _.jsExec(options.query) + '&'
        body.url += 'start=' + start + '&'
        body.url += 'end=' + end + '&'
        body.url += 'step=' + _.jsExec(step)

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

            return errorCallback 'Error retrieving data from Prometheus', -1 unless _.isObject result.body

            data = []
            
            # Translate from Prometheus JSON format to Cyclotron format
            if !_.isEmpty result.body
                if result.body.status == 'error'
                    return errorCallback('Prometheus error: ' + result.body.error, 0)
                else if result.body.status != 'success'
                    return errorCallback 'Prometheus query failed', 0
                
                metrics = result.body.data.result

                data = _.reduce metrics, (data, metric) ->
                    rowTemplate = _.omit metric.metric, ['__name__']
                    metricName = metric.metric.__name__

                    _.each metric.values, (valueSet) ->
                        row = _.assign { 
                            time: valueSet[0] * 1000,
                        }, rowTemplate

                        row[metricName] = parseFloat(valueSet[1])

                        data.push row

                    return data
                , []
                
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

    dataSourceFactory.create 'Prometheus', runner
