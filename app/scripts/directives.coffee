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
.directive 'project', [
  '$rootScope'
  'Project'
  ($rootScope, Project) ->
    restrict: 'E'
    template: '<div>' +
                '<div class="project-name">{{project.name}}</div>' +
                '<dirtree directory="directory" ng-repeat="directory in projectListing"></dirtree>' +
              '</div>'
    replace: true
    link: (scope, element, attrs) ->
      path = require 'path'
      fs = require 'fs'
      
      scope.project = Project.project
      scope.projectListing = []
      
      scope.$watch 'project.directories', (newVal, oldVal) ->
          scope.projectListing.push new Directory dir for dir in newVal unless _.find scope.projectListing, (existingPath) -> existingPath.root is projectPath
        , true
      
      scope.load = (directory) ->
        do directory.loadChildren
]
.directive 'dirtree', [
  '$compile'
  ($compile) ->
    restrict: 'E'
    scope:
      directory: '=directory'
    template: '<div class="tree" ng-click="load(directory)">' +
                '<span>{{directory.name}}</span>' +
              '</div>'
    replace: true
    link: (scope, element, attrs) ->
      dirNode = angular.element '<dirtree></dirtree>'
          .attr 'ng-repeat', 'dir in directory.dirs'
          .attr 'directory', 'dir'
      element.append dirNode
      scope.nodeFunction = $compile scope.dirNode
          
      appendElement = (element) ->
        scope.element.append element
        
      scope.load = (directory) ->
        do directory.loadChildren
        scope.nodeFunction scope
]
.directive 'filenode', [
  '$rootScope'
  ($rootScope) ->
    restrict: 'E'
    scope:
      file: '=file'
    template: '<div class="tree">' +
                '<span>{{file}}</span>' +
              '</div>'
    replace: true
    link: (scope, element, attrs) ->
      scope.click = () ->
]