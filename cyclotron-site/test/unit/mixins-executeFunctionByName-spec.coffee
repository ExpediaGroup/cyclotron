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

describe 'Unit: _.executeFunctionByName', ->

    it 'should return undefined for undefined', ->
        expect(_.executeFunctionByName(undefined, this)).toBeUndefined()

    it 'should return undefined for null', ->
        expect(_.executeFunctionByName(null, this)).toBeUndefined()

    it 'should return undefined for an empty string', ->
        expect(_.executeFunctionByName('', this)).toBeUndefined()

    it 'should return undefined for a null context', ->
        expect(_.executeFunctionByName('test', null)).toBeUndefined()

    it 'should return the value of a function with no namespace', ->
        expect(_.executeFunctionByName('f', { f: -> 10 })).toBe 10

    it 'should return the value of a function with one namespace', ->
        expect(_.executeFunctionByName('f.g', { f: { g: -> 10 } })).toBe 10

    it 'should return the value of a function with two namespaces', ->
        expect(_.executeFunctionByName('f.g.h', { f: { g: { h: -> 10 } } })).toBe 10

    it 'should return undefined if the function does not exist', ->
        expect(_.executeFunctionByName('f.g.x', { f: { g: { h: -> 10 } } })).toBeUndefined()

    it 'should return undefined if a namespace does not exist', ->
        expect(_.executeFunctionByName('f.x.h', { f: { g: { h: -> 10 } } })).toBeUndefined()

    it 'should return the value of a function with arguments', ->
        expect(_.executeFunctionByName('f.g', { f: { g: (x) -> x * 2 } }, 5)).toBe 10

    it 'should return the value of a function with arguments', ->
        context = { math: { sum: (a, b) -> a + b } }
        expect(_.executeFunctionByName('math.sum', context, 15, 5)).toBe 20
