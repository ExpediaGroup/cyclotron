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

cyclotronServices.factory 'logService', ($window, configService) ->

    now = -> $window.moment().format 'HH:mm:ss'

    getString = (obj) ->
        if _.isObject obj
            JSON.stringify(obj)
        else
            obj

    # Logs any number of arguments prefixed with the time
    writeLog = (args) ->
        $window.console.log '[' + now() + '] ' + _.map(args, getString).join ' '

    writeError = (args) ->
        $window.console.error '[' + now() + '] ' + _.map(args, getString).join ' '

    service = {
        debug: ->
            args = Array.prototype.slice.call arguments
            args.unshift 'DEBUG:'
            writeLog args

        info: ->
            args = Array.prototype.slice.call arguments
            args.unshift 'INFO:'
            writeLog args
        
        error: ->
            args = Array.prototype.slice.call arguments
            args.unshift 'ERROR:'
            writeError args            
    }

    if configService.logging?.enableDebug == false
        service.debug = -> return

    return service
