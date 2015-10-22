###
# Copyright (c) 2013-2015 the original author or authors.
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

cyclotronDirectives.directive 'widget', ($compile, $sce, layoutService) ->
    {
        restrict: 'A'

        link: (scope, element, attrs) ->

            $element = $(element)

            #
            # This directive dynamically replaces itself with the specified widget in the current scope
            #
            widget = null
            layout = null

            # Save the SCE handler in the scope
            scope.$sce = $sce

            # Watch for the model to change, indicating this widget needs to be updated
            scope.$watch 'widget', (newValue, oldValue) ->
                widget = newValue

                # Ignore the widget if hidden is set
                return if widget.hidden == true

                # Ignore widgets without a type
                return if _.isEmpty widget.widget 

                noscrollClass = if widget.noscroll == true
                    ' widget-noscroll'
                else
                    ''

                # Create the include for the specific widget referenced
                template = '<div class="dashboard-widget ' + newValue.style + noscrollClass + '" ng-include="\'/widgets/' + newValue.widget + '/' + newValue.widget + '.html\'"></div>'

                if widget.allowFullscreen != false
                    template = '<i class="widget-fullscreen fa fa-arrows-alt" title="Click to view fullscreen"></i>' + template

                compiledValue = $compile(template)(scope)

                # Replace the current contents with the newly compiled element
                element.contents().remove()
                element.append(compiledValue)

                return

            scope.$watch('layout', (layout, oldLayout) ->

                # Ignore the widget if hidden is set
                return scope.postLayout() if widget.hidden == true or _.isUndefined(layout)

                # Copy gridWidth/width into the scope
                # Apply overrides if necessary (mobile devices)
                if layout.forceGridWidth? 
                    if widget.gridWidth == layout.originalGridColumns
                        scope.widgetGridWidth = layout.gridColumns
                    else
                        scope.widgetGridWidth = layout.forceGridWidth 
                    scope.widgetWidth = null
                else
                    scope.widgetGridWidth = widget.gridWidth
                    scope.widgetWidth = widget.width

                if layout.forceGridHeight?
                    if widget.gridHeight == layout.originalGridRows
                        scope.widgetGridHeight = layout.gridRows
                    else
                        scope.widgetGridHeight = layout.forceGridHeight
                    scope.widgetHeight = null
                else
                    scope.widgetGridHeight = widget.gridHeight
                    scope.widgetHeight = widget.height

                # Calculate widget dimensions
                if scope.widgetHeight?
                    scope.widgetHeight = widget.height
                else if scope.widgetGridHeight?
                    scope.widgetHeight = layout.gridSquareHeight * scope.widgetGridHeight + ((layout.gutter) * (scope.widgetGridHeight - 1))

                if scope.widgetWidth?
                    scope.widgetWidth = widget.width
                else if scope.widgetGridWidth?
                    scope.widgetWidth = layout.gridSquareWidth * scope.widgetGridWidth + (layout.gutter * (scope.widgetGridWidth - 1))
                else
                    scope.widgetWidth = layout.gridSquareWidth

                # Set height/width
                scope.widgetWidth = Math.floor(scope.widgetWidth) if _.isNumber(scope.widgetWidth)
                scope.widgetHeight = Math.floor(scope.widgetHeight) if _.isNumber(scope.widgetHeight)
                $element.width(scope.widgetWidth)
                $element.height(scope.widgetHeight)

                # Set gutter padding (other sides are handled by masonry)    
                $element.css('margin-bottom', layout.gutter)

                # Trigger the post-layout update
                scope.postLayout()

                return

            , true)

            return
    }
