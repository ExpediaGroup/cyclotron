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

cyclotronApp.controller 'YoutubeWidget', ($scope, logService) ->
    # Override the widget feature of exporting data, since there is no data
    $scope.widgetContext.allowExport = false
    
    #
    # For reference: https://developers.google.com/youtube/player_parameters
    #
    $scope.getUrl = ->
        widget = _.compile $scope.widget
        return '' unless widget.videoId?

        url = 'http://www.youtube.com/embed'
        properties = []

        ids = widget.videoId.split(',')
        if ids.length > 1
            # Support multiple video IDs
            url = url + '/' + _.first ids
            properties.push 'playlist=' + _.rest(ids).join(',')
        else if widget.videoId.indexOf('PL') == 0
            # If the user puts a playlist ID in the videoID property...
            properties.push 'listType=playlist'
            properties.push 'list=' + widget.videoId
        else if widget.loop != false
            # Workaround to loop a single video
            url = 'http://www.youtube.com/v/' + widget.videoId
            properties.push 'playlist=,'
        else
            url = url + '/' + widget.videoId

        if widget.autoplay != false
            properties.push 'autoplay=1'
        if widget.loop != false
            properties.push 'loop=1'
        if !widget.enableKeyboard
            properties.push 'disablekb=1'
        if !widget.enableControls
            properties.push 'controls=0'
        if widget.showRelated
            properties.push 'rel=1'
        else 
            properties.push 'rel=0'
        if widget.showAnnotations
            properties.push 'iv_load_policy=1'
        else
            properties.push 'iv_load_policy=3'

        if properties.length > 0
            url = url + '?' + properties.join '&'

        logService.debug 'YouTube URL:', url
        return $scope.$sce.trustAsResourceUrl(url)
