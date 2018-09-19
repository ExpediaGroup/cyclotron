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

cyclotronServices.factory 'downloadService', ($http, $q, $localForage, $window, analyticsService, configService, logService) ->

    exports = {

        download: (name, format, data) ->
            # Post data to /export/data endpoint, get back a URL to the file
            # Then download the file
            $http.post(configService.restServiceUrl + '/export/data', { name, format, data })
            .then (result) ->
                $window.location = result.data.url
                alertify.log('Downloaded Widget Data', 2500)
            .catch (error) ->
                alertify.error 'Error downloading Widget data', 2500

    }

    return exports
