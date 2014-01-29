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
    @
