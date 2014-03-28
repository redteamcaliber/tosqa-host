ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider.state 'circuits',
    url: '/circuits'
    templateUrl: '/circuits/circuits.html'
    controller: circuitsCtrl
  navbarProvider.add '/circuits', 'Circuits', 30

circuitsCtrl = ($scope, jeebus) ->
  $scope.circuitId = 'def'
  $scope.myData =
    gadgets: [
      { id:'g1', x:750, y:30, title:'Gadget One', type:'Printer' }
      { id:'g2', x:750, y:150, title:'Gadget Two', type:'Pipe' }
    ]
    types:
      Timer:
        pins: [
          { name:'In', type:'i' }
          { name:'Out', type:'o' }
        ]
      Printer:
        pins: [
          { name:'In', type:'i' }
        ]
  
  setup = ->
    jeebus.attach 'circuit'
      .on 'sync', ->
        $scope.circuits = @rows
      
  setup()  if $scope.serverStatus is 'connected'
  $scope.$on 'ws-open', setup
