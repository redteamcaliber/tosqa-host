ng = angular.module 'myApp'

ng.value 'appInfo',
  name: 'Tosqa'
  version: '0.1.0'
  home: 'https://github.com/nutbolt/tosqa-host'

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
  
ng.controller 'NavCtrl', ($scope, navbar) ->
  $scope.navbar = navbar

ng.directive 'appVersion', (appInfo) ->
  (scope, elm, attrs) ->
    elm.text appInfo.version
