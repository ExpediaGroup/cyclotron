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

cyclotronDirectives.directive 'fancyImage', ($interval) ->
    {
        restrict: 'A'
        scope:
            image: '='
        link: (scope, element, attrs) ->
            $element = $(element)
            
            scope.$watch 'image', (image) ->

                $element.css {
                    'background-image': 'url(' + image.url + ')'
                    'background-size': image.backgroundSize || 'cover'
                    'background-repeat': image.backgroundRepeat || 'no-repeat'
                    'background-position': image.backgroundPosition || 'center'
                }
                
                if image.backgroundColor?
                    $element.css 'background-color', image.backgroundColor

                if image.filters?
                    $element.css 'filter', image.filters

    }
