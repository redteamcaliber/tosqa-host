ng = angular.module 'myApp'


ng.config ($stateProvider, navbarProvider, primus) ->
  $stateProvider.state 'view4',
    url: '/view4'
    templateUrl: 'view4/view.html'
    controller: 'View4Ctrl'
  navbarProvider.add '/view4', 'View4', 14
  
  primus.save = (scope, data) ->
    console.log "saveToStorage"
    primus.write ['saveToStorage', data]
     #primus.write ['live', data]
     
 
# use buttons to set variable to values
ng.controller 'View4Ctrl', ($scope, primus, jeebus) ->    
    console.log "view4"
    jeebus.connect

    # get existing nodes from db
    # $scope.view4 = primus.live $scope, 'view5', (table)->
    #   console.info table.value
    #   node = table.value
    #   $scope.todos.push 
    #       text: node.name
    #       done: false
      

    $scope.addValue = (key, value) ->
      # console.log jeebus.logFunc
      jeebus.saveToStorage {key, value}
      
      # # make sure entries end up in view 5, by adding a prefix

      # prefix = "view5"
      
      # value = null if value is ""

      # data = {prefix:prefix, key:key, value:value}
      # $scope.save = primus.save $scope, data
    
    counter = []      
    
    $scope.addNode = (name, type)-> 
      prefix = "view5"
                
      number = counter[type] or 0    
      height = number * 100 + 10
      
      value = '{"name":"'+ name + '","type":"' + type + '", "x":"300","y":"'+ height + '"}'      
      # console.info value

      
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
    


    # $scope.view5 = primus.getdb $scope, 'view5', (table)->
    #   console.info table.value
    #   node = JSON.parse table.value
    #   $scope.todos.push 
    #     text: node.name
    #     type: node.type
    #     done: false
    
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
            
          
      