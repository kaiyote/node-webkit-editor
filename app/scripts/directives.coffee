'use strict'

angular.module 'app.directives', [
  'app.services'
]
.directive 'tabs', [
  '$rootScope',
  ($rootScope) ->
    restrict: 'E'
    scope:
      sessions: '=sessions'
      editor: '=editor'
    template: '<div ng-repeat="session in sessions" class="tab" ng-class="{active: isActive(session.path)}">' +
                '<span ng-click="update(session)" data-text="{{filename(session.path)}}">{{filename(session.path)}}</span>' +
                '<a class="status" ng-click="close(session)">x</a>' +
              '</div>'
    replace: true
    link: (scope, element, attrs) ->
      path = require 'path'
      
      scope.filename = (file) ->
        path.basename file
      
      scope.update = (session) ->
        currentActive = document.querySelector 'div.tab.active'
        nextActive = document.querySelector("span[data-text='#{scope.filename session.path}']").parentElement
        currentActive.classList.remove 'active'
        nextActive.classList.add 'active'
        
        scope.editor.setSession session
        $rootScope.$broadcast 'modeChange', session.$mode.$id
        
      scope.close = (session) ->
        $rootScope.$broadcast 'closeSession', session
        
      scope.isActive = (file) ->
        scope.editor.getSession().path is file
]