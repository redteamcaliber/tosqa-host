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
    StepGen:
      shade: 'lightgreen'
      icon: '\uf013' # fa-cog
      inputs: 'Params'
      outputs: 'Out'
    SSB:
      shade: 'lightgray'
      icon: '\uf0b2' # fa-arrows-alt
      inputs: 'Cmds'
      
  $scope.circuit =
    gadgets:
      g1: { x: 120, y: 220, title: 'Gadget One', type: 'Pipe',    }
      g2: { x: 300, y: 250, title: 'Gadget Two', type: 'Printer', }
      g3: { x: 320, y:  60, title: 'StepGen-X',  type: 'StepGen', }
      g4: { x: 540, y:  70, title: 'SSB-X',      type: 'SSB',     }
      g5: { x: 340, y: 140, title: 'StepGen-Y',  type: 'StepGen', }
      g6: { x: 520, y: 150, title: 'SSB-Y',      type: 'SSB',     }
    wires:
      'g1.Out/g2.In': 0
      'g3.Out/g4.Cmds': 0
      'g5.Out/g6.Cmds': 0
    feeds:
      'g2.In': [ 'some data', { Tag: 'blah', Msg: 'tagged data' } ]
      'g3.Params': [ 1000, 500 ]
      'g5.Params': [ 500, 1000 ]
    labels:
      In: 'g2.In'
      
  updatePinList = () ->
    $scope.inputPins = []
    for gid, g of $scope.circuit.gadgets
      if ins = $scope.gadgets[g.type].inputs
        for p in ins.split ' '
          $scope.inputPins.push "#{gid}.#{p}"
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
    
  obj = 'demo1'
  
  handlers =
    addGadget: (x, y) ->      jeebus.send { cmd: 'ced-ag', obj, x, y     }
    delGadget: (id) ->        jeebus.send { cmd: 'ced-dg', obj, id       }
    addWire: (from, to) ->    jeebus.send { cmd: 'ced-aw', obj, from, to }
    delWire: (from, to) ->    jeebus.send { cmd: 'ced-dw', obj, from, to }
    selectGadget: (id) ->     jeebus.send { cmd: 'ced-sg', obj, id       }
    moveGadget: (id, x, y) -> jeebus.send { cmd: 'ced-mg', obj, id, x, y }

  $scope.$on 'circuit', (event, type, args...) ->
    console.log 'C:', type, args...
    handlers[type] args...
    
  setup = ->
    jeebus.attach 'circuit'
      .on 'sync', ->
        $scope.circuits = @rows
        angular.forEach @rows, (value) ->
          console.log value
      .on 'data', (k,v) ->
        #1. TODO: check for value, else remove
        console.log k, v
        #2. add to circuits
        # $scope.circuits push k, v
        #3. tell editor


  setup()  if $scope.serverStatus is 'connected'
  $scope.$on 'ws-open', setup
