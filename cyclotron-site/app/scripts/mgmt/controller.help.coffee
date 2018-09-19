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

#
# Help controller -- for viewing help pages
#
cyclotronApp.controller 'HelpController', ($scope, $location, configService) ->

    $scope.config = configService

    $scope.menu = configService.help

    $scope.selectItem = (item) ->
        $scope.selectedItem = item
        $location.search 'q', item.name

    $scope.feelingLucky = ->
        $scope.$broadcast 'feelingLucky'

    $scope.findItem = (name) ->
        $scope.$broadcast 'findItem', { name: name }

    # Initialization
    q = $location.search().q
    if q? then $scope.q = q
