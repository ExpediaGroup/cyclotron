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

describe 'Unit: dataService', ->

    defaultConfigService = null

    ds1 = [{x: 1, y: 5},
           {x: 2, y: 2},
           {x: 5, y: 1},
           {x: 3, y: 3},
           {x: 4, y: 4}]

    ds2 = [{y: 0},
           {x: 'a', y: 1},
           {x: 'aa', y: 2},
           {x: 'ab', y: 3},
           {x: null, y: 4},
           {x: 'bc', y: 5},
           {x: 'abc', y: 6}]

    ds3 = [{x: 1, y: 2},
           {x: 1, y: 1},
           {x: 3, y: 1},
           {x: 2, y: 3},
           {x: 2, y: 2}]

    ds4 = [{x: true, y: 1},
           {x: true, y: 2},
           {x: false, y: 3},
           {x: false, y: 4},
           {x: true, y: 5}]

    beforeEach ->
        module 'cyclotronApp'
        module 'cyclotronApp.services'

        inject (configService) ->
            defaultConfigService = configService

    describe 'filter', ->
        it 'should return null if data is null', inject (dataService) ->
            expect(dataService.filter(null, {})).toEqual null

        it 'should return data if filters are null', inject (dataService) ->
            expect(dataService.filter(ds1, null)).toEqual ds1

        it 'should return data if filters are empty', inject (dataService) ->
            expect(dataService.filter(ds1, {})).toEqual ds1

        it 'should return data if data is object', inject (dataService) ->
            obj = { a: 1, b: 2, c: 3 }
            expect(dataService.filter(obj, {x: 'zz'})).toEqual obj

        it 'should return no rows if filter does not match', inject (dataService) ->
            expect(dataService.filter(ds1, {x: 'zz'})).toEqual []

        it 'should return matching rows for one filter', inject (dataService) ->
            expect(dataService.filter(ds1, {x: 1})).toEqual [{x: 1, y: 5}]

        it 'should return matching rows for two filters', inject (dataService) ->
            expect(dataService.filter(ds1, {x: 4, y: 4})).toEqual [{x: 4, y: 4}]

        it 'should return no rows for two filters that do not match', inject (dataService) ->
            expect(dataService.filter(ds1, {x: 1, y: 1})).toEqual []

        it 'should return matching rows for array filter', inject (dataService) ->
            expect(dataService.filter(ds1, {x: [1, 2]})).toEqual [{x: 1, y: 5},
                                                                  {x: 2, y: 2}]

        it 'should return matching rows for multiple array filters', inject (dataService) ->
            expect(dataService.filter(ds1, {x: [1, 2, 3], y: [2, 3, 4]})).toEqual [{x: 2, y: 2},
                                                                                   {x: 3, y: 3}]

        it 'should return matching rows for a string filter', inject (dataService) ->
            expect(dataService.filter(ds2, {x: 'abc'})).toEqual [{x: 'abc', y: 6}]

        it 'should exclude rows with nulls for a wildcard filter', inject (dataService) ->
            expect(dataService.filter(ds2, {x: '*'})).toEqual [{x: 'a', y: 1},
                                                               {x: 'aa', y: 2},
                                                               {x: 'ab', y: 3},
                                                               {x: 'bc', y: 5},
                                                               {x: 'abc', y: 6}]

        it 'should exclude rows with nulls for a wildcard filter in an array', inject (dataService) ->
            expect(dataService.filter(ds2, {x: ['*']})).toEqual [{x: 'a', y: 1},
                                                                 {x: 'aa', y: 2},
                                                                 {x: 'ab', y: 3},
                                                                 {x: 'bc', y: 5},
                                                                 {x: 'abc', y: 6}]

        it 'should exclude rows with nulls for a regex wildcard filter', inject (dataService) ->
            expect(dataService.filter(ds2, {x: '/.+/'})).toEqual [{x: 'a', y: 1},
                                                                  {x: 'aa', y: 2},
                                                                  {x: 'ab', y: 3},
                                                                  {x: 'bc', y: 5},
                                                                  {x: 'abc', y: 6}]

        it 'should return matching rows for a regex filter', inject (dataService) ->
            expect(dataService.filter(ds2, {x: '/^a+$/'})).toEqual [{x: 'a', y: 1},
                                                                    {x: 'aa', y: 2}]

            expect(dataService.filter(ds2, {x: '/^a+.*$/'})).toEqual [{x: 'a', y: 1},
                                                                      {x: 'aa', y: 2},
                                                                      {x: 'ab', y: 3},
                                                                      {x: 'abc', y: 6}]

            expect(dataService.filter(ds2, {x: '/b/'})).toEqual [{x: 'ab', y: 3},
                                                                 {x: 'bc', y: 5},
                                                                 {x: 'abc', y: 6}]

            expect(dataService.filter(ds2, {x: '/bc/'})).toEqual [{x: 'bc', y: 5},
                                                                  {x: 'abc', y: 6}]

        it 'should return matching rows for an array of regex filters', inject (dataService) ->
            expect(dataService.filter(ds2, {x: ['/^a+$/', '/^b/']})).toEqual [{x: 'a', y: 1},
                                                                              {x: 'aa', y: 2},
                                                                              {x: 'bc', y: 5}]

        it 'should return matching rows for regex filter and string filter', inject (dataService) ->
            expect(dataService.filter(ds2, {x: '/^a+$/', y: 2})).toEqual [{x: 'aa', y: 2}]

        it 'should return no rows for three filters that do not match, including regex', inject (dataService) ->
            expect(dataService.filter(ds2, {x: '/[ab]/', y: 2, z: 'zz'})).toEqual []

        it 'should return matching rows for redundant filters', inject (dataService) ->
            expect(dataService.filter(ds2, {x: '*', x: '/c/'})).toEqual [{x: 'bc', y: 5},
                                                                         {x: 'abc', y: 6}]

    describe 'sort', ->
        it 'should return null if data is null', inject (dataService) ->
            expect(dataService.sort(null, {})).toEqual null

        it 'should return data if sorts are null', inject (dataService) ->
            expect(dataService.sort(ds1, null)).toEqual ds1

        it 'should return data if sorts are empty', inject (dataService) ->
            expect(dataService.sort(ds1, [])).toEqual ds1

        it 'should return data if data is object', inject (dataService) ->
            obj = { a: 1, b: 2, c: 3 }
            expect(dataService.sort(obj, [])).toEqual obj

        it 'should sort ascending by one column', inject (dataService) ->
            expected = [{x: 1, y: 5},
                        {x: 2, y: 2},
                        {x: 3, y: 3},
                        {x: 4, y: 4},
                        {x: 5, y: 1}]

            expect(dataService.sort(ds1, 'x')).toEqual expected
            expect(dataService.sort(ds1, ['x'])).toEqual expected
            expect(dataService.sort(ds1, '+x')).toEqual expected
            expect(dataService.sort(ds1, ['+x'])).toEqual expected

        it 'should sort booleans ascending by one column', inject (dataService) ->
            expected = [{x: true, y: 1},
                        {x: true, y: 2},
                        {x: true, y: 5},
                        {x: false, y: 3},
                        {x: false, y: 4}]

            expect(dataService.sort(ds4, 'x')).toEqual expected

        it 'should sort descending by one column', inject (dataService) ->
            expected = [{x: 5, y: 1},
                        {x: 4, y: 4},
                        {x: 3, y: 3},
                        {x: 2, y: 2},
                        {x: 1, y: 5}]

            expect(dataService.sort(ds1, '-x')).toEqual expected
            expect(dataService.sort(ds1, ['-x'])).toEqual expected

        it 'should sort booleans descending by one column', inject (dataService) ->
            expected = [{x: false, y: 3},
                        {x: false, y: 4},
                        {x: true, y: 1},
                        {x: true, y: 2},
                        {x: true, y: 5}]

            expect(dataService.sort(ds4, '-x')).toEqual expected

        it 'should sort ascending by two columns', inject (dataService) ->
            expected = [{x: 1, y: 1},
                        {x: 1, y: 2},
                        {x: 2, y: 2},
                        {x: 2, y: 3},
                        {x: 3, y: 1}]

            expect(dataService.sort(ds3, ['x', 'y'])).toEqual expected
            expect(dataService.sort(ds3, ['+x', '+y'])).toEqual expected

        it 'should sort ascending then descending', inject (dataService) ->
            expected = [{x: 1, y: 2},
                        {x: 1, y: 1},
                        {x: 2, y: 3},
                        {x: 2, y: 2},
                        {x: 3, y: 1}]

            expect(dataService.sort(ds3, ['x', '-y'])).toEqual expected
            expect(dataService.sort(ds3, ['+x', '-y'])).toEqual expected

        it 'should sort by a function', inject (dataService) ->
            expected = [{x: 5, y: 1},
                        {x: 4, y: 4},
                        {x: 3, y: 3},
                        {x: 2, y: 2},
                        {x: 1, y: 5}]
            sortFunction = (r1, r2, defaultSortFunction) ->
                defaultSortFunction(r1.x, r2.x, false)

            expect(dataService.sort(ds1, sortFunction)).toEqual expected

        it 'should sort by a function v2', inject (dataService) ->
            expected = [{x: 1, y: 1},
                        {x: 1, y: 2},
                        {x: 3, y: 1},
                        {x: 2, y: 2},
                        {x: 2, y: 3}]
            sortFunction = (r1, r2, defaultSortFunction) ->
                defaultSortFunction(r1.x * r1.y, r2.x * r2.y, true)

            expect(dataService.sort(ds3, sortFunction)).toEqual expected

    describe 'parseSortBy', ->
        it 'should parse columns without a direction prefix', inject (dataService) ->
            expect(dataService.parseSortBy('col1')).toEqual { columnName: 'col1', ascending: true }

        it 'should parse columns with an ascending prefix', inject (dataService) ->
            expect(dataService.parseSortBy('+col1')).toEqual { columnName: 'col1', ascending: true }

        it 'should parse columns with a descending prefix', inject (dataService) ->
            expect(dataService.parseSortBy('-col1')).toEqual { columnName: 'col1', ascending: false }

    describe 'defaultSortFunction', ->
        it 'should sort booleans ascending', inject (dataService) ->
            expect(dataService.defaultSortFunction(true, false, true)).toEqual -1
            expect(dataService.defaultSortFunction(true, true, true)).toEqual 0
            expect(dataService.defaultSortFunction(false, true, true)).toEqual 1

        it 'should sort booleans descending', inject (dataService) ->
            expect(dataService.defaultSortFunction(true, false, false)).toEqual 1
            expect(dataService.defaultSortFunction(false, false, false)).toEqual 0
            expect(dataService.defaultSortFunction(false, true, false)).toEqual -1

        it 'should sort numbers ascending', inject (dataService) ->
            expect(dataService.defaultSortFunction(1, 2, true)).toEqual -1
            expect(dataService.defaultSortFunction(1, 1, true)).toEqual 0
            expect(dataService.defaultSortFunction(101, 1, true)).toEqual 100

        it 'should sort numbers descending', inject (dataService) ->
            expect(dataService.defaultSortFunction(1, 2, false)).toEqual 1
            expect(dataService.defaultSortFunction(1, 1, false)).toEqual 0
            expect(dataService.defaultSortFunction(101, 1, false)).toEqual -100

        it 'should sort strings ascending', inject (dataService) ->
            expect(dataService.defaultSortFunction('a', 'b', true)).toEqual -1
            expect(dataService.defaultSortFunction('b', 'b', true)).toEqual 0
            expect(dataService.defaultSortFunction('b', 'a', true)).toEqual 1

        it 'should sort strings descending', inject (dataService) ->
            expect(dataService.defaultSortFunction('a', 'b', false)).toEqual 1
            expect(dataService.defaultSortFunction('b', 'b', false)).toEqual 0
            expect(dataService.defaultSortFunction('b', 'a', false)).toEqual -1

        it 'should sort nulls ascending', inject (dataService) ->
            expect(dataService.defaultSortFunction(null, 'a', true)).toEqual -1
            expect(dataService.defaultSortFunction(null, null, true)).toEqual 0
            expect(dataService.defaultSortFunction('a', null, true)).toEqual 1

        it 'should sort nulls descending', inject (dataService) ->
            expect(dataService.defaultSortFunction(null, 'a', false)).toEqual 1
            expect(dataService.defaultSortFunction(null, null, false)).toEqual 0
            expect(dataService.defaultSortFunction('a', null, false)).toEqual -1
