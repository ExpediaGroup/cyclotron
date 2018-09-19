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

cyclotronServices.factory 'tagService', ($http, configService) ->

    {
        # List of all tags
        getTags: (callback) ->
            q = $http.get(configService.restServiceUrl + '/tags')
            q.success (tags) -> callback(tags) if _.isFunction(callback)
            q.error -> alertify.error 'Cannot connect to cyclotron-svc (getTags)', 2500


        # List of autocomplete hints suggested when searching
        getSearchHints: (callback) ->
            q = $http.get(configService.restServiceUrl + '/searchhints')
            q.success (searchhints) -> callback(searchhints) if _.isFunction(callback)
            q.error -> alertify.error 'Cannot connect to cyclotron-svc (getSearchHints)', 2500
    }
