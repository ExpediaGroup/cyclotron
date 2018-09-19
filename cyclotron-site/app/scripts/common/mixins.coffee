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

# Adds custom functions to LoDash (e.g. _.isNullOrUndefined)
# These are available globally.
_.mixin({

    # false: Returns false
    'false': -> false

    # isNullOrUndefined: returns true if the object is either undefined or null
    'isNullOrUndefined': (obj) ->
        return _.isUndefined(obj) || _.isNull(obj)

    # titleCase: converts a string to title casing by 
    # capitalizing the first letter of each word.
    'titleCase': (str) ->
        return str unless str?
        str.replace /\w\S*/g, (txt) -> 
            txt.charAt(0).toUpperCase() + txt.substr(1)

    # fromCamelCase: prettifies a camel case string by adding spaces
    'fromCamelCase': (str) ->
        return str unless str?
        str = str.replace /^[a-z]|[a-z][A-Z]|\s[a-z]|[0-9][a-z]/g, (txt) -> 
            if txt.trim().length == 1 
                txt.toUpperCase()
            else
                txt.charAt(0) + ' ' + txt.charAt(1).toUpperCase()

    # slugify: replaces special characters with dashes, converts to lowercase
    'slugify': (str) ->
        if str?
            str.trim().replace(/[^A-Za-z0-9]/g, '-').toLowerCase()
        else
            str

    # varSub: performs variable subsitution on the given string, using own keys in the
    # given object.
    #
    # Variables are identified in the string using #{key} with case-insensitive matching.
    #
    # This method returns a new string and does not modify the arguments.
    'varSub': (str, varObj, missingNull = false) ->
        # Return unless it is a non-null string
        return str if _.isNullOrUndefined(str) || _.isNullOrUndefined(varObj) || !_.isString(str)

        repl = (str2, format) ->
            if str2 of varObj
                result = varObj[str2]
                if format? then return _.numeralformat(format, result)
                return result
            else if missingNull
                return null
            else 
                # No match, return original string
                if format? & format != ''
                    return '#{' + str2 + '|' + format + '}'
                else 
                    return '#{' + str2 + '}'

        # Replace all #{key} in the string, if the inner key is found in varObj
        # Test for a variable expression that fills the entire string
        wholeMatch = /^\#\{([^}]*?)(\|([^}]*?))?\}$/gi.exec(str)
        if wholeMatch != null
            return repl(wholeMatch[1], wholeMatch[3])
        else
            return str.replace /\#\{(.*?)(\|(.*?))?\}/gi, (all, inner, ignore, format) ->
                return repl(inner, format)

    # valSub: Like varSub, only replaces '#value' with a given value
    'valSub': (str, value) ->
        # Return unless it is a non-null string
        return str if _.isNullOrUndefined(str) || _.isNullOrUndefined(value) || !_.isString(str)
        
        return str.replace /\#value/gi, (all, inner) ->
            value

    # jsEval: evaluates a javascript string and returns the result.
    'jsEval': (str) ->
        return str if _.isNullOrUndefined(str) || !_.isString(str) || str.length == 0

        if str[str.length-1] == ';'
            str = str.substring(0, str.length-1)

        # Wrap in parenthesis to evaluate as an expression
        str = '(' + str + ')'

        try
            # Evaluate the expression and return whatever datatype is produced
            eval(str)
        catch
            console.log('jsEval failure: ' + str)
            return str


    # jsExec: evaluates inline javascript in a string and returns the result.
    # Uses ${} notation to identify inline JS
    'jsExec': (str, context) ->
        return str if _.isNullOrUndefined(str) || !_.isString(str)

        # Test for a javascript expression that fills the entire string
        wholeMatch = /^\$\{((.(?!\$\{))*?)\}$/gi.exec(str)
        if wholeMatch != null
            # Evaluate the expression and return whatever datatype is produced
            return _.jsEval(wholeMatch[1])
        else
            # Replace substring matches of inline JS (as strings)
            return str.replace /\$\{(.*?)\}/gi, (all, inner) ->
                _.jsEval(inner)?.toString()


    # Combines varSub and jsExec into a recursive replacement powerhouse
    # If obj is a string, it will be compiled (variable replacement and inline JS)
    # If obj is an object, its keys will be compiled
    # If recursive is true (default), each obj value will be compiled as well
    # ignoreKeys is an array of keys to ignore, using '.' for recursive descent
    'compile': (obj, varObj = {}, ignoreKeys = [], recursive = true, missingNull = false) ->
        return obj if _.isNullOrUndefined(obj)

        if _.isString obj
            return _.jsExec(_.varSub(obj, varObj, missingNull))

        else if _.isObject obj
            compiledObj = _.cloneDeep obj

            _.forIn compiledObj, (value, key) ->
                # Skip key if set to ignore
                return if _.contains(ignoreKeys, key)

                # Skip compiling objects unless recursive is true
                return if _.isObject(value) && !recursive 

                # Skip functions
                return if _.isFunction(value)

                subIgnoreKeys = _.map ignoreKeys, (ignoreKey) ->
                    return null if ignoreKey.indexOf(key + '.') < 0
                    return ignoreKey.substring(ignoreKey.indexOf('.') + 1)

                # Compile the value
                compiledObj[key] = _.compile(value, varObj, _.compact(subIgnoreKeys), recursive, missingNull)
                return

            return compiledObj
        else
            # Numbers, booleans, non-recursive objects, etc.
            return obj

    # numeralformat: Uses a format string to to reformat a value.
    'numeralformat': (format, value) ->
        return null if _.isNullOrUndefined value
        return value if _.isNullOrUndefined format
        return value if _.isEmpty format
        return 'NaN' if _.isNaN value
        
        if !_.isNumber(value)
            parsedValue = parseFloat(value)
            if _.isNaN parsedValue then return value else value = parsedValue
        return numeral(value).format(format)

    # ngApply: Takes a scope and a function, and returns a function that calls $apply around the given function
    'ngApply': (scope, f) ->
        return -> scope.$apply -> f()

    # Angular-aware event handler that returns false to avoid propagation up the DOM
    'ngNonPropagatingHandler': ($scope, fn) ->
        _.compose(_.false, _.ngApply($scope, fn))

    # regexIndexOf: String indexOf(), except finds the first index of a regex match
    'regexIndexOf': (string, regex, startpos) ->
        indexOf = string.substring(startpos || 0).search(regex)
        return if (indexOf >= 0) then (indexOf + (startpos || 0)) else indexOf

    # executeFunctionByName: given a function e.g. "Cyclotron.pages.go", 
    # invokes the function by splitting the namespaces.  Accepts a context.
    # Any args provided after context are passed to the function.
    'executeFunctionByName': (functionName, context) ->
        return undefined if _.isNullOrUndefined(functionName) || _.isNullOrUndefined(context)

        args = Array.prototype.slice.call(arguments, 2)
        namespaces = functionName.split(".")
        func = namespaces.pop()
        _.each namespaces, (namespace) ->
            context = context[namespace]

        f = context?[func]
        return undefined if _.isNullOrUndefined(f)

        f.apply(context, args)

    # loadCssFile: Helper that loads a CSS file
    'loadCssFile': (url) ->
        link = document.createElement("link")
        link.type = "text/css"
        link.rel = "stylesheet"
        link.href = url
        document.getElementsByTagName("head")[0].appendChild(link)

    # Replace all keys of an object with those from another object
    'replaceInside': (obj, rep) ->
        return rep unless rep? and obj?

        _.each _.keys(obj), (key) ->
            delete obj[key]

        _.assign obj, rep

    # Flatten nested objects (no arrays)
    'flattenObject': (obj) ->
        return obj unless _.isObject(obj) and not _.isArray(obj)
        newObj = {}
        _.forOwn obj, (value, key) ->
            if _.isObject(value) and not _.isArray(value)
                _.assign newObj, _.flattenObject value
            else
                newObj[key] = value
            return
        newObj
})
