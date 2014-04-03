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
      shade: 'lightyellow'
      icon: '\uf061' # fa-arrow-right
      inputs: 'In'
      outputs: 'Out'
    Printer:
      shade: 'lightblue'
      icon: '\uf02f' # fa-print
      inputs: 'In In2'
      
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
      
  updatePinList = () ->
    $scope.inputPins = []
    for g in $scope.circuit.gadgets
      if ins = $scope.gadgets[g.type].inputs
        for p in ins?.split(' ') when p.dir is 'in'
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
    console.log 'delFeed', pin, index, items[index]
    items.splice index, 1
    delete $scope.circuit.feeds[pin]  if items.length is 0
  
  $scope.$watch 'currSel.id', (x) ->
    console.log 'fix id', x
    updatePinList() # for new and deleted gadgets
  $scope.$watch 'currSel.title', (x) ->
    console.log 'fix title', x
  
  handlers =
    addGadget: (x, y) ->
    delGadget: (id) ->
    addWire: (from, to) ->
    delWire: (from, to) ->
    selectGadget: (id) ->
    moveGadget: (id, x, y) ->
      
  $scope.$on 'circuit', (event, type, args...) ->
    console.log 'C:', type, args...
    handlers[type] args...
    
  # setup = ->
  #   jeebus.attach 'circuit'
  #     .on 'sync', ->
  #       $scope.circuits = @rows
  #     
  # setup()  if $scope.serverStatus is 'connected'
  # $scope.$on 'ws-open', setup
