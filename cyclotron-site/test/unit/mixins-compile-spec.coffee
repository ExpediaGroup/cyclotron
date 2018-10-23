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

describe 'Unit: _.compile', ->

    it 'should return undefined if given undefined', ->
        expect(_.compile(undefined, null)).toBeUndefined()
    
    it 'should return null if given null', ->
        expect(_.compile(null, null)).toBeNull()    

    it 'should return a number if given a number', ->
        expect(_.compile(99, {})).toBe 99

    it 'should return a boolean if given a boolean', ->
        expect(_.compile(true, {})).toBeTrue()

    it 'should return empty string if given an empty string', ->
        expect(_.compile('', {})).toBeEmptyString()

    it 'should return an unchanged string if no inline JS is found', ->
        expect(_.compile('hello there', {})).toBe 'hello there'

    it 'should perform simple JS arithmetic', ->
        expect(_.compile('The Answer: ${1+1}', {})).toBe 'The Answer: 2'

    it 'should return booleans', ->
        expect(_.compile('The Answer: ${true}', {})).toBe 'The Answer: true'

    it 'should replace the entire string with a boolean', ->
        expect(_.compile('${true}', {})).toBeTrue()

    it 'should replace the entire string with a number', ->
        expect(_.compile('${99.12}', {})).toBe 99.12

    it 'should replace the entire string with a function', ->
        fn = _.compile('${function(){return true;}}', {})
        expect(fn).toBeFunction()
        expect(fn()).toBeTrue()
    
    it 'should calculate boolean expressions', ->
        expect(_.compile('The Answer: ${2+2==4}', {})).toBe 'The Answer: true'

    it 'should perform string manipulations', ->
        expect(_.compile('${"foo" + "bar"}', {})).toBe 'foobar'

    it 'should allow moment.js expressions', ->
        expect(_.compile('${moment.utc([2011, 0, 1, 8]).format("YYYY-MM-DD")}', {})).toBe '2011-01-01'

    it 'should return an object unchanged if its keys have no expressions', ->
        obj = 
            a: 'hello'
            b: 'world'

        result = _.compile(obj, {}, ['a'])
        expect(result).toEqual obj

    it 'should evaluate JS in object keys', ->
        obj = 
            a: '${true}'
            b: '${1+2} oranges'

        expected = 
            a: true
            b: '3 oranges'

        result = _.compile(obj, {})
        expect(result).toEqual expected
        expect(obj).not.toEqual expected

    it 'should replace variables in object keys', ->
        vars = 
            v1: 1
            v2: 'oranges'
        obj = 
            a: '\#{v1}'
            b: '${1+1} \#{v2}'

        expected = 
            a: 1
            b: '2 oranges'

        result = _.compile(obj, vars)
        expect(result).toEqual expected
        expect(obj).not.toEqual expected
        
    it 'should ignore variables not found in the varObj', ->
        vars = 
            v1: 1

        obj = 
            a: '\#{v2} ${true}'

        expected = 
            a: '\#{v2} true'

        result = _.compile(obj, vars)
        expect(result).toEqual expected
        expect(obj).not.toEqual expected

    it 'should replace variables not found in the varObj with null', ->
        vars = 
            v1: 1

        obj = 
            a: '\#{v2} ${true}'

        expected = 
            a: 'null true'

        result = _.compile(obj, vars, [], true, true)
        expect(result).toEqual expected

    it 'should ignore keys in ignoreKeys[]', ->
        obj = 
            a: '${true}'
            b: '${1+2} oranges'

        expected = 
            a: '${true}'
            b: '3 oranges'
       
        result = _.compile(obj, {}, ['a'])
        expect(result).toEqual expected

    it 'should keep keys of different types', ->

        fn = (a) -> a + 1

        obj = 
            a: true
            b: '${1+2} oranges'
            c: 99
            d: fn

        expected = 
            a: true
            b: '3 oranges'
            c: 99
            d: fn
       
        result = _.compile(obj, {}, [])
        expect(result).toEqual expected

    it 'should compile recursively', ->
        vals = 
            v1: 5

        obj = 
            a: 
                a1: '${true}'
                a2: '\#{v1}'
            b: '${1+2} oranges'

        expected = 
            a: 
                a1: true
                a2: 5
            b: '3 oranges'
       
        result = _.compile(obj, vals, [], true)
        expect(result).toEqual expected
        expect(obj).not.toEqual expected

    it 'should compile recursively with false values', ->
        vals = 
            v1: 5

        obj = 
            a: false
            b: '${1+2} oranges'

        expected = 
            a: false
            b: '3 oranges'
       
        result = _.compile(obj, vals, [], true)
        expect(result).toEqual expected
        expect(obj).not.toEqual expected

    it 'should ignore keys while compiling recursively', ->
        vals = 
            v1: 5
            v2: 2

        obj = 
            a: 
                a1: '${true}'
                a2: '${\#{v1} + \#{v2}}'
            b: '${1+2} oranges'
            a1: '\#{v3}'

        expected = 
            a: 
                a1: true
                a2: 7
            b: '3 oranges'
            a1: '\#{v3}'
       
        result = _.compile(obj, vals, ['a1'], true)
        expect(result).toEqual expected
        expect(obj).not.toEqual expected

    it 'should ignore keys while compiling recursively with descent', ->
        vals = 
            v1: 5
            v2: 2

        obj = 
            a: 
                a: '${true}'
                b: '${\#{v1} + \#{v2}}'
            b: 
                a: '\#{v3}'
                b: '${1+2} oranges'

        expected = 
            a: 
                a: true
                b: '${\#{v1} + \#{v2}}'
            b: 
                a: '\#{v3}'
                b: '3 oranges'
       
        result = _.compile(obj, vals, ['a.b', 'b.a'], true)
        expect(result).toEqual expected
        expect(obj).not.toEqual expected


    it 'should allow disabling recursion', ->
        vals = 
            v1: 5
            v2: 2

        obj = 
            a: 
                a1: '${true}'
                a2: '${\#{v1} + \#{v2}}'
            b: '${1+2} oranges'
            a1: '\#{v3}'

        expected = 
            a: 
                a1: '${true}'
                a2: '${\#{v1} + \#{v2}}'
            b: '3 oranges'
            a1: '\#{v3}'
       
        result = _.compile(obj, vals, ['c'], false)
        expect(result).toEqual expected

    it 'should return an array unchanged if its items have no expressions', ->
        array = ['hello', 'world']

        result = _.compile array
        expect(result).toEqual array

    it 'should return an empty array', ->
        array = []
        result = _.compile array
        expect(result).toEqual array        

    it 'should evaluate inline javascript in an array', ->
        array = ['hello', '${"world" + "!"}']
        expected = ['hello', 'world!']

        result = _.compile array
        expect(result).toEqual expected

    it 'should compile objects in an array', ->
        array = [{
                a: 'Alpha'
                b: '\#{b}'
            }, 
            '${1+2}', {
                c: ['\#{a}', '${"\#{a}" + "-" + "\#{b}"}']
            }
        ]
        expected = [{a: 'Alpha', b: 'Beta'}, 3, { c: ['Alpha', 'Alpha-Beta']}]

        result = _.compile array, { a: 'Alpha', b: 'Beta' }
        expect(result).toEqual expected
        expect(array).not.toEqual expected

    it 'should compile objects in an array, non-recursively', ->
        array = [{
                a: 'Alpha'
                b: '\#{b}'
            }, 
            '${1+2}', {
                c: ['\#{a}', '${"\#{a}" + "-" + "\#{b}"}']
            }
        ]
        expected = [{
                a: 'Alpha'
                b: '\#{b}'
            }, 
            3, {
                c: ['\#{a}', '${"\#{a}" + "-" + "\#{b}"}']
            }
        ]

        result = _.compile array, { a: 'Alpha', b: 'Beta' }, [], false
        expect(result).toEqual expected

