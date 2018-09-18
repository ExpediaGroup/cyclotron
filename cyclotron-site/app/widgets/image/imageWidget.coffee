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

cyclotronApp.controller 'ImageWidget', ($scope, $interval) ->
    # Override the widget feature of exporting data, since there is no data
    $scope.widgetContext.allowExport = false
    
    $scope.duration = $scope.widget.duration * 1000

    $scope.urlIndex = -1

    $scope.loadCurrentImage = ->
        $scope.currentImage = _.compile $scope.widget.images?[$scope.urlIndex]
        if $scope.currentImage.url? and $scope.currentImage.url.indexOf('http') != 0
            $scope.currentImage.url = 'http://' + $scope.currentImage.url

        $scope.link = $scope.currentImage.link

    $scope.linkTarget = ->
        if $scope.dashboard.openLinksInNewWindow == false then '_self' else '_blank'

    $scope.rotate = ->
        $scope.urlIndex = $scope.urlIndex + 1
        if $scope.urlIndex >= $scope.widget.images.length
            $scope.urlIndex = 0

        $scope.loadCurrentImage()

    $scope.rotate()

    # Configure rotation
    if $scope.duration > 0 and $scope.widget.images.length > 1
        $scope.rotateInterval = $interval $scope.rotate, $scope.duration
        
    #
    # Cleanup
    #
    $scope.$on '$destroy', ->
        if $scope.rotateInterval?
            $interval.cancel $scope.rotateInterval
            $scope.rotateInterval = null

