'use strict'

angular.module 'app.directives', [
  'app.services'
]
.directive 'tabs', () ->
  restrict: 'E'
  template: '<div repeat="session in sessions">'
  scope:
    sessions: '@sessions'
    editor: '@editor'
  link: (scope, element, attrs) ->
    scope.activate = (tab) ->
      ''
  