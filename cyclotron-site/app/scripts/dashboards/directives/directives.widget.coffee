###
# Copyright (c) 2013-2016 the original author or authors.
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
# Top-level Widget directive
# 
# Dynamically renders the configured widget into itself.  Expects the following
# scope variables:
#     widget: Widget to render
#     widgetIndex: Index of the widget in the current page (zero-indexed)
#     layout: Page layout object
#     dashboard: Entire Dashboard object
#     pageOverrides: Overrides object for the current page only
#     postLayout: Function to be called when the Widget has finished updating its layout
#
cyclotronDirectives.directive 'widget', ($compile, $sce, $window, layoutService) ->
    {
        restrict: 'A'
        scope:
            widget: '='
            widgetIndex: '='
            layout: '='
            dashboard: '='
            page: '='
            pageOverrides: '='
            postLayout: '&'

        link: (scope, element, attrs) ->

            $element = $(element)

            # Save the SCE handler in the scope
            scope.$sce = $sce

            scope.widgetLayout = { }

            # Update the layout
            updateLayout = (layout) ->
                
                # Ensure a valid layout is provided
                if _.isUndefined(layout)
                    return scope.postLayout()

                if isWidgetHidden()
                    # Hide Widget to avoid occupying space
                    $element.css 'display', 'none'
                    return scope.postLayout()

                # Copy gridWidth/width into the scope
                # Apply overrides if necessary (mobile devices)
                if layout.forceGridWidth? 
                    if scope.widget.gridWidth == layout.originalGridColumns
                        widgetGridWidth = layout.gridColumns
                    else
                        widgetGridWidth = layout.forceGridWidth 
                    widgetWidth = null
                else
                    widgetGridWidth = scope.widget.gridWidth
                    widgetWidth = scope.widget.width

                if layout.forceGridHeight?
                    if scope.widget.gridHeight == layout.originalGridRows
                        widgetGridHeight = layout.gridRows
                    else
                        widgetGridHeight = layout.forceGridHeight
                    widgetHeight = null
                else
                    widgetGridHeight = scope.widget.gridHeight
                    widgetHeight = scope.widget.height

                # Calculate widget dimensions
                if widgetHeight?
                    widgetHeight = scope.widget.height
                else if widgetGridHeight?
                    widgetHeight = layout.gridSquareHeight * widgetGridHeight + ((layout.gutter) * (widgetGridHeight - 1))

                if widgetWidth?
                    widgetWidth = scope.widget.width
                else if widgetGridWidth?
                    widgetWidth = layout.gridSquareWidth * widgetGridWidth + (layout.gutter * (widgetGridWidth - 1))
                else
                    widgetWidth = layout.gridSquareWidth

                # Set height/width
                widgetWidth = Math.floor(widgetWidth) if _.isNumber(widgetWidth)
                widgetHeight = Math.floor(widgetHeight) if _.isNumber(widgetHeight)
                $element.width widgetWidth
                $element.height widgetHeight
                $element.css 'display', 'block'

                if widgetWidth < widgetHeight
                    $element.addClass 'widget-skinny'
                else
                    $element.removeClass 'widget-skinny'

                # Set gutter padding (other sides are handled by masonry)    
                $element.css 'margin-bottom', layout.gutter

                # Trigger the post-layout update
                scope.postLayout()

                return

            # Determine if a Widget should be visible or hidden on the dashboard
            isWidgetHidden = ->
                return false unless scope.widget?
                
                if scope.pageOverrides?.widgets?
                    widgetOverrides = scope.pageOverrides.widgets?[scope.widgetIndex]

                    # If WidgetOverrides.hidden is set true or false, use its value
                    if widgetOverrides?.hidden?
                        return widgetOverrides.hidden == true

                # Else, default to the widget's "hidden" property
                return scope.widget.hidden == true

            # Store Widget API for use by Dashboards
            # Use scope.$evalAsync to ensure it gets digested by Angular
            if scope.widget.name?
                $window.Cyclotron.currentPage.widgets[scope.widget.name] = {
                    show: ->
                        scope.$evalAsync ->
                            widgetOverrides = scope.pageOverrides?.widgets?[scope.widgetIndex]
                            widgetOverrides.hidden = false
                    hide: ->
                        scope.$evalAsync ->
                            widgetOverrides = scope.pageOverrides?.widgets?[scope.widgetIndex]
                            widgetOverrides.hidden = true
                    toggleVisibility: ->
                        scope.$evalAsync ->
                            widgetOverrides = scope.pageOverrides?.widgets?[scope.widgetIndex]
                            widgetOverrides.hidden = !widgetOverrides.hidden
                }

            # Watch for the widget model to change, indicating this widget needs to be updated
            scope.$watch 'widget', (newValue, oldValue) ->
                widget = newValue

                # Ignore widgets without a type
                return if _.isEmpty widget.widget 

                noscrollClass = if widget.noscroll == true
                    ' widget-noscroll'
                else
                    ''

                # Create the include for the specific widget referenced
                template = '<div class="dashboard-widget ' + newValue.style + noscrollClass + '" ng-include="\'/widgets/' + newValue.widget + '/' + newValue.widget + '.html\'"></div>'

                if widget.allowFullscreen != false
                    template = '<i class="widget-fullscreen fa fa-expand" title="Click to view fullscreen"></i>' + template

                if widget.helpText?
                    # Store Help Text in scope for tooltip
                    scope.helpText = _.jsExec widget.helpText
                    template = '<i class="widget-helptext fa fa-question-circle" uib-tooltip="{{ ::helpText }}" tooltip-placement="auto-right" tooltip-trigger="outsideClick"></i>' + template

                compiledValue = $compile(template)(scope)

                # Replace the current contents with the newly compiled element
                element.contents().remove()
                element.append(compiledValue)

                return

            # Watch for page layout changes and resize the widget
            scope.$watch 'layout', updateLayout

            # Watch for widget visibility to change
            scope.$watch 'pageOverrides', (-> updateLayout(scope.layout)), true

            return
    }
