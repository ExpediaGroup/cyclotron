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
# InfluxDB Data Source
#
# Queries InfluxDB API for metrics.  Always proxies requests through the Cyclotron service.
#
cyclotronDataSources.factory 'influxdbDataSource', ($q, $http, configService, dataSourceFactory) ->

    getInfluxUrl = (options) ->

        # Clean up of Influx API URL
        influxUrl = _.jsExec options.url

        # Uses HTTP by default.. if HTTPS is enabled on the server, it needs to be
        # manually specified
        if influxUrl.indexOf('http') != 0
            influxUrl = 'http://' + influxUrl

        influxUrl = new URI(influxUrl)

        # Ensure default port
        if influxUrl.port() == ''
            influxUrl = influxUrl.port('8086')

        # Ensure default path
        if influxUrl.pathname() == '' or influxUrl.pathname() == '/'
            influxUrl = influxUrl.pathname '/query'

        # Query / Database params
        params = {
            db: _.jsExec options.database
            q: _.jsExec options.query
            epoch: _.jsExec options.precision
        }

        if options.username? then params.u = _.jsExec options.username
        if options.password? then params.p = _.jsExec options.password

        influxUrl.search params

        return influxUrl.toString()

    getProxyRequest = (options) ->
        # Format: https://github.com/mikeal/request#requestoptions-callback
        proxyBody =
            method: 'GET'
            json: true
            url: getInfluxUrl options

        if options.options?
            compiledOptions = _.compile(options.options, {})
            _.assign(proxyBody, compiledOptions)

        if options.insecureSsl?
            proxyBody.strictSSL = !options.insecureSsl

        return proxyBody

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

            return errorCallback 'Error retrieving data from InfluxDB', -1 unless _.isObject result.body

            if result.statusCode != 200
                return errorCallback result.body.error, result.statusCode

            data = []

            # Translate from InfluxDB JSON format to Cyclotron format
            if !_.isEmpty result.body?.results
                if result.body.results.length > 1
                    return errorCallback 'Multiple InfluxDB queries are not supported', 0

                influxResult = result.body.results[0]

                if influxResult.error?
                    return errorCallback influxResult.error, 0

                _.each influxResult.series, (series) ->
                    seriesData = _.map series.values, (values) ->
                        row = _.zipObject series.columns, values
                        row = _.merge row, series.tags

                    data = data.concat(seriesData)

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

    dataSourceFactory.create 'InfluxDB', runner
