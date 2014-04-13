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
    
    nodeWindow.removeAllListeners 'maximize'
    nodeWindow.on 'maximize', () ->
      $scope.$apply $scope.maximized = true
    
    nodeWindow.removeAllListeners 'unmaximize'
    nodeWindow.on 'unmaximize', () ->
      $scope.$apply $scope.maximized = false
]

.controller 'EditorCtrl', [
  '$scope'
  '$rootScope'
  ($scope, $rootScope) ->
    fs = require 'fs'
    Path = require 'path'
    nodeWindow = require('nw.gui').Window.get()
    
    sessionPath = Path.join process.env.home, '.nweditor', 'session.json'
    state = {}
    editors = []
    
    $scope.themes = ace.require('ace/ext/themelist').themes
    modes = ace.require 'ace/ext/modelist'
    $scope.modes = modes.modes
    $scope.debug = true
    
    editor = ace.edit 'editor'
    editor.commands.addCommand command for command in commands
    ace.config.set 'workerPath', 'js/workers'
    
    $scope.showDevTools = ->
      do nodeWindow.showDevTools
      
    $scope.reload = ->
      do nodeWindow.reloadIgnoringCache
    
    writeState = ->
      try
        fs.readdirSync Path.dirname sessionPath
      catch
        #doesn't exist, so make it
        fs.mkdirSync Path.dirname sessionPath
      fs.writeFileSync sessionPath, JSON.stringify state
    
    loadFile = (content, path, save) ->
      editor.path = path
      editor.setValue content
      do editor.navigateFileStart
      mode = modes.getModeForPath path
      $scope.$apply $scope.mode = mode.mode
      if save
        state.file = path
        do writeState
      
    openFile = document.querySelector '#openFile'
    saveFile = document.querySelector '#saveFile'
    
    openListener = (evt) ->
      path = this.value
      fs.readFile path, null, (err, data) ->
        if !err
          loadFile '' + data, path, true
        else
          alert err
    
    saveAsListener = (evt) ->
      fs.writeFile this.value, editor.getValue()
      #update editor path and state
      editor.path = state.file = this.value
      do writeState
    
    #ensure we don't keep attaching the same even listener repeatedly
    openFile.removeEventListener 'change', openListener, false
    openFile.addEventListener 'change', openListener, false
    #ensure we don't keep attaching the same even listener repeatedly
    saveFile.removeEventListener 'change', saveAsListener, false
    saveFile.addEventListener 'change', saveAsListener, false
      
    $scope.$watch 'theme', (newVal, oldVal) ->
      unless newVal is oldVal
        editor.setTheme newVal
        state.theme = newVal
        do writeState
      
    $scope.$watch 'mode', (newVal, oldVal) ->
      editor.getSession().setMode newVal unless newVal is oldVal
    
    nodeWindow.removeAllListeners 'on'
    nodeWindow.on 'loaded', () ->
      try
        state = JSON.parse '' + fs.readFileSync sessionPath
        if state.theme
          $scope.$apply $scope.theme = state.theme
        if state.file
          loadFile '' + fs.readFileSync(state.file), state.file
      catch e
        #no state to load, don't do anything
]