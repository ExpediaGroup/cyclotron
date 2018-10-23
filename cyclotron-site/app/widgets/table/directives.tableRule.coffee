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

cyclotronDirectives.directive 'tableRule', ->
    {
        restrict: 'CA'
        link: (scope, element, attrs) ->
            $element = $(element)
            rules = scope.row.__matchingRules

            # Apply matching CSS styles
            _.each rules, (rule) ->
                # Apply all properties (keys) of each rule in turn.
                _.each _.keys(rule), (key) ->
                    return if key == 'columns' or key == 'rule' or key == 'text'

                    value = rule[key]

                    if _.isNullOrUndefined(rule.columnsAffected)
                        # Set entire row
                        $element.css(key, _.compile(value, scope.row))
                    else if not _.isNullOrUndefined scope.column
                        if scope.column.name in rule.columnsAffected
                            # Replace #value, then compile
                            value = _.valSub(value, scope.row[scope.column.name])
                            value = _.compile(value, scope.row)
                            
                            # Set single columns
                            $element.css(key, value)
    }
