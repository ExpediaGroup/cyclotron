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

cyclotronDirectives.directive 'headerParameter', ($window, dashboardService, dataService, logService) ->
    {
        restrict: 'CA'
        scope: 
            dashboard: '='
            parameterDefinition: '='
        replace: true
        templateUrl: '/widgets/header/headerParameter.html'

        controller: ($scope) ->

            originalValue = $window.Cyclotron.parameters[$scope.parameterDefinition.name]

            $scope.parameter = 
                displayName: $scope.parameterDefinition.editing?.displayName || $scope.parameterDefinition.name
                editorType: $scope.parameterDefinition.editing?.editorType
                value: originalValue

            switch $scope.parameter.editorType 
                when 'datetime'
                    $scope.parameter.datetimeOptions =
                        datepicker: true
                        timepicker: true

                    if $scope.parameterDefinition.editing?.datetimeFormat?
                        $scope.parameter.datetimeOptions.datetimeFormat = $scope.parameterDefinition.editing.datetimeFormat
                    else 
                        $scope.parameter.datetimeOptions.datetimeFormat = 'YYYY-MM-DD HH:mm'

                when 'date'
                    $scope.parameter.datetimeOptions =
                        datepicker: true
                        timepicker: false

                    if $scope.parameterDefinition.editing?.datetimeFormat?
                        $scope.parameter.datetimeOptions.datetimeFormat = $scope.parameterDefinition.editing.datetimeFormat
                    else 
                        $scope.parameter.datetimeOptions.datetimeFormat = 'YYYY-MM-DD'

                when 'time'
                    $scope.parameter.datetimeOptions =
                        datepicker: false
                        timepicker: true

                    if $scope.parameterDefinition.editing?.datetimeFormat?
                        $scope.parameter.datetimeOptions.datetimeFormat = $scope.parameterDefinition.editing.datetimeFormat
                    else 
                        $scope.parameter.datetimeOptions.datetimeFormat = 'HH:mm'

            $scope.selectValue = (value) ->
                $scope.parameter.value = value
                $scope.updateParameter()

            $scope.updateParameter = ->
                if not _.isEqual $scope.parameter.value, originalValue
                    $window.Cyclotron.parameters[$scope.parameterDefinition.name] = $scope.parameter.value
                    originalValue = $scope.parameter.value
                    logService.debug 'Header Widget:', 'Updated Parameter [' + $scope.parameterDefinition.name + ']:', $scope.parameter.value

            # Initialize DataSource (optional)
            dsDefinition = dashboardService.getDataSource $scope.dashboard, $scope.parameterDefinition.editing
            $scope.dataSource = dataService.get dsDefinition
            if $scope.dataSource?
                $scope.dataVersion = 0
                $scope.loading = true

                # Data Source (re)loaded
                $scope.$on 'dataSource:' + dsDefinition.name + ':data', (event, eventData) ->
                    return unless eventData.version > $scope.dataVersion
                    $scope.dataVersion = eventData.version
                    $scope.dataSourceData = eventData.data[dsDefinition.resultSet].data
                    $scope.loading = false
                
                # Initialize the Data Source
                $scope.dataSource.init dsDefinition

            return
            
    }
