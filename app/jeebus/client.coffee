ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider.state 'jeebus',
    url: '/jeebus'
    templateUrl: 'jeebus/view.html'
    controller: 'JeeBusCtrl'
  navbarProvider.add '/jeebus', 'JeeBus', 25

ng.controller 'JeeBusCtrl', ($scope, jeebus) ->
  # TODO rewrite these example to use the "tosqa" service i.s.o. "jeebus"

  $scope.echoTest = ->
    jeebus.send "echoTest!" # send a test message to JB server's stdout
    jeebus.rpc('echo', 'Echo', 'me!').then (r) ->
      $scope.message = r

  $scope.dbGetTest = ->
    jeebus.rpc('db-get', '/admin/started').then (r) ->
      $scope.message = r

  $scope.dbKeysTest = ->
    jeebus.rpc('db-keys', '/').then (r) ->
      $scope.message = r

# Tosqa-specific setup to connect on startup and define a new "tosqa" service.

ng.run (jeebus) ->
  jeebus.connect 'tosqa', 3334

<<<<<<< HEAD
    reconnect true
   
  # Send a payload to the JeeBus server over the websocket connection.
  # The payload should be an object (anything but array is supported for now).
  # This becomes an MQTT message with topic "sv/<appTag>/ip-<addr:port>".
  send: (payload) ->
    msg = angular.toJson payload
    if msg[0] is '['
      console.error "payload can't be an array (#{payload.length} elements)"
    else
      ws.send msg
    @

  saveToStorage: (table) ->
    console.log "jeebus saveToStorage ", table.key, table.value
    ws.send angular.toJson table
    # if msg.slice(0, 3) is '["/'
    #   ws.send angular.toJson msg
    # else
    #   console.error 'key does not start with "/":', key
    # @

  # Store a key/value pair in the JeeBus database (key must start with "/").
  store: (key, value) ->
    msg = angular.toJson [key, value]
    if msg.slice(0, 3) is '["/'
      ws.send angular.toJson msg
    else
      console.error 'key does not start with "/":', key
=======
ng.factory 'tosqa', (jeebus) ->
  # For the calls below:
  #  - if more than one key is specified, they are joined with slashes
  #  - do not include a slash at the start or end of any key argument
  
  # Get the sub-keys under a certain path in the host database as a promise.
  # This only goes one level deep, i.e. a flat list of immediate sub-keys.
  keys: (key...) ->
    jeebus.rpc 'db-keys', "/#{['tosqa'].concat(key).join '/'}/"
  
  # Get a key's value from the host database, returned as a promise.
  get: (key...) ->
    jeebus.rpc 'db-get', "/#{['tosqa'].concat(key).join '/'}"

  # Set a key/value pair in the host database, properly tagged with a prefix.
  # If value is the empty string or null, the key will be deleted.
  set: (key..., value) ->
    jeebus.store "/#{['tosqa'].concat(key).join '/'}", value
>>>>>>> master
    @
