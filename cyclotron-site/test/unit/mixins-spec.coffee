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

# jasmine specs for Mixins go here */

describe 'Unit: _.false', ->

    it 'should return false', ->
        expect(_.false()).toBeFalse()


describe 'Unit: _.isNullOrUndefined', ->

    it 'should return true for undefined', ->
        expect(_.isNullOrUndefined(undefined)).toBeTrue()

    it 'should return true for null', ->
        expect(_.isNullOrUndefined(null)).toBeTrue()

    it 'should return false for an object', ->
        expect(_.isNullOrUndefined(new Object())).toBeFalse()

    it 'should return false for a number', ->
        expect(_.isNullOrUndefined(99)).toBeFalse()

describe 'Unit: _.regexIndexOf', ->

    it 'should return -1 if the regex cannot be found', ->
        expect(_.regexIndexOf('a string', /regex/, 0)).toBe -1

    it 'should return the location of a match at the start', ->
        expect(_.regexIndexOf('Mr. Smith', /Mr./, 0)).toBe 0

    it 'should allow startpos to be optional', ->
        expect(_.regexIndexOf('Mr. Smith', /Mr./)).toBe 0

    it 'should return the location of a match at the end', ->
        expect(_.regexIndexOf('Mr. Smith Jr.', /Jr./)).toBe 10

    it 'should return the location of a match in the middle', ->
        expect(_.regexIndexOf('405 Parc Ave Apt 445, Seattle', /Apt \d+/)).toBe 13

    it 'should return the location of the first match of multiple', ->
        expect(_.regexIndexOf('450 NE 445 SE 304.3 SW 33 NW', /[A-Z]{2}/)).toBe 4

    it 'should return the location of the first match of multiple afte the startpos', ->
        expect(_.regexIndexOf('450 NE 445 SE 304.3 SW 33 NW', /[A-Z]{2}/, 6)).toBe 11

describe 'Unit: _.titleCase', ->

    it 'should return null if given null', ->
        expect(_.titleCase(null)).toBeNull()

    it 'should return undefined if given undefined', ->
        expect(_.titleCase(undefined)).toBeUndefined()

    it 'should return empty string if given an empty string', ->
        expect(_.titleCase('')).toBeEmptyString()

    it 'should capitalize the first letter of a single word', ->
        expect(_.titleCase('gyro')).toBe 'Gyro'

    it 'should capitalize the first letter of each word', ->
        expect(_.titleCase('gyro sandwich')).toBe 'Gyro Sandwich'

    it 'should ignore the case of the rest of the word', ->
        expect(_.titleCase('GYRO SANDWICH')).toBe 'GYRO SANDWICH'
        expect(_.titleCase('Expedia EU')).toBe 'Expedia EU'

describe 'Unit: _.fromCamelCase', ->

    it 'should return null if given null', ->
        expect(_.fromCamelCase(null)).toBeNull()

    it 'should return undefined if given undefined', ->
        expect(_.fromCamelCase(undefined)).toBeUndefined()

    it 'should return empty string if given an empty string', ->
        expect(_.fromCamelCase('')).toBeEmptyString()

    it 'should capitalize the first letter of a single word', ->
        expect(_.fromCamelCase('gyro')).toBe 'Gyro'

    it 'should capitalize the first letter of each word', ->
        expect(_.fromCamelCase('gyro sandwich')).toBe 'Gyro Sandwich'

    it 'should split multiple words camel-cased together', ->
        expect(_.fromCamelCase('gyroSandwich')).toBe 'Gyro Sandwich'
        expect(_.fromCamelCase('tastyGyroSandwich')).toBe 'Tasty Gyro Sandwich'
        expect(_.fromCamelCase('5tastyGyroSandwiches')).toBe '5 Tasty Gyro Sandwiches'

    it 'should operate on multiple camel-case words', ->
        expect(_.fromCamelCase('mochaLatte & gyroSandwich')).toBe 'Mocha Latte & Gyro Sandwich'

