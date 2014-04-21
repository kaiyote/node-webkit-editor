'use strict'

angular.module 'app.directives', [
  'app.services'
]
.directive 'tabs', () ->
  restrict: 'E'
  scope:
    sessions: '=sessions'
    editor: '=editor'
  template: '<div ng-repeat="session in sessions" class="tab">' +
              '<span>{{filename(session.path)}}</span>' +
              '<div class="status">' +
              '</div>' +
            '</div>'
  replace: true
  link: (scope, element, attrs) ->
    path = require 'path'
    
    scope.filename = (index) ->
      path.basename index