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

describe 'Unit: _.flattenObject', ->

    it 'should return undefined if given undefined', ->
        expect(_.flattenObject(undefined)).toBeUndefined()
    
    it 'should return null if given null', ->
        expect(_.flattenObject(null)).toBeNull()
    
    it 'should return empty string if given an empty string', ->
        expect(_.flattenObject('')).toBeEmptyString()
    
    it 'should return a string if given a string', ->
        expect(_.flattenObject('hello')).toBe 'hello'
    
    it 'should return a number if given a number', ->
        expect(_.flattenObject(42)).toBe 42

    it 'should return an array if given an array', ->
        expect(_.flattenObject([1, 2, 3])).toEqual [1, 2, 3]

    it 'should return an unmodified object if given an object with no nesting', ->
        expect(_.flattenObject({ a: 1, b: 2 })).toEqual { a: 1, b: 2 }

    it 'should return an unmodified object if given an object with no nesting, including arrays', ->
        expect(_.flattenObject({ a: 1, b: 2, c: [7, 8, 9] })).toEqual { a: 1, b: 2, c: [7, 8, 9] }

    it 'should flatten one level of objects', ->
        expect(_.flattenObject({ a: 1, b: "x", c: { q: true, r: false }})).toEqual { a: 1, b: 'x', q: true, r: false }

    it 'should flatten one level of two objects', ->
        expect(_.flattenObject({ a: { x: 1 }, b: { q: true, r: false }})).toEqual { x: 1, q: true, r: false }

    it 'should overwrite repeated keys with subsequent values', ->
        expect(_.flattenObject({ a: { x: 1 }, b: { x: 2 }})).toEqual { x: 2 }

    it 'should flatten two levels of objects', ->
        expect(_.flattenObject({ a: { b: { msg: 'hello'} }})).toEqual { msg: 'hello' }
