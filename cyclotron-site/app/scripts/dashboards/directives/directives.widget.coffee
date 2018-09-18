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
# Widget Context scope variables:
#     widgetContext: {
#         helpText: compiled text for the Help (?) tooltip icon
#         allowFullscreen: true if the user can view the Widget in fullscreen
#         allowExport: true if the user can export the data for the Widget
#         loading: true if the widget is loading
#         nodata: message to display when there is no data; null otherwise
#         data: filtered/sorted data for the Widget
#     }
#
cyclotronDirectives.directive 'widget', ($compile, $sce, $window, downloadService, layoutService) ->
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

        templateUrl: '/partials/widget.html'

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
                $element.width widgetWidth
                
                if scope.widget.autoHeight != true
                    widgetHeight = Math.floor(widgetHeight) if _.isNumber(widgetHeight)
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
                    widgetOverrides = scope.pageOverrides.widgets[scope.widget._originalIndex]

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
                            widgetOverrides = scope.pageOverrides?.widgets?[scope.widget._originalIndex]
                            widgetOverrides.hidden = false
                    hide: ->
                        scope.$evalAsync ->
                            widgetOverrides = scope.pageOverrides?.widgets?[scope.widget._originalIndex]
                            widgetOverrides.hidden = true
                    toggleVisibility: ->
                        scope.$evalAsync ->
                            widgetOverrides = scope.pageOverrides?.widgets?[scope.widget._originalIndex]
                            widgetOverrides.hidden = !widgetOverrides.hidden

                    exportData: (format) ->
                        scope.exportData format

                }

            # Watch for the widget model to change, indicating this widget needs to be updated
            scope.$watch 'widget', (newValue, oldValue) ->
                widget = newValue
                scope.widgetContext ?= {
                    loading: false
                    dataSourceError: false
                    dataSourceErrorMessage: null
                    nodata: null
                }

                # Ignore widgets without a type
                return if _.isEmpty widget.widget 

                # Update Widget HTML template to include
                scope.widgetTemplateUrl = '/widgets/' + widget.widget + '/' + widget.widget + '.html'

                # Update standard Widget Options
                if widget.helpText?
                    # Store Help Text in scope for tooltip
                    scope.widgetContext.helpText = _.jsExec widget.helpText
                else 
                    scope.widgetContext.helpText = null

                scope.widgetContext.allowFullscreen = widget.allowFullscreen != false
                scope.widgetContext.allowExport = widget.allowExport != false

                # Update additional Widget styles
                scope.widgetClass = ''

                if widget.style
                    scope.widgetClass += newValue.style

                if widget.noscroll == true
                    scope.widgetClass += ' widget-noscroll'

                return

            # Watch for page layout changes and resize the widget
            scope.$watch 'layout', updateLayout

            # Watch for widget visibility to change
            scope.$watch 'pageOverrides', (-> updateLayout(scope.layout)), true

            return
        
        controller: ($scope, dataService) ->

            $scope.showDropdown = ->
                # Extensible for additional dropdown items
                $scope.widgetContext?.allowExport

            # Evaluate Title of Widget
            $scope.widgetTitle = -> _.jsExec $scope.widget.title

            $scope.isLoading = ->
                $scope.widgetContext.loading

            $scope.noDataOrError = ->
                $scope.widgetContext.nodata or $scope.widgetContext.dataSourceError

            $scope.filterAndSortWidgetData = (data) ->
                # Filter the data if the widget has "filters"
                if $scope.widget.filters?
                    data = dataService.filter(data, $scope.widget.filters)

                # Sort the data if the widget has "sortBy"
                if $scope.widget.sortBy?
                    data = dataService.sort(data, $scope.widget.sortBy)

                # Check for nodata
                if _.isEmpty(data) && $scope.widget.noData?
                    $scope.widgetContext.nodata = _.jsExec $scope.widget.noData
                    $scope.widgetContext.data = null
                    $scope.widgetContext.allowExport = false
                else
                    # Reset
                    $scope.widgetContext.nodata = null
                    $scope.widgetContext.data = data
                    $scope.widgetContext.allowExport = $scope.widget.allowExport != false

                return $scope.widgetContext.data
                
            # Export Widget data as a downloaded file
            # Expects data in $scope.widgetContext.data
            # Returns promise
            $scope.exportData = (format) ->
                return unless $scope.widgetContext.data
                name = if _.isString($scope.widget.dataSource) 
                        name = $scope.widget.dataSource
                    else 
                        $scope.dashboard.name

                downloadService.download name, format, $scope.widgetContext.data

            return
    }
