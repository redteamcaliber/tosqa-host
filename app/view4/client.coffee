ng = angular.module 'myApp'


ng.config ($stateProvider, navbarProvider, primus) ->
  $stateProvider.state 'view4',
    url: '/view4'
    templateUrl: 'view4/view.html'
    controller: 'View4Ctrl'
  navbarProvider.add '/view4', 'View4', 14

 
# use buttons to set variable to values
ng.controller 'View4Ctrl', ($scope, primus, TQ, tqNodeTypes, tqNodes) ->    
    console.log "view4"
    tqnt = tqNodeTypes
    

    console.log tqNodes
    


    $scope.addValue = (key, value) ->
      # console.log jeebus.logFun
      id = "id" + new Date().getTime() 

      tqNodes[id]=
              type:value
              title: key

      TQ.set key, tqNodes[id]

    counter = []
    
    $scope.addNode = (name, type)-> 
      prefix = "view5"
      
      console.log tqnt[type]

      number = counter[type] or 0    
      height = number * 100 + 10
      
      value = '{"name":"'+ name + '","type":"' + type + '", "x":"300","y":"'+ height + '"}'      
      
      data = {prefix:prefix, key:name, value:value}
      counter[type] = number+1 
    
    $scope.removeMotor = (name, type)-> 
      prefix = "view5"
                     
      data = {prefix:prefix, key:name, value:null}
      counter[type] -= 1


    
    #########
    ## modified todolist starts here
    #########
    
    $scope.todos = []

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



ng.factory "tqNodes", ->
  
    id2233:
       type:"ssb"
       title:"X-Axis"
    
    id4466: 
        type:"host"
        title:"Tosqa host"                 
    
      