ng = angular.module 'myApp'


ng.config ($stateProvider, navbarProvider) ->
  $stateProvider.state 'view3',
    url: '/view3'
    templateUrl: 'view3/view.html'
    controller: 'View3Ctrl'
  navbarProvider.add '/view3', 'View3', 13

# use buttons to set variable to values
ng.controller 'View3Ctrl', ($scope, host) ->
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
  
  
ng.filter 'interpolate', (appInfo) ->
  (text) ->
    String(text).replace '%VERSION%', appInfo.version
   
   
ng.controller 'newCtrl', ($scope, host) ->


 
