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

cyclotronDirectives.directive 'jsContainer', ($interval, configService) ->
    {
        restrict: 'EAC'
        scope:
            jsObject: '='
            data: '='
            refresh: '='

        link: (scope, element, attrs) ->

            $element = $(element)
            $parent = $element.parent()

            intervalPromise = null

            # Resize function
            resize = ->
                parentHeight = $parent.height()

                # Set container height by parents and optional title
                title = $parent.children('h1')
                if (title.length)
                    $element.height(parentHeight - title.height())
                else
                    $element.height(parentHeight)


            # Create JS object and invoke onCreate
            resize()
            if scope.jsObject.onCreate?
                scope.jsObject.onCreate($element, scope.data)

            # Update when data changes
            if scope.jsObject.onData?
                scope.$watch 'data', (data) ->
                    scope.jsObject.onData($element, data)

            # Update on a refresh schedule (independent from data)
            if scope.refresh? and scope.refresh > 0
                # If no 'onRefresh' function is provided, use onData
                eventName = if scope.jsObject.onRefresh? then 'onRefresh' else 'onData'

                if scope.jsObject[eventName]?
                    intervalFn = -> scope.jsObject[eventName]($element, scope.data)
                    intervalPromise = $interval intervalFn, scope.refresh * 1000, 0, false

            # Resize on window resize, and invoke onResize event (if exists)
            resizeEvent = ->
                resize()
                if scope.jsObject.onResize?
                    scope.jsObject.onResize($element, scope.data)

            $parent.resize _.throttle(resizeEvent, 200, { leading: false, trailing: true })

            #
            # Cleanup
            #
            scope.$on '$destroy', ->
                if $container?
                    $container.remove()
                    $container = null

                if intervalPromise?
                    $interval.cancel intervalPromise
                    intervalPromise = null

                $parent.off 'resize'
                $parent.off 'scroll'
                return

            return
    }
