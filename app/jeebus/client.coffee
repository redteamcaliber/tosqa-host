ng = angular.module 'myApp'

ws = null

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider.state 'jeebus',
    url: '/jeebus'
    templateUrl: 'jeebus/view.html'
    controller: 'JeeBusCtrl'
  navbarProvider.add '/jeebus', 'JeeBus', 25

ng.run ($rootScope) ->

  setCount = (data) ->
    $rootScope.$apply ->
      $rootScope.count = data

  reconnect = (firstCall) ->
    # the websocket is served from the same site as the web page
    # ws = new WebSocket "ws://#{location.host}/ws"
    ws = new WebSocket "ws://#{location.hostname}:3334/ws"

    ws.onopen = ->
      # location.reload()  unless firstCall
      console.log 'Open'

    ws.onmessage = (m) ->
      $rootScope.$apply ->
        msg = JSON.parse(m.data)
        $rootScope.$broadcast msg[0], msg.slice(1) | 0

    ws.onclose = ->
      console.log 'Closed'
      setTimeout reconnect, 1000
    
  reconnect true

ng.controller 'JeeBusCtrl', ($scope) ->
  $scope.$on 'R', (e, v) -> $scope.redLed = v is 1
  $scope.$on 'G', (e, v) -> $scope.greenLed = v is 1
  $scope.$on 'C', (e, v) -> $scope.count = v

  $scope.button = (b, v) ->
    ws.send JSON.stringify [b, v]
