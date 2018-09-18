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

describe 'Unit: _.slugify', ->

    it 'should return undefined if given undefined', ->
        expect(_.slugify(undefined)).toBeUndefined()
    
    it 'should return null if given null', ->
        expect(_.slugify(null)).toBeNull()
    
    it 'should return empty string if given an empty string', ->
        expect(_.slugify('')).toBeEmptyString()
    
    it 'should return an unchanged string if it has no spaces or capital letters', ->
        expect(_.slugify('hello')).toBe 'hello'
    
    it 'should replace spaces with dashes', ->
        expect(_.slugify('hello world')).toBe 'hello-world'
        expect(_.slugify('hello you beautiful world')).toBe 'hello-you-beautiful-world'

    it 'should replace underscores with dashes', ->
        expect(_.slugify('hello world')).toBe 'hello-world'
        expect(_.slugify('hello you beautiful world')).toBe 'hello-you-beautiful-world'

    it 'should replace slashes with dashes', ->
        expect(_.slugify('hello/world')).toBe 'hello-world'
        expect(_.slugify('hello//you-beautiful world/')).toBe 'hello--you-beautiful-world-'

    it 'should replace backslashes with dashes', ->
        expect(_.slugify('hello\\world')).toBe 'hello-world'
        expect(_.slugify('hello\\\\you-beautiful world\\')).toBe 'hello--you-beautiful-world-'

    it 'should replace question marks with dashes', ->
        expect(_.slugify('hello?world')).toBe 'hello-world'
        expect(_.slugify('hello??you-beautiful world?')).toBe 'hello--you-beautiful-world-'

    it 'should replace hashes with dashes', ->
        expect(_.slugify('hello#world')).toBe 'hello-world'
        expect(_.slugify('hello##you-beautiful world#')).toBe 'hello--you-beautiful-world-'

    it 'should replace ampersand with dashes', ->
        expect(_.slugify('hello&world')).toBe 'hello-world'
        expect(_.slugify('hello&&you-beautiful world&')).toBe 'hello--you-beautiful-world-'

    it 'should replace percent with dashes', ->
        expect(_.slugify('hello%world')).toBe 'hello-world'
        expect(_.slugify('hello%%you-beautiful world%')).toBe 'hello--you-beautiful-world-'

    it 'should convert to lowercase', ->
        expect(_.slugify('Hello World')).toBe 'hello-world'

    it 'should trim', ->
        expect(_.slugify('Hello World  ')).toBe 'hello-world'
        expect(_.slugify('  Hello World')).toBe 'hello-world'
        expect(_.slugify('  Hello World  ')).toBe 'hello-world'
