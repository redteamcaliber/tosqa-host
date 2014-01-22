# define an Angular module which injects incoming events The Angular Way
# this module must be added as dependency in the main Angular application

ng = angular.module 'myApp'

ng.run ($rootScope, primus) ->

  primus.on 'open', (arg) ->
    $rootScope.$apply -> $rootScope.serverConnection = 'open'
  primus.on 'end', (arg) ->
    $rootScope.$apply -> $rootScope.serverConnection = 'closed'
  primus.on 'reconnect', (arg) ->
    $rootScope.$apply -> $rootScope.serverConnection = 'lost'
  primus.on 'online', (arg) ->
    console.log 'ONLINE'
  primus.on 'offline', (arg) ->
    console.log 'OFFLINE'

  primus.on 'data', (arg) ->
    console.log 'ng-primus', arg
