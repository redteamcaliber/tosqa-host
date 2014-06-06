ng = angular.module 'myApp', [
  'ui.router'
  'ngAnimate'
  'mm.foundation'
]

ng.value 'appInfo',
  name: 'Tosqa'
  version: '0.9.0'
  home: 'http://tosqa.com/'

ng.run (jeebus) ->
  jeebus.connect 'tosqa'

ng.run ($rootScope, appInfo) ->
  $rootScope.shared = {}
  $rootScope.appInfo = appInfo
  $rootScope.$on 'ws-open', ->
    $rootScope.serverStatus = 'connected'
  $rootScope.$on 'ws-lost', ->
    $rootScope.serverStatus = 'disconnected'

ng.directive 'highlightOnChange', ($animate) ->
  (scope, elem, attrs) ->
    scope.$watch attrs.highlightOnChange, ->
      $animate.addClass elem, 'highlight', ->
        attrs.$removeClass 'highlight'
