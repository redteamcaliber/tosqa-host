ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider, primus) ->
  $stateProvider.state 'view1',
    url: '/'
    templateUrl: 'view1/view.html'
    controller: 'View1Ctrl'
  navbarProvider.add '/', 'View1', 11

ng.controller 'View1Ctrl', ->
  # nothing to do
