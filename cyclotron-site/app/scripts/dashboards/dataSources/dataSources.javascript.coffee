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
# JavaScript Data Source
#
# Enables custom JavaScript code to be used as a data source.  The custom JavaScript code will be run
# within the browser itself.
# 
# Properties:
#   processor: A javascript function to be run to load data.  A promise is passed in as an argument,
#              and this promise can be resolved, or a data set can be returned directly (for synchronous code).
#
cyclotronDataSources.factory 'javascriptDataSource', ($q, $http, configService, dataSourceFactory) ->

    runner = (options) ->
        q = $q.defer()

        processor = _.jsEval options.processor
        if !_.isFunction(processor) then processor = null

        if processor?
            promise = $q.defer()

            try
                result = processor(promise) || promise.promise
                if _.isObject(result) and result.promise?
                    result = result.promise

                # Post-Processor can either update the current dataset,
                # or return a new array that replaces it
                q2 = $q.when(result)

                q2.then (data) ->
                    if _.isArray data
                        q.resolve
                            '0':
                                data: data
                                columns: null
                    else 
                        err = 'Invalid data set returned in JavaScript Data Source.  Returned object must be an array of objects.'
                        console.log err
                        q.reject err
                
                q2.catch (reason) ->
                    console.log(reason)
                    q.reject reason
            catch error
                q.reject error
        else
            q.reject 'Processor is not a function.'

        return q.promise

    dataSourceFactory.create 'JavaScript', runner
