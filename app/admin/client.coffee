ng = angular.module 'myApp'

ng.config ($stateProvider) ->
  $stateProvider.state 'admin',
    url: '/admin'
    templateUrl: 'admin/view.html'
    controller: 'AdminCtrl'

ng.controller 'AdminCtrl', ($scope) ->
  # nothing to do
