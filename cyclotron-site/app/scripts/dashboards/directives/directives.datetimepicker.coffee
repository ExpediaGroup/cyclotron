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

cyclotronDirectives.directive 'datetimepicker', ($timeout) -> 
    {
        restrict: 'EAC'
        require: '?ngModel'
        template: '<input type="text">'
        scope:
            options: '='

        link: (scope, element, attrs, ngModelCtrl) ->

            textbox = element.find 'input[type=text]'
            
            # Default options
            defaultOptions = 
                scrollMonth: false
                format: 'Y-m-d H:i'
                formatDate: 'Y-m-d'
                formatTime: 'H:i'
                onChangeDateTime: (value, input) ->
                    # Handle changes from the datetimepicker
                    if ngModelCtrl? then scope.$apply ->
                        # Set the model and re-initialize the datetimepicker
                        ngModelCtrl.$setViewValue value
                        ngModelCtrl.$render()

                        # Convert back to the user-defined format and update textbox
                        formatted = moment(value).format mergedOptions.datetimeFormat
                        textbox.val formatted

                    return


            # Apply custom options over defaults    
            mergedOptions = _.merge defaultOptions, scope.options

            if ngModelCtrl?
                ngModelCtrl.$render = ->
                    # Set the value of the datetimepicker
                    mergedOptions.value = moment(ngModelCtrl.$viewValue).toDate()

                    # Initialize the datetimepicker plugin
                    element.datetimepicker mergedOptions

                    return 

                ngModelCtrl.$formatters.push (modelValue) ->
                    if modelValue
                        m = null
                        # Support either moments, dates, or strings
                        if moment.isMoment(modelValue)
                            m = modelValue
                        else if moment.isDate(modelValue)
                            m = moment(modelValue)
                        else
                            # Parse from string. Use specified format or ISO 8601
                            m = moment(modelValue, [mergedOptions.datetimeFormat, moment.ISO_8601])

                        # Convert to the user-defined format and update textbox
                        formatted = m.format mergedOptions.datetimeFormat
                        textbox.val formatted

                        # Return a JavaScript date to be used in the jQuery plugin
                        return m.toDate()

                ngModelCtrl.$parsers.push (viewValue) ->
                    if viewValue
                        # Convert to the user-defined format is update the model
                        formatted = moment(viewValue).format mergedOptions.datetimeFormat
                        return formatted

            # Handle manual changes to the textbox
            textbox.on 'keyup', (e) ->
                if ngModelCtrl?
                    modelValue = this.value
                    m = moment(modelValue, mergedOptions.datetimeFormat)
                    if m.isValid() then scope.$apply ->
                        # Update the view and re-initialize the plugin
                        ngModelCtrl.$setViewValue m.toDate()
                        ngModelCtrl.$render()
            return
    }
