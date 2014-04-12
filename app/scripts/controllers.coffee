'use strict'

angular.module 'app.controllers', []
.controller 'TitlebarCtrl', [
  '$scope'
  '$rootScope'
  ($scope, $rootScope) ->
    nodeWindow = require('nw.gui').Window.get()
    
    $scope.minimize = ->
      do nodeWindow.minimize
      
    $scope.maximize = ->
      if $scope.maximized
        do nodeWindow.unmaximize
      else
        do nodeWindow.maximize
        
    $scope.close = ->
      nodeWindow.close true
      
    nodeWindow.on 'maximize', () ->
      $scope.$apply $scope.maximized = true
      
    nodeWindow.on 'unmaximize', () ->
      $scope.$apply $scope.maximized = false
      
    nodeWindow.on 'loaded', () ->
      $rootScope.$broadcast 'restoreState'
]

.controller 'EditorCtrl', [
  '$scope'
  '$rootScope'
  ($scope, $rootScope) ->
    fs = require 'fs'
    path = require 'path'
    sessionPath = path.join process.env.home, '.nweditor', 'session.json'
    state = {}
    editor = ace.edit 'editor'
    editor.commands.addCommand command for command in commands
    ace.config.set 'workerPath', 'js/workers'
    
    writeState = ->
      try
        fs.readdirSync path.dirname sessionPath
      catch
        #doesn't exist, so make it
        fs.mkdirSync path.dirname sessionPath
      fs.writeFileSync sessionPath, JSON.stringify state
    
    loadFile = (content, path, save) ->
      editor.setValue content
      do editor.navigateFileStart
      mode = ace.require('ace/ext/modelist').getModeForPath path
      $rootScope.$broadcast 'changeMode', mode.mode
      if save
        state.file = path
        do writeState
      
    openFile = document.querySelector '#openFile'
    saveFile = document.querySelector '#saveFile'
    
    openFile.addEventListener 'change', (evt) ->
      editor.path = this.value
      fs.readFile editor.path, null, (err, data) ->
        if !err
          loadFile '' + data, editor.path, true
        else
          alert err
    , false
    
    saveFile.addEventListener 'change', (evt) ->
      fs.writeFile this.value, editor.getValue()
    , false
    
    $scope.$on 'themeChange', (event, arg) ->
      editor.setTheme arg
      state.theme = arg
      do writeState
      
    $scope.$on 'modeChange', (event, arg) ->
      editor.getSession().setMode arg
      
    $scope.$on 'restoreState', (event, arg) ->
      try
        state = JSON.parse '' + fs.readFileSync sessionPath
        if state.theme
          $rootScope.$broadcast 'changeTheme', state.theme
        if state.file
          loadFile '' + fs.readFileSync(state.file), state.file
      catch e
        #no state to load, don't do anything
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
      
    $scope.$on 'changeTheme', (event, arg) ->
      $scope.$apply($scope.theme = arg)
]