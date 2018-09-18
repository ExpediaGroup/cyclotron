###
# Copyright (c) 2016-2018 the original author or authors.
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

#
# Listens for focus events and sets focuses on a particular element
# For use with the focusService
#
cyclotronDirectives.directive 'focusOn', -> 
    {
        restrict: 'AC',
        link: (scope, element, attrs) ->
            scope.$on 'focusOn', (event, name) -> 
                element[0].focus() if attrs.focusOn == name
    }
