ng = angular.module 'myApp'

ng.value 'appInfo',
  name: 'Tosqa'
  version: '0.1.0'
  home: 'https://github.com/tosqa/tosqa-host'

ng.provider 'navbar', ->
  navs = []
  add: (route, title, weight = 50) ->
    navs.push { route, title, weight }
  del: (route) ->
    navs = navs.filter (x) -> x.route isnt route
  $get: ->
    navs.sort (a, b) -> a.weight - b.weight
  
ng.config ($urlRouterProvider, $locationProvider) ->
  $urlRouterProvider.otherwise '/'
  $locationProvider.html5Mode true
  
ng.run ($rootScope, appInfo) ->
  $rootScope.appInfo = appInfo
  $rootScope.shared = {}
  
ng.controller 'NavCtrl', ($scope, navbar, tosqa) ->
  # FIXME hack: inject tosqa for its side effect, i.e. connecting to JeeBus
  $scope.navbar = navbar

ng.directive 'appVersion', (appInfo) ->
  (scope, elm, attrs) ->
    elm.text appInfo.version

# The "tosqa" service connects to JeeBus and provides various services.
ng.factory 'tosqa', (jeebus) ->
  jeebus.connect 'blinker'
  
  # Get the sub-keys under a certain path in the host database as a promise.
  # This only goes one level deep, i.e. a flat list of immediate sub-keys.
  # If more than one key is given, they are joined with slashes.
  keys: (key...) ->
    jeebus.rpc 'db-keys', "/tosqa/#{key.join '/'}"
  
  # Get a key's value from the host database, returned as a promise.
  # If more than one key is given, they are joined with slashes.
  get: (key...) ->
    jeebus.rpc 'db-get', "/tosqa/#{key.join '/'}"

  # Set a key/value pair in the host database, properly tagged with a prefix.
  # If more than one key is given, they are joined with slashes.
  set: (key..., value) ->
    jeebus.store "/tosqa/#{key.join '/'}", value
    @
