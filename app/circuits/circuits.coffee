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
      { id:'g1', x:750, y:70, title:'Gadget One', type: 'Printer' }
      { id:'g2', x:800, y:190, title:'Gadget Two', type: 'Pipe' }
    ]
    wires: [
      { from: "g2.Out", to: "g1.In", cap: 0 }
    ]
    feeds:
      "g1.In": [ "some data", "more data" ]
    labels:
      "In": "g1.In"
  
  setup = ->
    jeebus.attach 'circuit'
      .on 'sync', ->
        $scope.circuits = @rows
      
  setup()  if $scope.serverStatus is 'connected'
  $scope.$on 'ws-open', setup
