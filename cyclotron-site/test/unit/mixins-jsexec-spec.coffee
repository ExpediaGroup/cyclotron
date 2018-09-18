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

describe 'Unit: _.jsExec', ->
    beforeEach ->
        jasmine.addMatchers {
            toBeFunction: ->
                return {
                    compare: (actual) ->
                        return {
                            pass: _.isFunction actual
                        }
                }
        }

    it 'should return undefined if given undefined', ->
        expect(_.jsExec(undefined)).toBeUndefined()
    
    it 'should return null if given null', ->
        expect(_.jsExec(null)).toBeNull()
    
    it 'should return a number if given a number', ->
        expect(_.jsExec(99, {})).toBe 99
    
    it 'should return a boolean if given a boolean', ->
        expect(_.jsExec(true, {})).toBeTrue()
    
    it 'should return empty string if given an empty string', ->
        expect(_.jsExec('', {})).toBeEmptyString()

    it 'should return empty string if given an empty inline JS string', ->
        expect(_.jsExec('hello ${}there', {})).toBe 'hello there'
    
    it 'should return an unchanged string if no inline JS is found', ->
        expect(_.jsExec('hello there')).toBe 'hello there'
    
    it 'should perform simple arithmetic', ->
        expect(_.jsExec('The Answer: ${1+1}')).toBe 'The Answer: 2'
    
    it 'should return booleans', ->
        expect(_.jsExec('The Answer: ${true}')).toBe 'The Answer: true'
    
    it 'should replace the entire string with a boolean', ->
        expect(_.jsExec('${true}')).toBeTrue()
    
    it 'should replace the entire string with a number', ->
        expect(_.jsExec('${99.12}')).toBe 99.12
    
    it 'should replace the entire string with a function', ->
        fn = _.jsExec('${function(){return true;}}')   
        expect(_.isFunction(fn)).toBeTrue()
        expect(fn()).toBeTrue()
    
    it 'should calculate boolean expressions', ->
        expect(_.jsExec('The Answer: ${2+2==4}')).toBe 'The Answer: true'
    
    it 'should perform string manipulations', ->
        expect(_.jsExec('${"foo" + "bar"}')).toBe 'foobar'

    it 'should allow moment.js expressions', ->
        expect(_.jsExec('${moment.utc([2011, 0, 1, 8]).format("YYYY-MM-DD")}')).toBe '2011-01-01'

    it 'should allow javascript functions', ->
        val = _.jsExec('${function (a) { return a+1; }}')
        expect(val).toBeFunction()

    it 'should allow javascript functions defined as variables', ->
        val = _.jsExec('${fn = function (a) { return a+1; }}')
        expect(val).toBeFunction()
        expect(val(4)).toBe 5

    it 'should allow self-executing functions', ->
        expect(_.jsExec('${function() { var a = 1; return a + 2; }()}')).toBe 3
