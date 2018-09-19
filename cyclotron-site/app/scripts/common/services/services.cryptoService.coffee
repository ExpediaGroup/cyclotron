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

cyclotronServices.factory 'cryptoService', ($http, $q, configService) ->

    {
        # Encrypt a string and return the encrypted form
        encrypt: (value) ->
            deferred = $q.defer()

            q = $http.post(configService.restServiceUrl + '/crypto/encrypt', { value: value })
            q.success (result) ->
                deferred.resolve('!{' + result + '}')

            q.error (error) ->
                alertify.error 'Cannot connect to cyclotron-svc (encrypt)', 2500
                deferred.reject(error)

            deferred.promise
    }
