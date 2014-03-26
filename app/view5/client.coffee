ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider, primus) ->
  $stateProvider.state 'view5',
    url: '/view5'
    templateUrl: 'view5/view.html'
    controller: 'View5Ctrl'
  navbarProvider.add '/view5', 'view5', 15


#controller, calls primus.dead only
ng.controller 'View5Ctrl', ($scope, primus, TQ, tqNodes, tqNodeTypes, $timeout, jeebus) ->
  diagram = createDiagramEditor('diagram')

  # TODO

  # # 2. table      {id:<e.g. ssb101>{type:<e.g. "ssb">, name:<e.g. "item">}}
  # # 3. metatable  {table:{id:string: type:string, name:string}}

  # attach /tq/ to 
  $timeout ->
    $scope.nodes = jeebus.attach '/tq/'
  , 100

  # jeebus.attach 'tq/diag'
  # $scope.nodes.rows
  # $scope.nodes.on "data", ()->



  # watch changes in "$scope.nodes"
  $scope.$watch "nodes", ((newValue, oldValue) -> 
    if oldValue? and newValue? and not angular.equals(oldValue, newValue)
      # compare arrays, add or remove when different keys exist
      diff = tqFindDiff(oldValue, newValue)

      if diff.action is "add"
        addItem(diff.key, newValue[diff.key], diagram, tqNodeTypes)
      else if diff.action is "remove"
        diagram.removeNode(diff.key)
  ), true



  $scope.nodeData = [
    ["properties", "-"]
  ];    

  $scope.update = (nodeId) ->
    console.log "info updated for nodeId:" + nodeId
    node = $scope.nodes[nodeId]

    $scope.nodeData = [
      ["properties", nodeId],
      ["title", node.title],
      ["type", node.type],
      ["diagramX", node.diagramX],
      ["diagramY", node.diagramY]
    ];    

  # add wires
  diagram.wireItUp()

  diagram.onMove = (nodeId, x, y, set)->
    # update tqNode with new position 
    $scope.nodes[nodeId].diagramX = x
    $scope.nodes[nodeId].diagramY = y
    console.log nodeId, $scope.nodes[nodeId].title, $scope.nodes[nodeId].diagramX, $scope.nodes[nodeId].diagramY

  
  diagram.onClick = (nodeId)->
    #update infotable with new node data
    $scope.$apply ->
      $scope.update(nodeId)
  
  diagram.onAddWire = (from, to) ->
    console.log 'added', from.node.id, from.name, '>', to.node.id, to.name
    link = from.node.id + from.name + '>' + to.node.id + to.name
    value = {fromId:from.node.id, pad:from.name, toId:to.node.id, topad:to.name}
    data = {prefix:"view5", key:link, value:value}
    primus.write ['saveToStorage', data]

  diagram.onRemoveWire = (from, to) ->
    console.log 'removed', from.node.id, from.name, '>', to.node.id, to.name
    link = from.node.id + from.name + '>' + to.node.id + to.name
    data = {prefix:"view5", key:link}
    primus.write ['saveToStorage', data]

addItem = (id, node, diagram, tqNodeTypes) ->
  console.log "addNode", node.title
  console.log node.type
  prop = tqNodeTypes[node.type]

  diagram.addNode
      id: id
      name: node.title
      # place at default position if not set before
      x: node.diagramX or prop.diagramX
      y: node.diagramY or prop.diagramY
      pads: prop.pads

tqFindDiff = (oldValue, newValue) ->
  array = Object.keys(oldValue)
  remain = array
  returnVal = {key:-1, action:"none"}
  for key in Object.keys(newValue)
    index = array.indexOf(key)
    if index < 0
      console.log "index for", key, "is", index
      console.log oldValue, newValue
      returnVal = {key:key, action:"add"}
    else 
      remain.splice key
  if remain.length is 1
    console.log remain[0]
    returnVal= {key:remain[0], action:"remove"}
  returnVal


