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
# Manages Cyclotron.parameters
#
cyclotronServices.factory 'parameterService', ($localForage, $q, $window, configService, logService) ->
    
    getLocalStorageKey = (dashboard, parameterDefinition) ->
        'param.' + dashboard.name + '.' +  parameterDefinition.name

    isSet = (parameterDefinition) ->
        $window.Cyclotron.parameters[parameterDefinition.name]?

    setValue = (parameterDefinition, value) ->
        $window.Cyclotron.parameters[parameterDefinition.name] = value

    tryLoadDefaultValue = (parameterDefinition) ->
        # Ensure it has a default value
        return unless parameterDefinition.defaultValue?

        # Evaluate default value and ensure not-null
        value = _.jsExec(parameterDefinition.defaultValue)
        return unless value?

        logService.debug 'Assigned parameter with default value: ' + parameterDefinition.name + ', ' + value
        setValue parameterDefinition, value

    return {
        
        # Load Persisted Values for Parameters
        # Returns a promise after all parameters have been initialized
        initializeParameters: (dashboard) ->
            return $q (resolve, reject) ->
                # Shortcut if no parameters
                resolve() unless dashboard?.parameters?

                qs = _.map dashboard.parameters, (parameter) ->
                    $q (resolve, reject) ->
                        # Skip if already loaded (e.g. from URL, which takes precedence)
                        return resolve() if isSet parameter

                        # Check for persistence
                        if parameter.persistent == true
                            $localForage.getItem(getLocalStorageKey(dashboard, parameter)).then (value) ->
                                if value?
                                    logService.debug 'Loaded parameter from localstorage: ' + parameter.name + ', ' + value
                                    setValue parameter, value
                                else
                                    # Not persisted, try to load a default value instead
                                    # Do this inside the promise to avoid race condition
                                    tryLoadDefaultValue parameter
                                resolve()
                        else
                            tryLoadDefaultValue parameter
                            resolve()

                $q.all(qs).then ->

                    # Log all parameters
                    _.each $window.Cyclotron.parameters, (value, key) ->
                        logService.info('Initial Parameter [' + key + ']: ' + value)

                    resolve()


        savePersistentParameters: (parameters, dashboard) ->
            logService.debug 'Saving persistent parameters to local browser storage'
            persistentParams = _.filter dashboard.parameters, { persistent: true }

            _.each persistentParams, (parameterDefinition) ->
                value = parameters[parameterDefinition.name]
                if value?
                    $localForage.setItem(getLocalStorageKey(dashboard, parameterDefinition), value).then ->
                        logService.debug 'Saved parameter to localstorage: ' + parameterDefinition.name + ', ' + value
                else
                    $localForage.removeItem(getLocalStorageKey(dashboard, parameterDefinition)).then ->
                        logService.debug 'Removed parameter from localstorage: ' + parameterDefinition.name
        
    }
