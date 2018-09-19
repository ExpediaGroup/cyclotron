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
# Tableau Widget
#
# Displays a tableau dashboard.
#

cyclotronApp.controller 'TableauWidget', ($scope) ->
    # Override the widget feature of exporting data, since there is no data
    $scope.widgetContext.allowExport = false
    $scope.params = []

    if !_.isUndefined($scope.widget.params)
        $scope.params = _.map _.keys($scope.widget.params), (key) ->
            {
                name: key,
                value: $scope.widget.params[key]
            }
