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
  '$rootScope'
  ($scope, $rootScope) ->
    fs = require 'fs'
    editor = ace.edit 'editor'
    ace.config.set 'workerPath', 'js/workers'
    
    $scope.$on 'themeChange', (event, arg) ->
      editor.setTheme arg
      
    $scope.$on 'modeChange', (event, arg) ->
      editor.getSession().setMode arg
      
    openFile = document.querySelector '#openFile'
    saveFile = document.querySelector '#saveFile'
    
    openFile.addEventListener 'change', (evt) ->
      editor.path = this.value
      fs.readFile editor.path, null, (err, data) ->
        if !err
          editor.setValue '' + data
          do editor.navigateFileStart
          if (mode = ace.require('ace/ext/modelist').getModeForPath(editor.path)) != null
            $rootScope.$broadcast 'changeMode', mode.mode
        else
          alert err
    , false
    
    saveFile.addEventListener 'change', (evt) ->
      fs.writeFile this.value, editor.getValue()
    , false
    
    editor.commands.addCommand command for command in commands
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
      
    $scope.$on 'changeMode', (event, arg) ->
      $scope.$apply($scope.mode = arg)
]