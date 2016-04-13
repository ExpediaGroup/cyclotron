###
# Copyright (c) 2013-2016 the original author or authors.
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

cyclotronApp.controller 'QRCodeWidget', ($scope, $location, dashboardService, dataService) ->
    $scope.loading = false
    $scope.dataSourceError = false
    $scope.dataSourceErrorMessage = null

    # Compiles the QR code options
    $scope.compileCode = (row) ->
        if $scope.widget.useUrl == true
            text = $location.absUrl()
        else 
            text = _.compile($scope.widget.text, row)

        $scope.options = {
            text: text
            maxSize: _.compile($scope.widget.maxSize, row)
            colorDark : _.compile($scope.widget.colorDark, row) || '#000000'
            colorLight : _.compile($scope.widget.colorLight, row) || '#ffffff'
        }

    # Load Data Source
    dsDefinition = dashboardService.getDataSource $scope.dashboard, $scope.widget
    $scope.dataSource = dataService.get dsDefinition
    
    # Initialize
    if $scope.dataSource?
        $scope.dataVersion = 0
        $scope.loading = true

        # Data Source (re)loaded
        $scope.$on 'dataSource:' + dsDefinition.name + ':data', (event, eventData) ->
            return unless eventData.version > $scope.dataVersion
            $scope.dataVersion = eventData.version

            $scope.dataSourceError = false
            $scope.dataSourceErrorMessage = null

            data = eventData.data[dsDefinition.resultSet].data
            
            # Filter the data if the widget has "filters"
            if $scope.widget.filters?
                data = dataService.filter(data, $scope.widget.filters)

            # Sort the data if the widget has "sortBy"
            if $scope.widget.sortBy?
                data = dataService.sort(data, $scope.widget.sortBy)

            # Check for no data
            if _.isEmpty(data) && $scope.widget.noData?
                $scope.nodata = _.jsExec($scope.widget.noData)
            else
                $scope.nodata = null
                
                # Compile QR Code with the first row
                $scope.compileCode data[0]

            $scope.loading = false

        # Data Source error
        $scope.$on 'dataSource:' + dsDefinition.name + ':error', (event, data) ->
            $scope.dataSourceError = true
            $scope.dataSourceErrorMessage = data.error
            $scope.nodata = null
            $scope.loading = false

        # Data Source loading
        $scope.$on 'dataSource:' + dsDefinition.name + ':loading', ->
            $scope.loading = true
        
    
        # Initialize the Data Source
        $scope.dataSource.init dsDefinition
    
    else if $scope.widget.useUrl == true
        $scope.$watch (-> $location.absUrl()), ->
            $scope.compileCode {}
    else
        # Compile QR Code options with no data source
        $scope.compileCode {}


