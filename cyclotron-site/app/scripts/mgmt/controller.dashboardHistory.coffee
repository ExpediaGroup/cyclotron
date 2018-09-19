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
# Dashboard History controller
#
cyclotronApp.controller 'DashboardHistoryController', ($scope, $stateParams, $uibModal, dashboardService) ->

    $scope.dashboardName = $stateParams.dashboardName
    $scope.itemsPerPage = 25
    $scope.currentPage = 1


    dashboardService.getDashboard($scope.dashboardName).then (dashboard) ->
        $scope.dashboard = dashboard
    dashboardService.getRevisions($scope.dashboardName).then (revisions) ->
        $scope.revisions = revisions
        $scope.revisionsCount = revisions.length
    
    $scope.diffWithLatest = (rev) ->
        # Diff dialog
        modalInstance = $uibModal.open {
            templateUrl: '/partials/revisionDiff.html'
            size: 'lg'
            scope: $scope
            controller: ['$scope', '$sce', 'rev', ($scope, $sce, rev) ->
                $scope.rev1 = rev - 1
                $scope.rev2 = rev

                $scope.previous = ->
                    $scope.rev2 = $scope.rev1
                    $scope.rev1 = $scope.rev1 - 1
                $scope.next = ->
                    $scope.rev1 = $scope.rev2
                    $scope.rev2 = $scope.rev2 + 1

                $scope.updateDiff = ->
                    dashboardService.getRevisionDiff($scope.dashboardName, $scope.rev1, $scope.rev2).then (diff) ->
                        $scope.diff = $sce.trustAsHtml(diff)

                $scope.updateDiff()

                $scope.$watch 'rev1 + rev2', ->
                    $scope.updateDiff()
            ]
            resolve: {
                rev: -> rev
            }
        }
