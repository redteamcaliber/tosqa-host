ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider.state 'circuits',
    url: '/circuits'
    templateUrl: '/circuits/circuits.html'
    controller: circuitsCtrl
  navbarProvider.add '/circuits', 'Circuits', 30

circuitsCtrl = ($scope, jeebus) ->
  $scope.gadgets =
    Pipe:
      name: 'Pipeline'
      width: 160
      shade: 'lightyellow'
      icon: '\uf061' # fa-arrow-right
      pins: [
        { name: 'In', dir: 'in' }
        { name: 'Out', dir: 'out' }
      ]
    Printer:
      width: 120
      shade: 'lightblue'
      icon: '\uf02f' # fa-print
      pins: [
        { name: 'In', dir: 'in' }
        { name: 'In2', dir: 'in' }
      ]
      
  $scope.circuit =
    gadgets: [
      { id: 'g1', x: 120, y: 100, title: 'Gadget One', type: 'Printer' }
      { id: 'g2', x: 120, y: 200, title: 'Gadget Two', type: 'Pipe' }
    ]
    wires: [
      { from: 'g2.Out', to: 'g1.In', cap: 0 }
    ]
    feeds:
      'g1.In': [ 'some data', { Tag: 'blah', Msg: 'tagged data' } ]
    labels:
      In: 'g2.In'
      
  $scope.inputPins = []
  for g in $scope.circuit.gadgets
    for p in $scope.gadgets[g.type].pins when p.dir is 'in'
      $scope.inputPins.push "#{g.id}.#{p.name}"
  $scope.inputPins.sort()
  
  $scope.$watch 'addPin', (pin) ->
    if pin
      $scope.circuit.feeds[pin] ?= []
      console.log 'addFeed', pin, $scope.circuit.feeds[pin].length
      $scope.circuit.feeds[pin].push ''
      $scope.addPin = null
    
  $scope.delFeed = (pin, index) ->
    items = $scope.circuit.feeds[pin]
    items.splice index, 1
    delete $scope.circuit.feeds[pin]  if items.length is 0
  
  $scope.$watch 'currSel.id', (x) ->
    console.log 'fix id', x
  $scope.$watch 'currSel.title', (x) ->
    console.log 'fix title', x
    
  # setup = ->
  #   jeebus.attach 'circuit'
  #     .on 'sync', ->
  #       $scope.circuits = @rows
  #     
  # setup()  if $scope.serverStatus is 'connected'
  # $scope.$on 'ws-open', setup