describe 'Unit: _.replaceInside', ->

    it 'should do nothing if given null', ->
        expect(_.replaceInside(null, null)).toEqual null

        original = {x: 1}
        expect(_.replaceInside(original, null)).toEqual null
        expect(original).toEqual original

    it 'should return empty object if given that', ->
        original = {}
        expect(_.replaceInside(original, {})).toEqual {}
        expect(original).toEqual {}

    it 'should replace an object with an empty object', ->
        original = {x: 1}
        expect(_.replaceInside(original, {})).toEqual {}
        expect(original).toEqual {}

    it 'should return the replacement object if original is null', ->
        original = null
        expect(_.replaceInside(original, {a: 1, b: 2})).toEqual {a: 1, b: 2}
        expect(original).toEqual null

    it 'should replace all keys of the original', ->
        original = {c: 5, d: 6, e: 8}
        expect(_.replaceInside(original, {a: 1, b: 2})).toEqual {a: 1, b: 2}
        expect(original).toEqual {a: 1, b: 2}

    it 'should replace with nested objects', ->
        original = {widget: [{id: 1}]}
        expect(_.replaceInside(original, {pages: [{duration: 40}]})).toEqual {pages: [{duration: 40}]}
        expect(original).toEqual {pages: [{duration: 40}]}

describe 'Unit: _.numeralformat', ->

    it 'should return null if given null', ->
        expect(_.numeralformat('0.0', null)).toBeNull()

    it 'should return null if given undefined', ->
        expect(_.numeralformat('0.0', undefined)).toBeNull()

    it 'should return the number if format is null', ->
        expect(_.numeralformat(null, 20.20512)).toBe 20.20512

    it 'should return the number if format is empty', ->
        expect(_.numeralformat('', 20.20512)).toBe 20.20512

    it 'should return NaN if number is NaN', ->
        expect(_.numeralformat('0.0', 0/0)).toBe 'NaN'

    it 'should apply format correctly', ->
        expect(_.numeralformat('0.0', 20.20512)).toBe '20.2'

    it 'should apply format correctly to strings', ->
        expect(_.numeralformat('0,0.0', '2002.041')).toBe '2,002.0'

    it 'should return the string if a non-numeric string is provided', ->
        expect(_.numeralformat('0,0.0', 'null')).toBe 'null'

describe 'Unit: _.ngApply', ->
    actual = null
    mockScope = {
        $apply: (f) ->
            actual = f()
            return 1
    }
    mockFunction = -> 2

    it 'should call $apply on the scope and pass the function', ->
        x = _.ngApply(mockScope, mockFunction)()
        expect(x).toBe 1
        expect(actual).toBe 2

describe 'Unit: _.ngNonPropagatingHandler', ->
    oracle = { a: 0, b: 0, c: 0 }

    mockScope = {
        $apply: (f) ->
            actual = f()
            return 1
    }

    mockFunctionA = -> 
        oracle.a = 1
    mockFunctionB = -> 
        oracle.b = 2
        return true
    mockFunctionC = -> 
        oracle.c = 3
        return 'OK'

    it 'should return a function', ->
        a = _.ngNonPropagatingHandler(mockScope, mockFunctionA)
        expect(a).toBeFunction()

    it 'should call the function A and return false', ->
        a = _.ngNonPropagatingHandler(mockScope, mockFunctionA)()
        expect(a).toBeFalse()
        expect(oracle.a).toBe 1

    it 'should call the function B and return false', ->
        b = _.ngNonPropagatingHandler(mockScope, mockFunctionB)()
        expect(b).toBeFalse()
        expect(oracle.b).toBe 2

    it 'should call the function C and return false', ->
        c = _.ngNonPropagatingHandler(mockScope, mockFunctionC)()
        expect(c).toBeFalse()
        expect(oracle.c).toBe 3
