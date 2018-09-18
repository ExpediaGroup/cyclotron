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

cyclotronDirectives.directive 'qrcode', ->
    {
        restrict: 'C'
        scope:
            options: '='

        link: (scope, element, attrs) ->
            $element = $(element)
            $widget = $element.parent().parent()

            makeCode = _.throttle ->
                options = _.clone scope.options
                options.correctLevel = QRCode.CorrectLevel.H
                
                size = Math.min $widget.width(), $widget.height()
                if options.maxSize?
                    size = Math.min size, options.maxSize

                options.width = size
                options.height = size
                element.css 'width', size + 'px'
                element.css 'height', size + 'px'
                element.css 'margin-top', ($widget.height() - size) / 2 + 'px'

                element.empty()
                new QRCode(element[0], options)
            , 75

            scope.$watch 'options', (options) ->
                makeCode()

            # Update on window resizing
            resizeFunction = _.debounce makeCode, 100, { leading: false, maxWait: 300 }
            $widget.on 'resize', resizeFunction

            #
            # Cleanup
            #
            scope.$on '$destroy', ->
                $widget.off 'resize', resizeFunction
                return
    }
