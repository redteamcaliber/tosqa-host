ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider.state 'circuits',
    url: '/circuits'
    templateUrl: '/circuits/circuits.html'
    controller: circuitsCtrl
  navbarProvider.add '/circuits', 'Circuits', 30

circuitsCtrl = ($scope, jeebus) ->
  
  $scope.circuits ={}
  
  # '#fbea5b'
  # #dacfc0
  # #d8d8d8
  # #d2e38f
  # #757779
  
  
  $scope.gadgets =
    Pipe:
      name: 'Pipeline'
      shade: '#d8d8d8'
      icon: '\uf061' # fa-arrow-right
      inputs: 'In'
      outputs: 'Out'
    Printer:
      shade: '#dacfc0'
      icon: '\uf02f' # fa-print
      inputs: 'In In2'
    clock:
      shade: '#dacfc0'
      icon: '\uf017' # fa-clock-o
      inputs: 'Rate'
      outputs: 'Pulse'
    tosqa_logo:
      shade: '#fbea5b'
      icon: 'TQ' # fa-clock-o
      inputs: 'Rate'
      outputs: 'X Y'
    StepGen:
      shade: '#d2e38f'
      icon: '\uf013' # fa-cog
      inputs: 'Params'
      outputs: 'Out'
    SSB:
      shade: '#fbea5b'
      icon: '\uf0b2' # fa-arrows-alt
      inputs: 'Cmds'
      
  $scope.circuit =
    gadgets:{}
    wires:{}
    feeds:{}
      
  updatePinList = () ->
    $scope.inputPins = []
    for gid, g of $scope.circuit.gadgets
      if ins = $scope.gadgets[g.type].inputs
        for p in ins.split ' '
          $scope.inputPins.push "#{gid}.#{p}"
    $scope.inputPins.sort()
  
  #function to redraw editor
  $scope.redraw =() ->
    console.log 'redraw'
    $scope.circuit =
      gadgets:{}
      wires:{}
      feeds:{}
    jeebus.attach 'circuit/demo1'
     .on 'data', (args...) ->
        temp = @rows
        for obj in temp
          $scope.circuit.gadgets[obj.id] = obj
        for obj in temp
          angular.forEach obj.feed, (v,k)-> 
            $scope.circuit.feeds["#{obj.id}.#{k}"] = v
          angular.forEach obj.wire, (v,k)->
            to = (v.split ".")[0]
            if $scope.circuit.gadgets[to]?
              # TODO:remove wire from db
              $scope.circuit.wires["#{obj.id}.#{k}/#{v}"] = 0

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
    if $scope.currSel and x?
      id = $scope.currSel.id
      obj = $scope.circuit.gadgets[id]
      obj.title = x
      jeebus.put "/circuit/demo1/#{id}", obj
      console.log 'fix title', x
      
  handlers =
    addGadget: (x, y) ->      
      if $scope.newtype? 
        # jeebus.send { cmd: 'ced-ag', obj}
        id= "g" + String Date.now()%1234567
        type = $scope.newtype
        obj = {title:"#{type}", type:$scope.newtype, x:x, y:y}
        jeebus.put "/circuit/demo1/#{id}", obj
        $scope.redraw()          
        
    delGadget: (id) ->
      # jeebus.send { cmd: 'ced-dg', obj, id}      
      jeebus.put "/circuit/demo1/#{id}"  # put nil value to delete id
      $scope.redraw()          
      
    addWire: (from, to) ->   
      #jeebus.send { cmd: 'ced-aw', obj, from, to }
      id = (from.split '.')[0]
      output = (from.split '.')[1]
      obj = $scope.circuit.gadgets[id]
      obj.wire = obj.wire or {}
      obj.wire[output] = to
      jeebus.put "/circuit/demo1/#{id}", obj 
      $scope.redraw()
    delWire: (from, to) ->    #jeebus.send { cmd: 'ced-dw', obj, from, to }
      id = (from.split '.')[0]
      pin = (from.split '.')[1]
      obj = $scope.circuit.gadgets[id]
      delete obj.wire[pin]
      jeebus.put "/circuit/demo1/#{id}", obj
      $scope.redraw()
    selWire: (from, to) ->    #jeebus.send { cmd: 'ced-dw', obj, from, to }
      $scope.currSel ={}
      $scope.currSel.id = "#{from}/#{to}"
      $scope.currSel.title = null
      $scope.currSel.type = "wire" #$scope.circuit.gadgets[id].type
    selectGadget: (id) ->     #jeebus.send { cmd: 'ced-sg', obj, id       }
      $scope.currSel ={}
      $scope.currSel.id = id
      $scope.currSel.title = $scope.circuit.gadgets[id].title
      $scope.currSel.type = $scope.circuit.gadgets[id].type
      
    moveGadget: (id, x, y) -> #jeebus.send { cmd: 'ced-mg', obj, id, x, y }
      obj = $scope.circuit.gadgets[id]
      obj.x = x
      obj.y = y
      jeebus.put "/circuit/demo1/#{id}", obj
      $scope.redraw()          
      


  $scope.$on 'circuit', (event, type, args...) ->
    console.log 'C:', type, args...
    handlers[type] args...
    
  
    
  setup = ->
    jeebus.attach 'circuit/demo1'
     .on 'sync', (args...) ->
        temp = @rows
        for obj in temp
          $scope.circuits[obj.id] = obj
        console.log "init circuits"
     # .on 'data', (args...) ->
     #    console.log 111, args
     $scope.redraw()
    
        #1. TODO: check for value, else remove
        #2. add to circuits
        # $scope.circuits push k, v
        #3. tell editor
    # jeebus.attach 'demo'
    #  .on 'data', (args...) ->
    #     console.log 'data-tim', args
      

  setup()  if $scope.serverStatus is 'connected'
  $scope.$on 'ws-open', setup
