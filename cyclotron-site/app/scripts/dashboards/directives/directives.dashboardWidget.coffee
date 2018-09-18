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

cyclotronDirectives.directive 'dashboardWidget', (layoutService) ->
    {
        restrict: 'AC'
        
        link: (scope, element, attrs) ->
            $element = $(element)
            $parent = $element.parent()

            scope.$watch 'widget', (widget) ->

                # Wire-up fullscreen button if available
                if widget.allowFullscreen
                    $parent.find('.widget-fullscreen').on 'click', ->
                        $element.fullScreen(true)
                return

            scope.$watch 'layout', (layout) ->
                return unless layout?

                # Set the border width if overloaded (otherwise keep theme default)
                if layout.borderWidth?
                    $element.css('border-width', layout.borderWidth + 'px')

            return

    }
