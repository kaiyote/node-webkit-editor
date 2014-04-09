'use strict'

App = angular.module 'app', [
  'ngCookies'
  'ngResource'
  'ngRoute'
  'app.controllers'
  'app.directives'
  'app.filters'
  'app.services'
  'app.templates'
]

App.config [
  '$routeProvider'
  '$locationProvider'
  ($routeProvider, $locationProvider, config) ->
    $routeProvider
      .when '/todo', {templateUrl: 'app/partials/todo.jade'}
      .when '/view1', {templateUrl: 'app/partials/partial1.jade'}
      .when '/view2', {templateUrl: 'app/partials/partial2.jade'}
      .otherwise {redirectTo: '/todo'}
    # Without server side support html5 must be disabled.
    $locationProvider.html5Mode(false)
]
