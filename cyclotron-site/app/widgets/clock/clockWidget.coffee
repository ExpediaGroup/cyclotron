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
# Clock Widget
#
cyclotronApp.controller 'ClockWidget', ($scope, $interval, configService) ->
    # Override the widget feature of exporting data, since there is no data
    $scope.widgetContext.allowExport = false
    
    $scope.format = configService.widgets.clock.properties.format.default
    $scope.timezone = null

    # Load user-specified format if defined
    if !_.isEmpty($scope.widget.format) 
        $scope.format = _.jsExec $scope.widget.format

    # Load user-specified time-zone if defined
    if !_.isEmpty($scope.widget.timezone) 
        if moment.tz.zone($scope.widget.timezone)
            $scope.timezone = _.jsExec $scope.widget.timezone 
        else
            $scope.widgetContext.dataSourceError = true
            $scope.widgetContext.dataSourceErrorMessage = '"' + _.jsExec $scope.widget.timezone + '" is not a valid time zone'

    # Schedule an update every second
    $scope.updateTime = ->
        temp = moment()
        if $scope.timezone? 
            temp = temp.tz($scope.timezone)
        $scope.currentTime = temp.format $scope.format

    $scope.updateTime()
    $scope.interval = $interval $scope.updateTime, 1000
    
    #
    # Cleanup
    #
    $scope.$on '$destroy', ->
        if $scope.interval?
            $interval.cancel $scope.interval
            $scope.interval = null
