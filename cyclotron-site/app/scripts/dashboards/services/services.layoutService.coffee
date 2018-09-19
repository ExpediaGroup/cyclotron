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

cyclotronServices.factory 'layoutService', ->
    {
        getLayout: (dashboardPage, containerWidth, containerHeight) ->
            # Initialize the layout object with defaults
            layout =
                width: containerWidth
                height: containerHeight

                # Default parameters for auto-sizing widgets
                gridSquareMin: 180
                gridSquareMax: 300
                gridSquareMid: 220

                gridWidthAdjustment: dashboardPage.layout.gridWidthAdjustment || 0
                gridHeightAdjustment: dashboardPage.layout.gridHeightAdjustment || 0

                # Padding around outer edge of dashboard
                margin: dashboardPage.layout.margin

                # Padding between widgets
                gutter: dashboardPage.layout.gutter

                # Specifies the pixel width of the border around each widget.
                borderWidth: dashboardPage.layout.borderWidth

                # Override widget size settings
                forceGridWidth: null
                forceGridHeight: null

                # Store the original settings (in case it was modified)
                originalGridRows: dashboardPage.layout.gridRows
                originalGridColumns: dashboardPage.layout.gridColumns

                # Enable/disable vertical scrolling
                scrolling: dashboardPage.layout.scrolling

                # Optional Widget-specific properties
                widget: {}

            if (dashboardPage.style == 'fullscreen')
                # No margin on the fullscreen dashboards
                layout.margin = 0

            updateInnerWidth = ->
                layout.innerWidth = layout.width + layout.gridWidthAdjustment - (layout.margin * 2)

            updateInnerHeight = ->
                layout.innerHeight = layout.height + layout.gridHeightAdjustment - (layout.margin * 2)

            # Set the layout column count and calculate the width of each
            calculateSquareWidth = (gridColumns) ->
                layout.gridColumns = gridColumns

                # Available space for widgets
                updateInnerWidth()
                innerWidthMinusGutters = layout.innerWidth - ((gridColumns - 1) * layout.gutter)
                layout.gridSquareWidth = innerWidthMinusGutters / gridColumns

            # Set the layout row count and calculate the height of each
            calculateSquareHeight = (gridRows) ->
                layout.gridRows = gridRows

                # Available space for widgets
                updateInnerHeight()
                innerHeightMinusGutters = layout.innerHeight - ((gridRows - 1) * layout.gutter)
                layout.gridSquareHeight = innerHeightMinusGutters / gridRows

            reducePadding = ->
                layout.gutter = Math.min(6, dashboardPage.layout.gutter)
                layout.margin = Math.min(6, dashboardPage.layout.margin)

            # Phone portrait mode (400px max width)
            if layout.width <= 400 and layout.width < layout.height
                layout.gridHeightAdjustment = 0
                layout.gridWidthAdjustment = 0

                layout.width -= 16 # Add some padding on the right for the scroll bar
                reducePadding()

                calculateSquareWidth(1)
                layout.forceGridWidth = 1

                calculateSquareHeight(Math.min(2, dashboardPage.layout.gridRows))
                layout.forceGridHeight = 1

            # Phone landscape mode (400px max height)
            else if layout.height <= 400 and layout.width > layout.height
                layout.gridHeightAdjustment = 0
                layout.gridWidthAdjustment = 0

                layout.width -= 16 # Add some padding on the right for the scroll bar
                reducePadding()

                calculateSquareWidth(Math.min(2, dashboardPage.layout.gridColumns))
                layout.forceGridWidth = 1

                calculateSquareHeight(1)
                layout.forceGridHeight = 1

            else
                # Normal browser layout logic:
                layout.forceGridWidth = null
                layout.forceGridHeight = null

                # If dashboardPage specifies the number of horizontal grid spaces...
                if dashboardPage.layout.gridColumns? 
                    calculateSquareWidth(dashboardPage.layout.gridColumns)
                else
                    # Approximate a good number of squares
                    updateInnerWidth()
                    calculateSquareWidth(Math.ceil(layout.innerWidth / layout.gridSquareMid))
                    if layout.gridSquareWidth < layout.gridSquareMin
                        calculateSquareWidth(--layout.gridColumns)

                # If dashboardPage specifies the number of vertical grid spaces...
                if dashboardPage.layout.gridRows? 
                    calculateSquareHeight(dashboardPage.layout.gridRows)
                else
                    # Grid squares are actually square if not specified
                    layout.gridSquareHeight = layout.gridSquareWidth

            # Round down to avoid off-by-one pixel issues
            # This has some issues, namely that extra pixels can accumulate at 
            # the bottom and/or right of the screen.
            layout.gridSquareWidth = Math.floor(layout.gridSquareWidth)
            layout.gridSquareHeight = Math.floor(layout.gridSquareHeight)

            return layout
    }
