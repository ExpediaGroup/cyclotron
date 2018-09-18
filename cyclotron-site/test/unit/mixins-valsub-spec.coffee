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

describe 'Unit: _.valSub', ->
    it 'should return undefined if given undefined', ->
        expect(_.valSub(undefined)).toBeUndefined()
    
    it 'should return null if given null', ->
        expect(_.valSub(null)).toBeNull()
    
    it 'should return the value of the object if null', ->
        expect(_.valSub("string", null)).toBe "string"
    
    it 'should return a number if given a number', ->
        expect(_.valSub(99, {})).toBe 99
    
    it 'should return empty string if given an empty string', ->
        expect(_.valSub('', {})).toBeEmptyString()
    
    it 'should return an unchanged string if it has no #value', ->
        expect(_.valSub('hello', {})).toBe 'hello'
    
    it 'should replace #values at the end of the string', ->
        expect(_.valSub('hello #value', 'Dave')).toBe 'hello Dave'

    it 'should replace #values at the beginning of the string', ->
        expect(_.valSub('#value is great', 'Dave')).toBe 'Dave is great'

    it 'should replace two #values in the string', ->
        expect(_.valSub('#value is #value', 'to be zen')).toBe 'to be zen is to be zen'
    
