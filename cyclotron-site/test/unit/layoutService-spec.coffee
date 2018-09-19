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

describe 'Unit: layoutService', ->

    defaultConfigService = null
    emptyDashboardPage = { layout: {} }

    beforeEach ->
        module 'cyclotronApp'
        module 'cyclotronApp.services'

        inject (configService) ->
            defaultConfigService = configService

    describe 'getLayout', ->
        it 'should not return null', inject (layoutService) ->
            expect(layoutService.getLayout(emptyDashboardPage)).not.toBeNull()

        it 'should be an object', inject (layoutService) ->
            expect(layoutService.getLayout(emptyDashboardPage)).toBeNonEmptyObject()

        it 'should return width and height correctly', inject (layoutService) ->
            layout = layoutService.getLayout(emptyDashboardPage, 1200, 900)
            expect(layout.width).toBe 1200
            expect(layout.height).toBe 900

        it 'should return margin, gutter, and borderWidth correctly', inject (layoutService) ->
            dashboardPage =
                layout:
                    margin: 20
                    gutter: 15
                    borderWidth: 10

            layout = layoutService.getLayout(dashboardPage, 1200, 900)
            expect(layout.margin).toBe 20
            expect(layout.gutter).toBe 15
            expect(layout.borderWidth).toBe 10

        it 'should return 0 margin for fullscreen', inject (layoutService) ->
            dashboardPage =
                style: 'fullscreen'
                layout:
                    margin: 20
                    gutter: 15

            layout = layoutService.getLayout(dashboardPage, 1200, 900)
            expect(layout.margin).toBe 0
            expect(layout.gutter).toBe 15

        it 'should handle 1 row/1 column', inject (layoutService) ->
            dashboardPage =
                layout:
                    margin: 10
                    gutter: 10
                    gridColumns: 1
                    gridRows: 1

            layout = layoutService.getLayout(dashboardPage, 1200, 900)
            expect(layout.gridColumns).toBe 1
            expect(layout.gridRows).toBe 1
            expect(layout.gridSquareWidth).toBe 1180
            expect(layout.gridSquareHeight).toBe 880

        it 'should handle 1 row/2 columns', inject (layoutService) ->
            dashboardPage =
                layout:
                    margin: 10
                    gutter: 10
                    gridColumns: 2
                    gridRows: 1

            layout = layoutService.getLayout(dashboardPage, 1200, 900)
            expect(layout.gridSquareWidth).toBe ((1200 - 30) / 2) # 2*margins, 1*gutter
            expect(layout.gridSquareHeight).toBe 880

        it 'should handle 1 row/3 columns', inject (layoutService) ->
            dashboardPage =
                layout:
                    margin: 10
                    gutter: 8
                    gridColumns: 3
                    gridRows: 1

            layout = layoutService.getLayout(dashboardPage, 1200, 900)
            expect(layout.gridSquareWidth).toBe ((1200 - 20 - 16) / 3) # 2*margins, 2*gutter
            expect(layout.gridSquareHeight).toBe 880

        it 'should handle 2 rows/1 column', inject (layoutService) ->
            dashboardPage =
                layout:
                    margin: 9
                    gutter: 8
                    gridColumns: 1
                    gridRows: 2

            layout = layoutService.getLayout(dashboardPage, 1200, 900)
            expect(layout.gridSquareWidth).toBe 1182
            expect(layout.gridSquareHeight).toBe ((900 - 18 - 8) / 2) # 2*margins, 2*gutter

        it 'should handle 2 rows/2 column', inject (layoutService) ->
            dashboardPage =
                layout:
                    margin: 10
                    gutter: 8
                    gridColumns: 2
                    gridRows: 2

            layout = layoutService.getLayout(dashboardPage, 1200, 900)
            expect(layout.gridSquareWidth).toBe ((1200 - 20 - 8) / 2)
            expect(layout.gridSquareHeight).toBe ((900 - 20 - 8) / 2)

        it 'should handle 3 rows/3 column', inject (layoutService) ->
            dashboardPage =
                layout:
                    margin: 10
                    gutter: 8
                    gridColumns: 3
                    gridRows: 3

            layout = layoutService.getLayout(dashboardPage, 1200, 900)
            expect(layout.gridSquareWidth).toBe Math.floor((1200 - 20 - 16) / 3)
            expect(layout.gridSquareHeight).toBe Math.floor((900 - 20 - 16) / 3)

        it 'should handle 3 rows/3 column, fullscreen', inject (layoutService) ->
            dashboardPage =
                style: 'fullscreen'
                layout:
                    margin: 10
                    gutter: 8
                    gridColumns: 3
                    gridRows: 3

            layout = layoutService.getLayout(dashboardPage, 1200, 900)
            expect(layout.gridSquareWidth).toBe Math.floor((1200 - 16) / 3)
            expect(layout.gridSquareHeight).toBe Math.floor((900 - 16) / 3)

        it 'should handle unspecified rows/columns', inject (layoutService) ->
            dashboardPage =
                layout:
                    margin: 10
                    gutter: 10

            layout = layoutService.getLayout(dashboardPage, 1200, 900)
            expect(layout.gridColumns).toBe 6
            expect(layout.gridRows).toBeUndefined()
            expect(layout.gridSquareWidth).toBe 188
            expect(layout.gridSquareHeight).toBe 188

        it 'should handle unspecified rows/columns with small resolution', inject (layoutService) ->
            dashboardPage =
                layout:
                    margin: 10
                    gutter: 10

            layout = layoutService.getLayout(dashboardPage, 500, 500)
            expect(layout.gridColumns).toBe 2
            expect(layout.gridRows).toBeUndefined()
            expect(layout.gridSquareWidth).toBe Math.floor((500 - 20 - 1*10) / 2)
            expect(layout.gridSquareHeight).toBe Math.floor((500 - 20 - 1*10) / 2)

        it 'should handle unspecified columns', inject (layoutService) ->
            dashboardPage =
                layout:
                    margin: 10
                    gutter: 10
                    gridRows: 4

            layout = layoutService.getLayout(dashboardPage, 1200, 900)
            expect(layout.gridColumns).toBe 6
            expect(layout.gridRows).toBe 4
            expect(layout.gridSquareWidth).toBe 188
            expect(layout.gridSquareHeight).toBe Math.floor((900 - 20 - 3*10) / 4)

        it 'should handle mobile portrait resolutions', inject (layoutService) ->
            dashboardPage =
                layout:
                    margin: 10
                    gutter: 10
                    gridRows: 4
                    gridColumns: 4

            layout = layoutService.getLayout(dashboardPage, 360, 400)
            expect(layout.margin).toBe 6
            expect(layout.gutter).toBe 6
            
            expect(layout.gridColumns).toBe 1
            expect(layout.gridRows).toBe 2

            expect(layout.forceGridWidth).toBe 1
            expect(layout.forceGridHeight).toBe 1

            expect(layout.gridSquareWidth).toBe (360 - 16 - 12)
            expect(layout.gridSquareHeight).toBe ((400 - 18) / 2)

        it 'should handle mobile landscape resolutions', inject (layoutService) ->
            dashboardPage =
                layout:
                    margin: 10
                    gutter: 10
                    gridRows: 4
                    gridColumns: 4

            layout = layoutService.getLayout(dashboardPage, 400, 360)
            expect(layout.margin).toBe 6
            expect(layout.gutter).toBe 6
            
            expect(layout.gridColumns).toBe 2
            expect(layout.gridRows).toBe 1

            expect(layout.forceGridWidth).toBe 1
            expect(layout.forceGridHeight).toBe 1

            expect(layout.gridSquareWidth).toBe ((400 - 12 - 16 - 6) / 2)
            expect(layout.gridSquareHeight).toBe (360 - 12)
