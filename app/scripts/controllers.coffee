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
        do nodeWindow.unmaximize
      else
        do nodeWindow.maximize
        
    nodeWindow.on 'maximize', () ->
      $scope.$apply $scope.maximized = true
      
    nodeWindow.on 'unmaximize', () ->
      $scope.$apply $scope.maximized = false
        
    $scope.close = ->
      nodeWindow.close true
]

.controller 'EditorCtrl', [
  '$scope'
  ($scope) ->
    fs = require 'fs'
    nodeWindow = require('nw.gui').Window.get()
    state = {}
    $scope.themes = ace.require('ace/ext/themelist').themes
    $scope.modes = ace.require('ace/ext/modelist').modes
    $scope.debug = true
    
    $scope.safeApply = (fn) ->
      phase = this.$root.$$phase
      if phase is '$apply' or phase is '$digest'
        if fn? and typeof fn is 'function'
          do fn
      else
        this.$apply fn
    
    $scope.$watch 'theme', (newVal, oldVal) ->
      editor.setTheme newVal unless newVal is oldVal
      state.theme = newVal
      do writeState
      
    $scope.$watch 'mode', (newVal, oldVal) ->
      editor.getSession().setMode newVal unless newVal is oldVal
      
    writeState = ->
      fs.writeFileSync 'config/session.json', JSON.stringify state
      
    loadFile = (content, path) ->
      editor.setValue content
      do editor.navigateFileStart
      mode = ace.require('ace/ext/modelist').getModeForPath(path)
      $scope.safeApply () -> $scope.mode = mode?.mode || 'ace/mode/text'
    
    if fs.existsSync 'config/session.json'
      stateString = '' + fs.readFileSync 'config/session.json'
      state = JSON.parse stateString unless stateString is ''
    
    editor = ace.edit 'editor'
    ace.config.set 'workerPath', 'js/workers'
    editor.commands.addCommand command for command in commands
    
    if Object.keys(state).length
      $scope.safeApply () -> $scope.theme = state.theme
      editor.setTheme state.theme
      editor.path = state.file
      loadFile '' + fs.readFileSync(state.file), state.file
    else
      state = {}
    
    $scope.showDevTools = ->
      do nodeWindow.showDevTools
      
    $scope.reload = ->
      do nodeWindow.reloadIgnoringCache
      
    openFile = document.querySelector '#openFile'
    saveFile = document.querySelector '#saveFile'
    
    openFile.addEventListener 'change', (evt) ->
      editor.path = this.value
      state.file = this.value
      do writeState
      fs.readFile editor.path, null, (err, data) ->
        if !err
          loadFile '' + data, editor.path
        else
          alert err
    , false
    
    saveFile.addEventListener 'change', (evt) ->
      fs.writeFile this.value, editor.getValue()
    , false
]