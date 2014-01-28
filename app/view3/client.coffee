ng = angular.module 'myApp'


ng.config ($stateProvider, navbarProvider) ->
  $stateProvider.state 'view3',
    url: '/view3'
    templateUrl: 'view3/view.html'
    controller: 'View3Ctrl'
  navbarProvider.add '/view3', 'View3', 13

# use buttons to set variable to values
ng.controller 'View3Ctrl', ($scope, host, tqNodeTypes) ->
  $scope.spice = "very"
  console.log "view3"

  $scope.chiliSpicy = () ->
    $scope.spice = 'chili' 
  $scope.jalapenoSpicy = () ->
    $scope.spice = 'jalepeno'
  $scope.cSpice = (spice) ->
    $scope.spice = spice    
    
  $scope.newCtrl = () ->
    $scope.counter = host 'view3_next' 
    console.log "newCtrl"  

  $scope.test = () ->
    console.log tqNodeTypes.ssb.description
  
  
ng.filter 'interpolate', (appInfo) ->
  (text) ->
    String(text).replace '%VERSION%', appInfo.version
   
   
ng.controller 'newCtrl', ($scope, host) ->


ng.factory "tqNodeTypes", ->

  #factory function body that constructs shinyNewServiceInstance
  ssb:
    description: "this is a driver for ssb"
    driver: "ssbDriver"
    diagramX: 400
    attributes:
      temp:
        varType: "int"
        editable: false
        default: 0
      stepSize:
        varType: "float"
        editable: true
    pads:
      'frequency': {}
      'timbre': {}
      'modulation': {}
  
  host:
    description: "this the host"
    driver: "hostDriver"
    diagramX: 200
    attributes:
      temp:
        varType: "int"
        editable: false
        default: 0
      stepSize:
        varType: "float"
        editable: true
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
  
  sensor:
    description: "this a sensor"
    driver: "sensorDriver"
    diagramX: 50
    attributes:
      value:
        varType: "int"
        editable: false
        default: 0
    pads:
      'measure out':
        wires:
          10: ['']
