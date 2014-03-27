ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider.state 'circuits',
    url: '/circuits'
    templateUrl: '/circuits/circuits.html'
    controller: circuitsCtrl
  navbarProvider.add '/circuits', 'Circuits', 30

circuitsCtrl = ($scope, jeebus) ->
  drivers = {}
  
  setup = ->
    drivers = jeebus.attach 'circuit'
      .on 'sync', ->
        $scope.circuits = @rows
      
  setup()  if $scope.serverStatus is 'connected'
  $scope.$on 'ws-open', setup
