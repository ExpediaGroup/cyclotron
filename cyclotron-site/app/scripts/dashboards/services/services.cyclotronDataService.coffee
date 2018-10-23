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
# Provides access to the CyclotronData API
cyclotronServices.factory 'cyclotronDataService', ($http, configService, logService) ->
    defaultUrl = configService.restServiceUrl

    checkBucketExists = (key, url = defaultUrl) ->
        logService.debug 'CyclotronData: Checking if bucket exists:', key
        url = url + '/data/' + encodeURIComponent(key)
        req = $http.get url
        req.then (result) -> 
            true
        .catch (error) ->
            false

    createBucket = (key, data = [], url = defaultUrl) -> 
        logService.debug 'CyclotronData: Creating new bucket:', key
        url = url + '/data'
        req = $http.post url, { key, data }
        req.then (result) -> result.data

    ensureBucketExists = (key, url = defaultUrl) ->
        checkBucketExists(key, url).then (result) ->
            if !result
                createBucket key, [], url

    return {
        # Gets a list of available buckets (without data)
        getBuckets: (url = defaultUrl) -> 
            url = url + '/data'
            req = $http.get url
            req.then (result) -> result.data

        bucketExists: checkBucketExists

        # Creates a new bucket
        createBucket: createBucket

        # Deletes a bucket
        deleteBucket: (key, url = defaultUrl) -> 
            url = url + '/data/' + encodeURIComponent(key)
            req = $http.delete url

        # Gets a bucket
        getBucket: (key, url = defaultUrl) -> 
            url = url + '/data/' + encodeURIComponent(key)
            req = $http.get url
            req.then (result) -> 
                result.data
            .catch (error) ->
                null
        
        # Gets just the data for a bucket
        getBucketData: (key, url = defaultUrl) -> 
            url = url + '/data/' + encodeURIComponent(key) + '/data'
            req = $http.get url
            req.then (result) -> 
                result.data
            .catch (error) ->
                null

        # Replaces the data for a bucket
        updateBucketData: (key, data, url = defaultUrl) -> 
            ensureBucketExists(key, url).then ->
                url = url + '/data/' + encodeURIComponent(key) + '/data'
                req = $http.put url, data
                req.then (result) -> result.data

        # Appends to the data for a bucket
        append: (key, data, url = defaultUrl) -> 
            ensureBucketExists(key, url).then ->
                url = url + '/data/' + encodeURIComponent(key) + '/append'
                req = $http.post url, data
                req.then (result) -> result.data

        # Upserts a row of data for a bucket
        upsert: (key, matchingKeys, data, url = defaultUrl) -> 
            ensureBucketExists(key, url).then ->
                url = url + '/data/' + encodeURIComponent(key) + '/upsert'
                req = $http.post url, { keys: matchingKeys, data: data }
                req.then (result) -> result.data

        # Removes matching data from a bucket
        remove: (key, matchingKeys, data, url = defaultUrl) -> 
            ensureBucketExists(key, url).then ->
                url = url + '/data/' + encodeURIComponent(key) + '/remove'
                req = $http.post url, matchingKeys
                req.then (result) -> result.data
    }
