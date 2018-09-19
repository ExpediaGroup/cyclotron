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

describe 'Unit: dashboardService', ->

    configService = null
    dashboardService = null

    beforeEach ->
        module('cyclotronApp')
        module('cyclotronApp.services')

        inject (commonConfigService, _dashboardService_) ->
            configService = commonConfigService
            dashboardService = _dashboardService_

    describe 'parse', ->
        it 'should throw an error for empty string', ->
            expect(_.partial(dashboardService.parse, '')).toThrowError()

        it 'should throw an error for unmatched braces', ->
            expect(_.partial(dashboardService.parse, '{')).toThrowError()

        it 'should parse an empty object', ->
            expect(dashboardService.parse('{}')).toBeEmptyObject()

        it 'should parse an object with one property', ->
            o = dashboardService.parse('{"a": true}')
            expect(o).toBeNonEmptyObject()
            expect(o.a).toBeTrue()

        it 'should parse nested objects', ->
            dashboard = dashboardService.parse('{"name": "dashboard-1", pages: [{"name": "page1"}]}')
            expect(dashboard).toBeNonEmptyObject()
            expect(dashboard.name).toBe 'dashboard-1'
            expect(dashboard.pages).toBeNonEmptyArray()
            expect(dashboard.pages[0].name).toBe 'page1'

        it 'should ignore whitespace', ->
            o = dashboardService.parse('    {   "a"    : true   }   ')
            expect(o).toBeNonEmptyObject()
            expect(o.a).toBeTrue()

        it 'should ignore newlines', ->
            o = dashboardService.parse('{\r"a"\r:\rtrue\r}\r')
            expect(o).toBeNonEmptyObject()
            expect(o.a).toBeTrue()

        it 'should ignore more newlines', ->
            o = dashboardService.parse('{\r\n"a"\n\r:\r\ntrue\r}\n')
            expect(o).toBeNonEmptyObject()
            expect(o.a).toBeTrue()
    
        it 'should ignore tabs', ->
            o = dashboardService.parse('{\r\t"a":\r\n\t\ttrue\r}\r')
            expect(o).toBeNonEmptyObject()
            expect(o.a).toBeTrue()

    describe 'toString', ->
        it 'should return empty string for null', ->
            expect(dashboardService.toString(null)).toBeEmptyString()

        it 'should return empty string for undefined string', ->
            expect(dashboardService.toString(undefined)).toBeEmptyString()

        it 'should tostring an object', ->
            expect(dashboardService.toString({ a: '1' })).toBe '{\n    "a": "1"\n}'
            expect(dashboardService.toString({ a: '1', b: '2' })).toBe '{\n    "a": "1",\n    "b": "2"\n}'

        it 'should omit internal properties of an object', ->
            expect(dashboardService.toString({ $$hashKey: 'xxxx' })).toBe '{}'

    describe 'newDashboard', ->
        it 'should not return null', ->
            expect(dashboardService.newDashboard()).not.toBeNull()

        it 'should be an object', ->
            expect(dashboardService.newDashboard()).toBeNonEmptyObject()

        it 'should match config service sample', ->
            expect(dashboardService.newDashboard()).toEqual configService.dashboard.sample

        it 'should not return the same object twice', ->
            dashboard1 = dashboardService.newDashboard()
            dashboard2 = dashboardService.newDashboard()
            expect(dashboard1).toEqual dashboard2
            expect(dashboard1).not.toBe dashboard2

    describe 'addPage', ->
        it 'should return the same dashboard object', ->
            dashboard = { name: 'add-page-dashboard' }
            updatedDashboard = dashboardService.addPage(dashboard)
            expect(updatedDashboard).toBe dashboard
            expect(updatedDashboard.name).toBe 'add-page-dashboard'

        it 'should match config service sample', ->
            dashboard = { name: 'add-page-dashboard' }
            dashboardService.addPage(dashboard)
            expect(dashboard.pages[0]).toEqual configService.page.sample

        it 'should add a page if pages is missing', ->
            dashboard = { name: 'add-page-dashboard' }
            dashboardService.addPage(dashboard)
            expect(dashboard.pages.length).toBe 1

        it 'should add a page if pages is empty', ->
            dashboard = { name: 'add-page-dashboard', pages: [] }
            dashboardService.addPage(dashboard)
            expect(dashboard.pages.length).toBe 1

        it 'should add a page if pages is not empty', ->
            dashboard = { name: 'add-page-dashboard', pages: [{ 'name': 'page 1' }] }
            dashboardService.addPage(dashboard)
            expect(dashboard.pages.length).toBe 2

        it 'should add multiple pages', ->
            dashboard = { name: 'add-page-dashboard' }
            dashboardService.addPage(dashboard)
            dashboardService.addPage(dashboard)
            dashboardService.addPage(dashboard)
            expect(dashboard.pages.length).toBe 3

            expect(dashboard.pages[0]).toEqual dashboard.pages[1]
            expect(dashboard.pages[0]).not.toBe dashboard.pages[1]
            expect(dashboard.pages[1]).toEqual dashboard.pages[2]
            expect(dashboard.pages[1]).not.toBe dashboard.pages[2]

    describe 'removePage', ->
        it 'should return the same dashboard object', ->
            dashboard = { name: 'remove-page-dashboard', pages: [{ 'name': 'page1' }] }
            updatedDashboard = dashboardService.removePage(dashboard, 0)
            expect(updatedDashboard).toBe dashboard
            expect(updatedDashboard.name).toBe 'remove-page-dashboard'

        it 'should do nothing if no pages exist', ->
            dashboard = { name: 'remove-page-dashboard' }
            dashboardService.removePage(dashboard, 0)
            expect(dashboard.pages).toBeUndefined()

        it 'should do nothing if index is outside range', ->
            dashboard = { name: 'remove-page-dashboard', pages: [{ 'name': 'page1' }] }
            dashboardService.removePage(dashboard, 1)
            expect(dashboard.pages.length).toBe 1
            expect(dashboard.pages[0].name).toBe 'page1'

        it 'should do nothing if index is negative', ->
            dashboard = { name: 'remove-page-dashboard', pages: [{ 'name': 'page1' }] }
            dashboardService.removePage(dashboard, -1)
            expect(dashboard.pages.length).toBe 1
            expect(dashboard.pages[0].name).toBe 'page1'

        it 'should remove the first and only page', ->
            dashboard = { name: 'remove-page-dashboard', pages: [{ 'name': 'page1' }] }
            dashboardService.removePage(dashboard, 0)
            expect(dashboard.pages).toBeEmptyArray()

        it 'should remove the first page of two', ->
            dashboard = { name: 'remove-page-dashboard', pages: [{ 'name': 'page1' }, { 'name': 'page2' }] }
            dashboardService.removePage(dashboard, 0)
            expect(dashboard.pages.length).toBe 1
            expect(dashboard.pages[0].name).toBe 'page2'

        it 'should remove the last page of two', ->
            dashboard = { name: 'remove-page-dashboard', pages: [{ 'name': 'page1' }, { 'name': 'page2' }] }
            dashboardService.removePage(dashboard, 1)
            expect(dashboard.pages.length).toBe 1
            expect(dashboard.pages[0].name).toBe 'page1'

    describe 'addDataSource', ->
        it 'should return the same dashboard object', ->
            dashboard = { name: 'add-datasource-dashboard' }
            updatedDashboard = dashboardService.addDataSource(dashboard)
            expect(updatedDashboard).toBe dashboard
            expect(updatedDashboard.name).toBe 'add-datasource-dashboard'

        it 'should add a dataSource if dataSources is missing', ->
            dashboard = { name: 'add-datasource-dashboard' }
            dashboardService.addDataSource(dashboard)
            expect(dashboard.dataSources.length).toBe 1

        it 'should add a dataSource if dataSources is empty', ->
            dashboard = { name: 'add-datasource-dashboard', dataSources: [] }
            dashboardService.addDataSource(dashboard)
            expect(dashboard.dataSources.length).toBe 1
            expect(dashboard.dataSources[0].name).toBe 'datasource_0'

        it 'should add a dataSource if dataSources is not empty', ->
            dashboard = { name: 'add-datasource-dashboard', dataSources: [{ 'name': 'dataSource 1' }] }
            dashboardService.addDataSource(dashboard)
            expect(dashboard.dataSources.length).toBe 2
            expect(dashboard.dataSources[1].name).toBe 'datasource_1'
            expect(dashboard.dataSources[0].type).toBeUndefined()

        it 'should add multiple dataSources', ->
            dashboard = { name: 'add-datasource-dashboard' }
            dashboardService.addDataSource(dashboard)
            dashboardService.addDataSource(dashboard)
            dashboardService.addDataSource(dashboard)
            expect(dashboard.dataSources.length).toBe 3
            expect(dashboard.dataSources[0].name).toBe 'datasource_0'
            expect(dashboard.dataSources[1].name).toBe 'datasource_1'
            expect(dashboard.dataSources[2].name).toBe 'datasource_2'

        it 'should add a dataSource with a specific type', ->
            dashboard = { name: 'add-datasource-dashboard', dataSources: [] }
            dashboardService.addDataSource(dashboard, 'graphite')
            expect(dashboard.dataSources.length).toBe 1
            expect(dashboard.dataSources[0].name).toBe 'datasource_0'
            expect(dashboard.dataSources[0].type).toBe 'graphite'

    describe 'removeDataSource', ->
        it 'should return the same dashboard object', ->
            dashboard = { name: 'remove-datasource-dashboard', dataSources: [{ 'name': 'datasource_0' }] }
            updatedDashboard = dashboardService.removeDataSource(dashboard, 0)
            expect(updatedDashboard).toBe dashboard
            expect(updatedDashboard.name).toBe 'remove-datasource-dashboard'

        it 'should do nothing if no data sources exist', ->
            dashboard = { name: 'remove-datasource-dashboard' }
            dashboardService.removeDataSource(dashboard, 0)
            expect(dashboard.dataSources).toBeUndefined()

        it 'should do nothing if index is outside range', ->
            dashboard = { name: 'remove-datasource-dashboard', dataSources: [{ 'name': 'datasource_0' }] }
            dashboardService.removeDataSource(dashboard, 1)
            expect(dashboard.dataSources.length).toBe 1
            expect(dashboard.dataSources[0].name).toBe 'datasource_0'

        it 'should do nothing if index is negative', ->
            dashboard = { name: 'remove-datasource-dashboard', dataSources: [{ 'name': 'datasource_0' }] }
            dashboardService.removeDataSource(dashboard, -1)
            expect(dashboard.dataSources.length).toBe 1
            expect(dashboard.dataSources[0].name).toBe 'datasource_0'

        it 'should remove the first and only data source', ->
            dashboard = { name: 'remove-datasource-dashboard', dataSources: [{ 'name': 'datasource_0' }] }
            dashboardService.removeDataSource(dashboard, 0)
            expect(dashboard.dataSources).toBeEmptyArray()

        it 'should remove the first data source of two', ->
            dashboard = { name: 'remove-datasource-dashboard', dataSources: [{ 'name': 'datasource_0' }, { 'name': 'datasource_1' }] }
            dashboardService.removeDataSource(dashboard, 0)
            expect(dashboard.dataSources.length).toBe 1
            expect(dashboard.dataSources[0].name).toBe 'datasource_1'

        it 'should remove the last data source of two', ->
            dashboard = { name: 'remove-datasource-dashboard', dataSources: [{ 'name': 'datasource_0' }, { 'name': 'datasource_1' }] }
            dashboardService.removeDataSource(dashboard, 1)
            expect(dashboard.dataSources.length).toBe 1
            expect(dashboard.dataSources[0].name).toBe 'datasource_0'

    describe 'addParameter', ->
        it 'should return the same dashboard object', ->
            dashboard = { name: 'add-parameter-dashboard' }
            updatedDashboard = dashboardService.addParameter(dashboard)
            expect(updatedDashboard).toBe dashboard
            expect(updatedDashboard.name).toBe 'add-parameter-dashboard'

        it 'should match config service sample', ->
            dashboard = { name: 'add-parameter-dashboard' }
            dashboardService.addParameter(dashboard)
            expect(dashboard.parameters[0]).toEqual configService.dashboard.properties.parameters.sample

        it 'should add a parameter if parameters is missing', ->
            dashboard = { name: 'add-parameter-dashboard' }
            dashboardService.addParameter(dashboard)
            expect(dashboard.parameters.length).toBe 1

        it 'should add a parameter if parameters is empty', ->
            dashboard = { name: 'add-parameter-dashboard', parameters: [] }
            dashboardService.addParameter(dashboard)
            expect(dashboard.parameters.length).toBe 1
            expect(dashboard.parameters[0].name).toBe ''

        it 'should add a parameter if parameters is not empty', ->
            dashboard = { name: 'add-parameter-dashboard', parameters: [{ 'name': 'parameter 1' }] }
            dashboardService.addParameter(dashboard)
            expect(dashboard.parameters.length).toBe 2
            expect(dashboard.parameters[0].name).toBe 'parameter 1'
            expect(dashboard.parameters[1].name).toBe ''

        it 'should add multiple parameters', ->
            dashboard = { name: 'add-parameter-dashboard' }
            dashboardService.addParameter(dashboard)
            dashboardService.addParameter(dashboard)
            dashboardService.addParameter(dashboard)
            expect(dashboard.parameters.length).toBe 3

    describe 'removeParameter', ->
        it 'should return the same dashboard object', ->
            dashboard = { name: 'remove-parameter-dashboard', parameters: [{ 'name': 'p1' }] }
            updatedDashboard = dashboardService.removeParameter(dashboard, 0)
            expect(updatedDashboard).toBe dashboard
            expect(updatedDashboard.name).toBe 'remove-parameter-dashboard'

        it 'should do nothing if no data sources exist', ->
            dashboard = { name: 'remove-parameter-dashboard' }
            dashboardService.removeParameter(dashboard, 0)
            expect(dashboard.parameters).toBeUndefined()

        it 'should do nothing if index is outside range', ->
            dashboard = { name: 'remove-parameter-dashboard', parameters: [{ 'name': 'p1' }] }
            dashboardService.removeParameter(dashboard, 1)
            expect(dashboard.parameters.length).toBe 1
            expect(dashboard.parameters[0].name).toBe 'p1'

        it 'should do nothing if index is negative', ->
            dashboard = { name: 'remove-parameter-dashboard', parameters: [{ 'name': 'p1' }] }
            dashboardService.removeParameter(dashboard, -1)
            expect(dashboard.parameters.length).toBe 1
            expect(dashboard.parameters[0].name).toBe 'p1'

        it 'should remove the first and only parameter', ->
            dashboard = { name: 'remove-parameter-dashboard', parameters: [{ 'name': 'p1' }] }
            dashboardService.removeParameter(dashboard, 0)
            expect(dashboard.parameters).toBeEmptyArray()

        it 'should remove the first parameter of two', ->
            dashboard = { name: 'remove-parameter-dashboard', parameters: [{ 'name': 'p1' }, { 'name': 'p2' }] }
            dashboardService.removeParameter(dashboard, 0)
            expect(dashboard.parameters.length).toBe 1
            expect(dashboard.parameters[0].name).toBe 'p2'

        it 'should remove the last parameter of two', ->
            dashboard = { name: 'remove-parameter-dashboard', parameters: [{ 'name': 'p1' }, { 'name': 'p2' }] }
            dashboardService.removeParameter(dashboard, 1)
            expect(dashboard.parameters.length).toBe 1
            expect(dashboard.parameters[0].name).toBe 'p1'

    describe 'addScript', ->
        it 'should return the same dashboard object', ->
            dashboard = { name: 'add-script-dashboard' }
            updatedDashboard = dashboardService.addScript(dashboard)
            expect(updatedDashboard).toBe dashboard
            expect(updatedDashboard.name).toBe 'add-script-dashboard'

        it 'should match config service sample', ->
            dashboard = { name: 'add-script-dashboard' }
            dashboardService.addScript(dashboard)
            expect(dashboard.scripts[0]).toEqual configService.dashboard.properties.scripts.sample

        it 'should add a script if scripts is missing', ->
            dashboard = { name: 'add-script-dashboard' }
            dashboardService.addScript(dashboard)
            expect(dashboard.scripts.length).toBe 1

        it 'should add a script if scripts is empty', ->
            dashboard = { name: 'add-script-dashboard', scripts: [] }
            dashboardService.addScript(dashboard)
            expect(dashboard.scripts.length).toBe 1
            expect(dashboard.scripts[0].text).toBe ''

        it 'should add a script if scripts is not empty', ->
            dashboard = { name: 'add-script-dashboard', scripts: [{ 'text': 'console.log("hello")' }] }
            dashboardService.addScript(dashboard)
            expect(dashboard.scripts.length).toBe 2
            expect(dashboard.scripts[0].text).toBe 'console.log("hello")'
            expect(dashboard.scripts[1].text).toBe ''

        it 'should add multiple scripts', ->
            dashboard = { name: 'add-script-dashboard' }
            dashboardService.addScript(dashboard)
            dashboardService.addScript(dashboard)
            dashboardService.addScript(dashboard)
            expect(dashboard.scripts.length).toBe 3

    describe 'removeScript', ->
        it 'should return the same dashboard object', ->
            dashboard = { name: 'remove-script-dashboard', scripts: [{ 'name': 'script1' }] }
            updatedDashboard = dashboardService.removeScript(dashboard, 0)
            expect(updatedDashboard).toBe dashboard
            expect(updatedDashboard.name).toBe 'remove-script-dashboard'

        it 'should do nothing if no data sources exist', ->
            dashboard = { name: 'remove-script-dashboard' }
            dashboardService.removeScript(dashboard, 0)
            expect(dashboard.scripts).toBeUndefined()

        it 'should do nothing if index is outside range', ->
            dashboard = { name: 'remove-script-dashboard', scripts: [{ 'name': 'script1' }] }
            dashboardService.removeScript(dashboard, 1)
            expect(dashboard.scripts.length).toBe 1
            expect(dashboard.scripts[0].name).toBe 'script1'

        it 'should do nothing if index is negative', ->
            dashboard = { name: 'remove-script-dashboard', scripts: [{ 'name': 'script1' }] }
            dashboardService.removeScript(dashboard, -1)
            expect(dashboard.scripts.length).toBe 1
            expect(dashboard.scripts[0].name).toBe 'script1'

        it 'should remove the first and only script', ->
            dashboard = { name: 'remove-script-dashboard', scripts: [{ 'name': 'script1' }] }
            dashboardService.removeScript(dashboard, 0)
            expect(dashboard.scripts).toBeEmptyArray()

        it 'should remove the first script of two', ->
            dashboard = { name: 'remove-script-dashboard', scripts: [{ 'name': 'script1' }, { 'name': 'script2' }] }
            dashboardService.removeScript(dashboard, 0)
            expect(dashboard.scripts.length).toBe 1
            expect(dashboard.scripts[0].name).toBe 'script2'

        it 'should remove the last script of two', ->
            dashboard = { name: 'remove-script-dashboard', scripts: [{ 'name': 'script1' }, { 'name': 'script2' }] }
            dashboardService.removeScript(dashboard, 1)
            expect(dashboard.scripts.length).toBe 1
            expect(dashboard.scripts[0].name).toBe 'script1'

    describe 'addStyle', ->
        it 'should return the same dashboard object', ->
            dashboard = { name: 'add-style-dashboard' }
            updatedDashboard = dashboardService.addStyle(dashboard)
            expect(updatedDashboard).toBe dashboard
            expect(updatedDashboard.name).toBe 'add-style-dashboard'

        it 'should match config service sample', ->
            dashboard = { name: 'add-style-dashboard' }
            dashboardService.addStyle(dashboard)
            expect(dashboard.styles[0]).toEqual configService.dashboard.properties.styles.sample

        it 'should add a style if styles is missing', ->
            dashboard = { name: 'add-style-dashboard' }
            dashboardService.addStyle(dashboard)
            expect(dashboard.styles.length).toBe 1

        it 'should add a style if styles is empty', ->
            dashboard = { name: 'add-style-dashboard', styles: [] }
            dashboardService.addStyle(dashboard)
            expect(dashboard.styles.length).toBe 1
            expect(dashboard.styles[0].text).toBe ''

        it 'should add a style if styles is not empty', ->
            dashboard = { name: 'add-style-dashboard', styles: [{ 'text': 'div: { border: 1px;}' }] }
            dashboardService.addStyle(dashboard)
            expect(dashboard.styles.length).toBe 2
            expect(dashboard.styles[0].text).toBe 'div: { border: 1px;}'
            expect(dashboard.styles[1].text).toBe ''

        it 'should add multiple styles', ->
            dashboard = { name: 'add-style-dashboard' }
            dashboardService.addStyle(dashboard)
            dashboardService.addStyle(dashboard)
            dashboardService.addStyle(dashboard)
            expect(dashboard.styles.length).toBe 3

    describe 'removeStyle', ->
        it 'should return the same dashboard object', ->
            dashboard = { name: 'remove-style-dashboard', styles: [{ 'name': 'style1' }] }
            updatedDashboard = dashboardService.removeStyle(dashboard, 0)
            expect(updatedDashboard).toBe dashboard
            expect(updatedDashboard.name).toBe 'remove-style-dashboard'

        it 'should do nothing if no data sources exist', ->
            dashboard = { name: 'remove-style-dashboard' }
            dashboardService.removeStyle(dashboard, 0)
            expect(dashboard.styles).toBeUndefined()

        it 'should do nothing if index is outside range', ->
            dashboard = { name: 'remove-style-dashboard', styles: [{ 'name': 'style1' }] }
            dashboardService.removeStyle(dashboard, 1)
            expect(dashboard.styles.length).toBe 1
            expect(dashboard.styles[0].name).toBe 'style1'

        it 'should do nothing if index is negative', ->
            dashboard = { name: 'remove-style-dashboard', styles: [{ 'name': 'style1' }] }
            dashboardService.removeStyle(dashboard, -1)
            expect(dashboard.styles.length).toBe 1
            expect(dashboard.styles[0].name).toBe 'style1'

        it 'should remove the first and only style', ->
            dashboard = { name: 'remove-style-dashboard', styles: [{ 'name': 'style1' }] }
            dashboardService.removeStyle(dashboard, 0)
            expect(dashboard.styles).toBeEmptyArray()

        it 'should remove the first style of two', ->
            dashboard = { name: 'remove-style-dashboard', styles: [{ 'name': 'style1' }, { 'name': 'style2' }] }
            dashboardService.removeStyle(dashboard, 0)
            expect(dashboard.styles.length).toBe 1
            expect(dashboard.styles[0].name).toBe 'style2'

        it 'should remove the last style of two', ->
            dashboard = { name: 'remove-style-dashboard', styles: [{ 'name': 'style1' }, { 'name': 'style2' }] }
            dashboardService.removeStyle(dashboard, 1)
            expect(dashboard.styles.length).toBe 1
            expect(dashboard.styles[0].name).toBe 'style1'

    describe 'addWidget', ->
        it 'should return the same dashboard object', ->
            dashboard = { name: 'add-widget-dashboard' }
            updatedDashboard = dashboardService.addWidget(dashboard, null, 0)
            expect(updatedDashboard).toBe dashboard
            expect(updatedDashboard.name).toBe 'add-widget-dashboard'

        it 'should match config service sample', ->
            dashboard = { name: 'add-widget-dashboard' }
            dashboardService.addWidget(dashboard, 'clock', 0)

            expected = { widget: 'clock' }
            expect(dashboard.pages[0].widgets[0]).toEqual expected

        it 'should add a blank widget if name is missing', ->
            dashboard = { name: 'add-widget-dashboard' }
            dashboardService.addWidget(dashboard, null, 0)
            expect(dashboard.pages[0].widgets[0].widget).toEqual ''

        it 'should add a page if pages is missing', ->
            dashboard = { name: 'add-widget-dashboard' }
            dashboardService.addWidget(dashboard, null, null)
            expect(dashboard.pages.length).toBe 1
            expect(dashboard.pages[0].widgets).toBeNonEmptyArray()
            expect(dashboard.pages[0].widgets.length).toBe 1
            expect(dashboard.pages[0].widgets[0].widget).toBe ''

        it 'should add a page if pages is empty', ->
            dashboard = { name: 'add-widget-dashboard', pages: [] }
            dashboardService.addWidget(dashboard, null, null)
            expect(dashboard.pages.length).toBe 1
            expect(dashboard.pages[0].widgets).toBeNonEmptyArray()
            expect(dashboard.pages[0].widgets.length).toBe 1
            expect(dashboard.pages[0].widgets[0].widget).toBe ''

        it 'should add a widget to an existing page', ->
            dashboard = { name: 'add-widget-dashboard', pages: [{ name: 'page1' }] }
            dashboardService.addWidget(dashboard, null, null)
            expect(dashboard.pages.length).toBe 1
            expect(dashboard.pages[0].widgets.length).toBe 1
            expect(dashboard.pages[0].widgets[0].widget).toBe ''

        it 'should add a widget to the second page', ->
            dashboard = { name: 'add-widget-dashboard', pages: [{ widgets: [{ widget: 'clock' }] }, { widgets: [{ widget: 'table' }] }] }
            dashboardService.addWidget(dashboard, 'chart', 1)
            expect(dashboard.pages.length).toBe 2
            expect(dashboard.pages[0].widgets[0].widget).toBe 'clock'
            expect(dashboard.pages[1].widgets[0].widget).toBe 'table'
            expect(dashboard.pages[1].widgets[1].widget).toBe 'chart'

        it 'should add multiple widgets', ->
            dashboard = { name: 'add-widget-dashboard', pages: [{ widgets: [{ widget: 'clock' }] }, { widgets: [{ widget: 'table' }] }] }
            dashboardService.addWidget(dashboard, 'chart', 1)
            dashboardService.addWidget(dashboard, 'number', 1)
            dashboardService.addWidget(dashboard, 'chart', 1)
            dashboardService.addWidget(dashboard, 'number', 0)
            expect(dashboard.pages.length).toBe 2
            expect(dashboard.pages[0].widgets.length).toBe 2
            expect(dashboard.pages[0].widgets[0].widget).toBe 'clock'
            expect(dashboard.pages[0].widgets[1].widget).toBe 'number'
            expect(dashboard.pages[1].widgets.length).toBe 4
            expect(dashboard.pages[1].widgets[0].widget).toBe 'table'
            expect(dashboard.pages[1].widgets[1].widget).toBe 'chart'
            expect(dashboard.pages[1].widgets[2].widget).toBe 'number'
            expect(dashboard.pages[1].widgets[3].widget).toBe 'chart'

    describe 'removeWidget', ->
        it 'should return the same dashboard object', ->
            dashboard = { name: 'remove-widget-dashboard', pages: [{ widgets: [{ widget: 'clock' }] }, { widgets: [{ widget: 'table' }] }] }
            updatedDashboard = dashboardService.removeWidget(dashboard, 0, 0)
            expect(updatedDashboard).toBe dashboard
            expect(updatedDashboard.name).toBe 'remove-widget-dashboard'

        it 'should do nothing if no widgets exist', ->
            dashboard = { name: 'remove-widget-dashboard' }
            dashboardService.removeWidget(dashboard, 0, 0)
            expect(dashboard.name).toBe 'remove-widget-dashboard'
            expect(dashboard.pages).toBeUndefined()

        it 'should do nothing if index is outside range', ->
            dashboard = { name: 'remove-widget-dashboard', pages: [{ widgets: [{ widget: 'clock' }] }] }
            dashboardService.removeWidget(dashboard, 5, 0)
            expect(dashboard.pages.length).toBe 1
            expect(dashboard.pages[0].widgets[0].widget).toBe 'clock'

        it 'should do nothing if widget index is negative', ->
            dashboard = { name: 'remove-widget-dashboard', pages: [{ widgets: [{ widget: 'clock' }] }] }
            dashboardService.removeWidget(dashboard, -1, 0)
            expect(dashboard.pages.length).toBe 1
            expect(dashboard.pages[0].widgets[0].widget).toBe 'clock'

        it 'should remove the first and only widget', ->
            dashboard = { name: 'remove-widget-dashboard', pages: [{ widgets: [{ widget: 'clock' }] }] }
            dashboardService.removeWidget(dashboard, 0, 0)
            expect(dashboard.pages.length).toBe 1
            expect(dashboard.pages[0].widgets).toBeEmptyArray()

        it 'should remove the first widget of two', ->
            dashboard = { name: 'remove-widget-dashboard', pages: [{ widgets: [{ widget: 'clock' }, { widget: 'table' }] }] }
            dashboardService.removeWidget(dashboard, 0, 0)
            expect(dashboard.pages.length).toBe 1
            expect(dashboard.pages[0].widgets.length).toBe 1
            expect(dashboard.pages[0].widgets[0].widget).toBe 'table'

        it 'should remove the last widget of two', ->
            dashboard = { name: 'remove-widget-dashboard', pages: [{ widgets: [{ widget: 'clock' }, { widget: 'table' }] }] }
            dashboardService.removeWidget(dashboard, 1, 0)
            expect(dashboard.pages.length).toBe 1
            expect(dashboard.pages[0].widgets.length).toBe 1
            expect(dashboard.pages[0].widgets[0].widget).toBe 'clock'

    describe 'setDashboardDefaults', ->
        verifyDefaultProperties = (obj, properties, ignored, parent) ->
            _.each properties, (property, name) ->
                return if name in ignored
                return unless property.default? or property.inherit?

                # Inherit from the parent object
                if property.inherit == true
                    expect(obj[name]).toEqual parent[name]
                else
                    expect(obj[name]).toEqual property.default
        
        it 'should set the default dashboard properties on empty Dashboard', ->
            testDashboard = 
                name: 'testDashboard'
            dashboard = dashboardService.setDashboardDefaults(testDashboard)

            _.each configService.dashboard.properties, (property, name) ->
                return unless property.default?
                expect(dashboard[name]).toEqual property.default

            expect(dashboard.dataSources.length).toBe 0
            expect(dashboard.scripts.length).toBe 0

        it 'should not overwrite existing properties', ->
            testDashboard = 
                name: 'testDashboard'
                theme: 'aqua'
                duration: 1

            dashboard = dashboardService.setDashboardDefaults(testDashboard)
            verifyDefaultProperties(dashboard, configService.dashboard.properties, ['theme', 'duration'])

            expect(dashboard.theme).toEqual 'aqua'
            expect(dashboard.duration).toEqual 1

        it 'should not modify additional properties', ->
            testDashboard = 
                name: 'testDashboard'
                foo: 'bar'
            dashboard = dashboardService.setDashboardDefaults(testDashboard)
            verifyDefaultProperties(dashboard, configService.dashboard.properties, [])

            expect(dashboard.foo).toEqual 'bar'

        it 'should set page defaults', ->
            testDashboard = 
                name: 'testDashboard'
                pages: [{
                    name: 'page1'
                }]

            dashboard = dashboardService.setDashboardDefaults(testDashboard)
            verifyDefaultProperties(dashboard, configService.dashboard.properties, ['pages'])
            
            _.each dashboard.pages, (page) ->
                verifyDefaultProperties(page, 
                    configService.dashboard.properties.pages.properties, 
                    [], dashboard)

        it 'should set data source defaults', ->
            testDashboard = 
                name: 'testDashboard'
                dataSources: [{
                    name: 'datasource_0'
                    type: 'javascript'
                }, {
                    name: 'datasource_1'
                    type: 'javascript'
                    preload: true
                    deferred: true
                }]

            dashboard = dashboardService.setDashboardDefaults(testDashboard)

            expect(dashboard.dataSources[0].deferred).toBeFalse()
            expect(dashboard.dataSources[0].preload).toBeFalse()
            expect(dashboard.dataSources[1].deferred).toBeTrue()
            expect(dashboard.dataSources[1].preload).toBeTrue()
        
        it 'should set widget defaults', ->
            testDashboard = 
                name: 'testDashboard'
                pages: [{
                    name: 'page1'
                    widgets: [{
                        widget: 'chart'
                        dataSource: 'source'
                    }]
                }]

            dashboard = dashboardService.setDashboardDefaults(testDashboard)
            verifyDefaultProperties(dashboard, configService.dashboard.properties, ['pages'])

            _.each dashboard.pages, (page) ->
                verifyDefaultProperties(page, 
                    configService.dashboard.properties.pages.properties, 
                    ['widgets'],
                    dashboard)

                _.each page.widgets, (widget) ->
                    verifyDefaultProperties(widget, 
                        configService.dashboard.properties.pages.properties.widgets.properties, 
                        [],
                        page)
        
        it 'should inherit defaults', ->
            testDashboard = 
                allowFullscreen: false
                name: 'testDashboard'
                pages: [{
                    name: 'page0'
                    widgets: [{
                        widget: 'chart'
                        dataSource: 'source'
                    }, {
                        widget: 'chart'
                        theme: 'dark'
                    }]
                }, {
                    name: 'page1'
                    allowFullscreen: true
                    theme: 'gto'
                    widgets: [{
                        widget: 'chart'
                        dataSource: 'source'
                    }, {
                        widget: 'chart'
                        allowFullscreen: false
                    }]
                }]
                theme: 'light'

            dashboard = dashboardService.setDashboardDefaults(testDashboard)

            expect(dashboard.pages[0].widgets[0].theme).toEqual 'light'
            expect(dashboard.pages[0].widgets[1].theme).toEqual 'dark'

            expect(dashboard.pages[0].widgets[0].allowFullscreen).toEqual false
            expect(dashboard.pages[0].widgets[1].allowFullscreen).toEqual false
            
            expect(dashboard.pages[1].widgets[0].theme).toEqual 'gto'
            expect(dashboard.pages[1].widgets[1].theme).toEqual 'gto'

            expect(dashboard.pages[1].widgets[0].allowFullscreen).toEqual true
            expect(dashboard.pages[1].widgets[1].allowFullscreen).toEqual false

        it 'should apply default layout', ->
            testDashboard = 
                allowFullscreen: false
                name: 'testDashboard'
                pages: [{
                    name: 'page0'
                }]
                theme: 'light'

            dashboard = dashboardService.setDashboardDefaults(testDashboard)

            expect(dashboard.pages[0].layout.gutter).toEqual configService.dashboard.properties.pages.properties.layout.properties.gutter.default
            expect(dashboard.pages[0].layout.margin).toEqual configService.dashboard.properties.pages.properties.layout.properties.margin.default

    describe 'getThemes', ->
        it 'should return an empty array when there are no themes', ->
            expect(dashboardService.getThemes({})).toEqual []

        it 'should include the dashboard theme', ->
            expect(dashboardService.getThemes({ theme: 'theme1'})).toEqual ['theme1']

        it 'should ignore empty pages', ->
            expect(dashboardService.getThemes({ theme: 'theme1', pages: []})).toEqual ['theme1']

        it 'should ignore pages without themes', ->
            expect(dashboardService.getThemes({ theme: 'theme1', pages: [{ name: 'page1' }] })).toEqual ['theme1']

        it 'should include page themes', ->
            expect(dashboardService.getThemes({ theme: 'theme1', pages: [{ theme: 'theme2' }, { name: 'page2' }] })).toEqual ['theme1', 'theme2']
        
        it 'should include page themes when there is no dashboard theme', ->
            expect(dashboardService.getThemes({ pages: [{ theme: 'theme2' }] })).toEqual ['theme2']
        
        it 'should include multiple page themes', ->
            expect(dashboardService.getThemes({ theme: 'theme1', pages: [{ theme: 'theme2' }, { theme: 'theme3' }] })).toEqual ['theme1', 'theme2', 'theme3']
        
        it 'should exclude duplicate themes', ->
            expect(dashboardService.getThemes({ theme: 'theme1', pages: [{ theme: 'theme1' }, { theme: 'theme3' }] })).toEqual ['theme1', 'theme3']
        
        it 'should include widget themes', ->
            expect(dashboardService.getThemes({ theme: 'theme1', pages: [{ theme: 'theme2', widgets: [{ theme: 'theme3' }] }, { name: 'page2', widgets: [{ theme: 'theme4' }, {}]}]})).toEqual ['theme1', 'theme2', 'theme3', 'theme4']

    describe 'getPageName', ->
        it 'should work if page is null', ->
            expect(dashboardService.getPageName(null, 0)).toBe 'Page 1'
            expect(dashboardService.getPageName(null, 9)).toBe 'Page 10'

        it 'should work if page.name is null', ->
            expect(dashboardService.getPageName({}, 0)).toBe 'Page 1'
            expect(dashboardService.getPageName({}, 8)).toBe 'Page 9'

        it 'should work if page.name is empty', ->
            expect(dashboardService.getPageName({ name: '' }, 0)).toBe 'Page 1'
            expect(dashboardService.getPageName({ name: '' }, 8)).toBe 'Page 9'

        it 'should work if page.name is not null', ->
            expect(dashboardService.getPageName({ name: 'abc' }, 0)).toBe 'abc'
            expect(dashboardService.getPageName({ name: 'testpage' }, 1)).toBe 'testpage'

        it 'should support upper case and spaces', ->
            expect(dashboardService.getPageName({ name: 'ABC' }, 0)).toBe 'ABC'
            expect(dashboardService.getPageName({ name: 'Test Page' }, 1)).toBe 'Test Page'
            expect(dashboardService.getPageName({ name: 'Test Page 程文萨' }, 1)).toBe 'Test Page 程文萨'

        it 'should trim spaces', ->
            expect(dashboardService.getPageName({ name: '  ABC' }, 0)).toBe 'ABC'
            expect(dashboardService.getPageName({ name: ' Test Page  ' }, 1)).toBe 'Test Page'
            expect(dashboardService.getPageName({ name: 'Test Page 程文萨   ' }, 1)).toBe 'Test Page 程文萨'
            expect(dashboardService.getPageName({ name: '    ' }, 1)).toBe 'Page 2'
