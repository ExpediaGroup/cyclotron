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

describe 'Unit: _.jsEval', ->

    it 'should return undefined if given undefined', ->
        expect(_.jsEval(undefined)).toBeUndefined()
    
    it 'should return null if given null', ->
        expect(_.jsEval(null)).toBeNull()
    
    it 'should return a number if given a number', ->
        expect(_.jsEval(99, {})).toBe 99
    
    it 'should return a boolean if given a boolean', ->
        expect(_.jsEval(true, {})).toBeTrue()
    
    it 'should return empty string if given an empty string', ->
        expect(_.jsEval('')).toBeEmptyString()
    
    it 'should return a string if given a string', ->
        expect(_.jsEval('"hello there"')).toBe 'hello there'
    
    it 'should perform simple arithmetic', ->
        expect(_.jsEval('1+1')).toBe 2

    it 'should perform string manipulations', ->
        expect(_.jsEval('"abc" + "def"')).toBe 'abcdef'

    it 'should allow moment.js expressions', ->
        expect(_.jsEval('moment.utc([2011, 0, 1, 8]).format("YYYY-MM-DD")')).toBe '2011-01-01'

    it 'should allow javascript functions', ->
        val = _.jsEval('function (a) { return a+1; }')
        expect(val).toBeFunction()

    it 'should allow javascript functions part 2', ->
        val = _.jsEval('result = function (a) { return a+1; }')
        expect(val).toBeFunction()
        expect(val(4)).toBe 5

    it 'should strip trailing semicolons', ->
        val = _.jsEval('result = function (a) { return a+2; };')
        expect(val).toBeFunction()
        expect(val(4)).toBe 6

    it 'should catch exceptions', ->
        str = 'function (a) {'
        val = _.jsEval(str)
        expect(val).toBe('(' + str + ')')
