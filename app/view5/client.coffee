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
  diagram_nodes = []
  
  $timeout ->
    $scope.admin = jeebus.attach '/admin/'
    $scope.$on '$destroy', -> jeebus.detach '/admin/'
  , 100


  # attach /tq/ to 
  $timeout ->
    $scope.nodes = jeebus.attach '/tq/'
  , 100


  $scope.nodeData = [
    ["properties", "-"]
  ];    

  $scope.update = (nodeId) ->
    console.log "info updated for nodeId:" + nodeId
    node = tqNodes[nodeId]

    $scope.nodeData = [
      ["properties", nodeId],
      ["title", node.title]
      ["diagramX", node.diagramX],
      ["diagramY", node.diagramY]
    ];    

  # add all nodes in view
  for id in Object.keys(tqNodes)
    node = tqNodes[id]

    addItem(id, node, diagram, tqNodeTypes)
  
  angular.forEach $scope.nodes, () ->
    console.log "this"

  # angular.forEach $scope.nodes, (node) ->
  #     console.log $scope.nodes




  diagram.wireItUp()

  diagram.onMove = (nodeId, x, y, set)->
    # update tqNode with new position 
    tqNodes[nodeId].diagramX = x
    tqNodes[nodeId].diagramY = y
    console.log nodeId, tqNodes[nodeId].title, tqNodes[nodeId].diagramX, tqNodes[nodeId].diagramY

  
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


ng.directive 'highlightOnChange', ($animate) ->
  (scope, elem, attrs) ->
    scope.$watch attrs.highlightOnChange, ->
      $animate.addClass elem, 'highlight', ->
        attrs.$removeClass 'highlight'  



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

       


