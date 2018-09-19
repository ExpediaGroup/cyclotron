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

describe 'Unit: _.varSub', ->

    it 'should return undefined if given undefined', ->
        expect(_.varSub(undefined)).toBeUndefined()

    it 'should return null if given null', ->
        expect(_.varSub(null)).toBeNull()

    it 'should return the value of the object if null', ->
        expect(_.varSub("string", null)).toBe 'string'

    it 'should return a number if given a number', ->
        expect(_.varSub(99, {})).toBe 99

    it 'should return empty string if given an empty string', ->
        expect(_.varSub('', {})).toBeEmptyString()
        expect(_.varSub('', {}, true)).toBeEmptyString()

    it 'should return an unchanged string if it has no variables', ->
        expect(_.varSub('hello', {})).toBe 'hello'

    it 'should return an unchanged string if the variable name is not found', ->
        expect(_.varSub('hello #{name}', {number: 99})).toBe 'hello #{name}'

    it 'should return a null if the variable name is not found and missingNull is true', ->
        expect(_.varSub('hello #{name}', {number: 99}, true)).toBe 'hello null'
        expect(_.varSub('#{name}', {number: 99}, true)).toBeNull()

    it 'should return an unchanged string if it has no variables but the object has properties', ->
        expect(_.varSub('hello', {one: "one"})).toBe 'hello'

    it 'should replace variables at the end of the string', ->
        expect(_.varSub('hello #{name}', {name: 'Dave'})).toBe 'hello Dave'

    it 'should replace variables at the beginning of the string', ->
        expect(_.varSub('#{name} is great', {name: 'Dave'})).toBe 'Dave is great'

    it 'should replace two variables in the string', ->
        expect(_.varSub('#{name} is #{adj}', {name: 'Dave', adj: 'funny'})).toBe 'Dave is funny'

    it 'should replace three variables in the string', ->
        expect(_.varSub('#{name} is #{adv} #{adj}!', {name: 'Dave', adj: 'funny', adv: 'very'})).toBe 'Dave is very funny!'

    it 'should replace the entire string with a number', ->
        expect(_.varSub('#{number}', {number: 99})).toBe 99

    it 'should replace the entire string with a boolean', ->
        expect(_.varSub('#{boolean}', {boolean: true})).toBeTrue()

    it 'should format a number if a format string is provided', ->
        expect(_.varSub('#{number|0.0 %}', {number: 0.99})).toBe '99.0 %'

    it 'should format a number if a format string is provided with additional text', ->
        expect(_.varSub('#{number|0.0} bps', {number: 123.456})).toBe '123.5 bps'

    it 'should avoid formatting a number if the format is empty', ->
        expect(_.varSub('#{number|} bps', {number: 123.456})).toBe '123.456 bps'

    it 'should return an unchanged string if the variable name is not found but there is a format code', ->
        expect(_.varSub('#{number|0.0 %}', {})).toBe '#{number|0.0 %}'

    it 'should return an unchanged string if a format string is provided but the value is not a number', ->
        expect(_.varSub('#{number|0.0 %}', {number: 'null'})).toBe 'null'
