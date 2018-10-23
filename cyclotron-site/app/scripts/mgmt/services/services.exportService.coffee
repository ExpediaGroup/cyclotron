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

cyclotronServices.factory 'exportService', ($http, configService) ->

    {
        # List of all tags
        exportAsync: (dashboardName, format, params, callback) ->
            uri = configService.restServiceUrl + '/export/' + dashboardName + '/' + format
            if params? && _.keys(params).length > 0
                paramStrings = _.map _.pairs(params), (pair) ->
                    pair[0] + '=' + pair[1]
                uri += '?' + paramStrings.join('&')

            $http.post(uri).success (result) ->
                if _.isFunction(callback) then callback(result)

        getStatus: (statusUrl, callback) ->
            $http.get(statusUrl).success (result) ->
                if _.isFunction(callback) then callback(result)
    }
