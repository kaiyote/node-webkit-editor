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
    
    sessionPath = Path.join process.env.HOME || process.env.USERPROFILE, '.nweditor', 'session.json'
    state = {}
    $scope.sessions = []
    
    $scope.themes = ace.require('ace/ext/themelist').themes
    modes = ace.require 'ace/ext/modelist'
    $scope.modes = modes.modes
    $scope.debug = true
    
    $scope.editor = ace.edit 'editor'
    $scope.editor.commands.addCommand command for command in commands
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
    
    $scope.editor.loadFile = (content, path, save) ->
      mode = modes.getModeForPath path
      try
        session = _.find $scope.sessions, (session) -> session.path is path
        if !session?
          session = new ace.EditSession content, mode
      catch
        #something weird is going on, the first attempt to make an EditSession always fails because it can't call "split" on undefined
        #no idea why, but the second attempt works
        session = new ace.EditSession content, mode
      session.path = path
      # close any file watcher we currently have
      do session.watcher?.close
      session.watcher = fs.watch path, (event, filename) ->
        do session.watcher.close
        $scope.editor.loadFile '' + fs.readFileSync(path), path
      
      $scope.sessions.push session unless _.find $scope.sessions, (innerSession) -> innerSession.path is session.path
      $scope.editor.setSession session
      do $scope.editor.navigateFileStart
      
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
          $scope.editor.loadFile '' + data, path, true
        else
          alert err
    
    saveAsListener = (evt) ->
      session = do $scope.editor.getSession
      fs.writeFile this.value, $scope.editor.getValue()
      #update editor path and state
      session.path = state.file = this.value
      do writeState
    
    #ensure we don't keep attaching the same even listener repeatedly
    openFile.removeEventListener 'change', openListener, false
    openFile.addEventListener 'change', openListener, false
    #ensure we don't keep attaching the same even listener repeatedly
    saveFile.removeEventListener 'change', saveAsListener, false
    saveFile.addEventListener 'change', saveAsListener, false
      
    $scope.$watch 'theme', (newVal, oldVal) ->
      unless newVal is oldVal
        $scope.editor.setTheme newVal
        state.theme = newVal
        do writeState
      
    $scope.$watch 'mode', (newVal, oldVal) ->
      $scope.editor.getSession().setMode newVal unless newVal is oldVal
    
    nodeWindow.removeAllListeners 'on'
    nodeWindow.on 'loaded', () ->
      try
        state = JSON.parse '' + fs.readFileSync sessionPath
        if state.theme
          $scope.$apply $scope.theme = state.theme
        if state.file
          $scope.editor.loadFile '' + fs.readFileSync(state.file), state.file
      catch e
        #no state to load, don't do anything
        
    nodeWindow.on 'loading', () ->
      do session?.watcher?.close for session in $scope.sessions
]