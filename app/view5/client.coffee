ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider, primus) ->
  $stateProvider.state 'view5',
    url: '/view5'
    templateUrl: 'view5/view.html'
    controller: 'View5Ctrl'
  navbarProvider.add '/view5', 'view5', 15
  
  primus.live = (scope, prefix, adjust) ->
    table = []
    primus.write ['live', prefix]

    #function called at server side to update client         
    scope.$on "live.#{prefix}", (event, type, value) ->
      switch type
        when 'put'
          key = value.key
          value = {key:key, value:value.value}
          console.log "updated: " + key
         
        when 'del'
          key = value.key
          value = {key:key, value:null}
          console.log "deleted: " + key 
        else
          return

      adjust? value  if value?
# # 
      # for row, index in table 
      #   if row.key is key
      #     if value?
      #       table[index] = value
      #     else
      #       # table.splice index, 1
      #     return
      
      table.push value
      
    table


#controller, calls primus.dead only
ng.controller 'View5Ctrl', ($scope, primus, host) ->
  
  diagram = createDiagramEditor('diagram')
  diagram_nodes = []
  
  $scope.view5 = primus.live $scope, 'view5', (table)->
    
    node = table.value
    console.log node

    $scope.nodeData = [
      ["properties", "-"]
    ];    

    # if diagram does not contain node with this id then
    if diagram.nodes[table.key]?
      console.log "key exists"
      if table.value isnt null
        console.log "new properties"
        console.log diagram.nodes[table.key]
        diagram.nodes[table.key].x = 60
        # console.log diagram.node[table.key]

      else 
        # if key is removed then remove Node
        console.log "remove node:" + table.key
        diagram.removeNode table.key
        
    else
      if node? and node.name?
        console.info "add node:" + table.key
        addItem(diagram, table, node )

      #updates infotable with new node data
    $scope.update = (nodeId) ->
      console.log "info updated for nodeId:" + nodeId
      $scope.nodeData = [
        ["properties", nodeId],
        ["temp", 50],
        ["STEP", 200],
        ["value", 63]
      ];        
   
      
  diagram.wireItUp()

  
  diagram.onClick = (nodeId)->
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



addItem = (diagram, table, node) ->
  if node.type is 'motor'
     diagram.addNode
      id: table.key
      name: node.name
      x: 400 
      y: node.y or 50
      pads:
        'frequency': {}
        'timbre': {}
        'modulation': {}
        # 'waveform':
          # wires:
            # 3: ['inmix']
  
  if node.type is 'host'
     diagram.addNode
      id: table.key
      name: node.name + '(HOST)'
      x: 200 
      y: node.y or 50
      pads:
        'in1': {}
        'in2': {}
        'x':
          wires:
            10: ['']
        'y':
          wires:
            10: ['']
        'z':
          wires:
            10: ['']
        'r':
          wires:
            10: ['']            
  
  if node.type is 'sensor'            
     diagram.addNode
      id: table.key
      name: node.name
      x: 50 
      y: node.y or 50
      pads:
        'out':
          wires:
            10: ['']       


