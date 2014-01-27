ng = angular.module 'myApp'

ng.constant 'jbName', 'blinker'

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider.state 'jeebus',
    url: '/jeebus'
    templateUrl: 'jeebus/view.html'
    controller: 'JeeBusCtrl'
  navbarProvider.add '/jeebus', 'JeeBus', 25

ng.run ($rootScope, jbName) ->
  ws = null

  # global function to send an object to the JeeBus server
  $rootScope.jbSend = (payload) ->
    ws.send JSON.stringify payload
  
  reconnect = (firstCall) ->
    # the websocket is served from the same site as the web page
    # ws = new WebSocket "ws://#{location.host}/ws"
    ws = new WebSocket "ws://#{location.hostname}:3334/ws", [jbName]

    ws.onopen = ->
      # location.reload()  unless firstCall
      console.log 'WS Open'

    ws.onmessage = (m) ->
      if m.data instanceof ArrayBuffer
        console.log 'binary msg', m
      $rootScope.$apply ->
        for k, v of JSON.parse(m.data)
          $rootScope[k] = v

    # ws.onerror = (e) ->
    #   console.log 'Error', e

    ws.onclose = ->
      console.log 'WS Closed'
      setTimeout reconnect, 1000
    
  reconnect true

ng.controller 'JeeBusCtrl', ($scope) ->

  $scope.button = (button, value) ->
    @jbSend {button,value}
