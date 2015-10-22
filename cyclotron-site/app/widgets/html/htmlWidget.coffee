###
# Copyright (c) 2013-2015 the original author or authors.
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
# Html Widget
#
# Displays raw HTML, optionally repeating over a Data Source.
# Options:
# {
#     <See help>
# }
#
# If the Data Source is not used, the HTML will be output once.  If it is provided, the 
# html property is treated as a repeater, while the preHtml and postHtml are rendered only once.
#
# Title is optional, but can be used to give the same style title as other widgets.

cyclotronApp.controller 'HtmlWidget', ($scope, dashboardService, dataService) ->

    $scope.loading = false
    $scope.htmlStrings = []

    $scope.widgetTitle = -> _.jsExec($scope.widget.title)

    if $scope.widget.preHtml?
        $scope.preHtml = _.jsExec $scope.widget.preHtml

    if $scope.widget.postHtml?
        $scope.postHtml = _.jsExec $scope.widget.postHtml

    $scope.loadData = ->
        $scope.loading = true
        $scope.dataSourceError = false
        $scope.dataSourceErrorMessage = null

        # Load data source
        dsDefinition = dashboardService.getDataSource($scope.dashboard, $scope.widget)
        $scope.dataSource = dataService.get(dsDefinition)
        $scope.loading = true

        # Load data from the data source
        $scope.dataSource.getData dsDefinition, (data, headers, isUpdate) ->

            $scope.dataSourceError = false
            $scope.dataSourceErrorMessage = null

            # Filter the data if the widget has filters
            if $scope.widget.filters?
                data = dataService.filter(data, $scope.widget.filters)

            # Sort the data if the widget has sortBy
            if $scope.widget.sortBy?
                data = dataService.sort(data, $scope.widget.sortBy)

            # Check for no Data
            if _.isEmpty(data) && $scope.widget.noData?
                $scope.nodata = _.jsExec($scope.widget.noData)
                $scope.htmlStrings = []
            else
                $scope.nodata = null

                dataCopy = _.cloneDeep data
                _.each dataCopy, (row, index) -> row.__index = index

                # Compile HTML template with rows
                $scope.htmlStrings = _.map dataCopy, _.partial(_.compile, $scope.widget.html)

                if $scope.preHtml?
                    $scope.htmlStrings.unshift $scope.preHtml
                if $scope.postHtml?
                    $scope.htmlStrings.push $scope.postHtml


            $scope.loading = false

        , (errorMessage, status) ->
            # Error callback
            $scope.loading = false
            $scope.dataSourceError = true
            $scope.dataSourceErrorMessage = errorMessage
            $scope.nodata = null
            $scope.htmlStrings = []
        , ->
            # Loading callback
            $scope.loading = true

    $scope.reload = ->
        $scope.dataSource.execute(true)

    # Data Source - Repeater mode
    if $scope.widget.dataSource?
        $scope.loadData()

    # No Data Source
    else if $scope.widget.html?
        $scope.htmlStrings.push $scope.preHtml if $scope.preHtml?
        $scope.htmlStrings.push _.jsExec $scope.widget.html
        $scope.htmlStrings.push $scope.postHtml if $scope.postHtml?
