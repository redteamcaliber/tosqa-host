ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider.state 'view2',
    url: '/view2'
    templateUrl: 'view2/view.html'
    controller: 'View2Ctrl'
  navbarProvider.add '/view2', 'View2', 12

ng.controller 'View2Ctrl', ($scope, host) ->
  host('view2_next').then (x) ->
    $scope.counter = x

ng.filter 'interpolate', (appInfo) ->
  (text) ->
    String(text).replace '%VERSION%', appInfo.version
