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
# CyclotronData Data Source
#
# Retrieves data from a CyclotronData bucket.  Does not use a proxy. 
#
cyclotronDataSources.factory 'cyclotrondataDataSource', ($q, $http, configService, dataSourceFactory) ->

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
                    data: result.data
                    columns: null

        # Do the request, wiring up success/failure handlers
        key = _.jsExec options.key
        url = (_.jsExec(options.url) || configService.restServiceUrl) + '/data/' + encodeURIComponent(key) + '/data'

        req = $http.get url
        
        # Add callback handlers to promise
        req.then successCallback
        req.error errorCallback

        return q.promise

    dataSourceFactory.create 'CyclotronData', runner
