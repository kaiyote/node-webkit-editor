'use strict'

angular.module 'app.controllers', []
.controller 'TitlebarCtrl', [
  '$scope'
  ($scope) ->
    nodeWindow = require('nw.gui').Window.get()
    
    $scope.minimize = ->
      do nodeWindow.minimize
      
    $scope.maximize = ->
      if $scope.maximized
        $scope.maximized = false
        do nodeWindow.unmaximize
      else
        $scope.maximized = true
        do nodeWindow.maximize
        
    $scope.close = ->
      nodeWindow.close true
]

.controller 'EditorCtrl', [
  '$scope'
  ($scope) ->
    editor = ace.edit "editor"
    ace.config.set 'workerPath', 'js/workers'
    
    $scope.$on 'themeChange', (event, arg) ->
      editor.setTheme arg
      
    $scope.$on 'modeChange', (event, arg) ->
      editor.getSession().setMode arg
]

.controller 'StatusCtrl', [
  '$scope'
  '$rootScope'
  ($scope, $rootScope) ->
    nodeWindow = require('nw.gui').Window.get()
    $scope.themes = ace.require('ace/ext/themelist').themes
    $scope.modes = ace.require('ace/ext/modelist').modes
    $scope.debug = true
    
    $scope.showDevTools = ->
      do nodeWindow.showDevTools
      
    $scope.reload = ->
      do nodeWindow.reloadIgnoringCache
      
    $scope.$watch 'theme', (newVal, oldVal) ->
      $rootScope.$broadcast 'themeChange', newVal unless newVal is oldVal
      
    $scope.$watch 'mode', (newVal, oldVal) ->
      $rootScope.$broadcast 'modeChange', newVal unless newVal is oldVal
]