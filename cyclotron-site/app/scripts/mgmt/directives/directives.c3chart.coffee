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

cyclotronDirectives.directive 'c3chart', ->
    {
        restrict: 'EAC'
        scope: 
            data: '='
            options: '='

        link: (scope, element) ->

            $element = $(element)
            scope.width = $element.width()

            # Generate random element ID
            if _.isEmpty $element.prop('id')
                scope.id = 'c3-' + uuid.v4()
                $element.prop 'id', scope.id

            redraw = ->
                return unless scope.data? and scope.data.length > 0

                options = 
                    bindto: '#' + scope.id
                    data: 
                        json: scope.data
                    size:
                        height: 200
                    
                # Apply passed options
                _.merge options, scope.options

                c3.generate options
            
            scope.$watch 'data', ->
                redraw()
            
            scope.$watch 'options', ->
                redraw()

    }
