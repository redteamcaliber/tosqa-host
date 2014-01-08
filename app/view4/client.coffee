ng = angular.module 'myApp'


ng.config ($stateProvider, navbarProvider, primus) ->
  $stateProvider.state 'view4',
    url: '/view4'
    templateUrl: 'view4/view.html'
    controller: 'View4Ctrl'
  navbarProvider.add '/view4', 'View4', 14
  
  primus.save = (scope, data) ->
     primus.write ['save', data]


  primus.getdb = (scope, prefix, adjust) ->
    table = []
    primus.write ['getdb', prefix]

    #function called at server side to update client         
    scope.$on "getdb.#{prefix}", (event, type, value) ->
      switch type
        when 'put'
          key = value.key
          value = {key:key, value:value.value}
          console.log "updated: " + key 
        else
          return
        

      adjust? value  if value?
# 
      for row, index in table 
        if row.key is key
          if value?
            table[index] = value
          else
            # table.splice index, 1
          return
# 
      
      table.push value
      
    table     
     
 
# use buttons to set variable to values
ng.controller 'View4Ctrl', ($scope, primus, host) ->    
    $scope.addValue = (key, value) ->
      
      # make sure entries end up in view 5, by adding a prefix
      prefix = "view5"
      
      data = {prefix:prefix, key:key, value:value}
      $scope.save = primus.save $scope, data
    
    counter = []      
    
    $scope.addNode = (name, type)-> 
      prefix = "view5"
                
      number = counter[type] or 0    
      height = number * 100 + 10
      
      value = '{"name":"'+ name + '","type":"' + type + '", "x":"300","y":"'+ height + '"}'      
      console.info value

      
      data = {prefix:prefix, key:name, value:value}
      $scope.save = primus.save $scope, data
      counter[type] = number+1 
    
    $scope.removeMotor = (name, type)-> 
      prefix = "view5"
                     
      data = {prefix:prefix, key:name, value:null}
      $scope.save = primus.save $scope, data
      counter[type] -= 1
    

    
    #########
    ## modified todolist starts here
    #########
    
    $scope.todos = [
      
    ]
    
    # get existing nodes from db
    $scope.view5 = primus.getdb $scope, 'view5', (table)->
      console.info table.value
      node = JSON.parse table.value
      $scope.todos.push 
        text: node.name
        type: node.type
        done: false
    
    $scope.addTodo = ->
      $scope.todos.push
        text: $scope.todoText
        type: $scope.nodeType
        done: false
      
      name = $scope.todoText
      type = $scope.nodeType
      $scope.addNode(name, type)

      $scope.todoText = ""
      $scope.nodeType = ""

  
    $scope.remaining = ->
      count = 0
      angular.forEach $scope.todos, (todo) ->
        count += (if todo.done then 0 else 1)
  
      count
  
    $scope.archive = ->
      oldTodos = $scope.todos
      $scope.todos = []
      angular.forEach oldTodos, (todo) ->
        if todo.done is false
          $scope.todos.push todo
        else
          $scope.removeMotor(todo.text, todo.type)
            
          
      