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
  'Session'
  'Project'
  ($scope, $rootScope, Session, Project) ->
    fs = require 'fs'
    Path = require 'path'
    nodeWindow = require('nw.gui').Window.get()
    
    sessionPath = Path.join process.env.HOME || process.env.USERPROFILE, '.nweditor', 'session.json'
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
    
    $scope.editor.loadFile = (content, path, save) ->
      mode = modes.getModeForPath path
      try
        session = _.find $scope.sessions, (session) -> session.path is path or session.path is 'untitled.txt'
        if !session?
          session = new ace.EditSession content, mode.mode
        else if session.path is 'untitled.txt'
          session.path = path
          session.setDocument new Document content
          session.setMode mode.mode
      catch
        #something weird is going on, the first attempt to make an EditSession always fails because it can't call "split" on undefined
        #no idea why, but the second attempt works
        session = new ace.EditSession content, mode.mode
      session.path = path
      # close any file watcher we currently have
      do session.watcher?.close
      session.watcher = fs.watch path, (event, filename) ->
        do session.watcher.close
        $scope.editor.loadFile '' + fs.readFileSync(path), path
      
      $scope.sessions.push session unless _.find $scope.sessions, (innerSession) -> innerSession.path is session.path
      $scope.editor.setSession session
      do $scope.editor.navigateFileStart
      
      $scope.$apply $scope.mode = ''
      $scope.$apply $scope.mode = mode.mode
      if save
        Session.state.files.push path
        do Session.writeSession
        
    $scope.editor.newFile = (apply) ->
      session = new ace.EditSession '', 'ace/mode/text'
      session.path = 'untitled.txt'
      $scope.editor.setSession session
      if apply
        $scope.$apply $scope.sessions.push session
        $scope.$apply $scope.mode = 'ace/mode/text'
      else
        $scope.sessions.push session
        $scope.mode = 'ace/mode/text'
      
    openFile = document.querySelector '#openFile'
    saveFile = document.querySelector '#saveFile'
    
    openListener = (evt) ->
      path = @value
      fs.readFile path, null, (err, data) ->
        if !err
          $scope.editor.loadFile '' + data, path, true
        else
          alert err
      @value = ''
    
    saveAsListener = (evt) ->
      session = do $scope.editor.getSession
      fs.writeFile @value, $scope.editor.getValue()
      #update editor path and state
      session.path = @value
      Session.state.files = _.reject Session.state.files, (file) -> file is session.path
      Session.state.files.push @value
      do Session.writeSession
    
    #ensure we don't keep attaching the same even listener repeatedly
    openFile.removeEventListener 'change', openListener, false
    openFile.addEventListener 'change', openListener, false
    #ensure we don't keep attaching the same even listener repeatedly
    saveFile.removeEventListener 'change', saveAsListener, false
    saveFile.addEventListener 'change', saveAsListener, false
      
    $scope.$watch 'theme', (newVal, oldVal) ->
      unless newVal is oldVal
        $scope.editor.setTheme newVal
        Session.state.theme = newVal
        do Session.writeSession
      
    $scope.$watch 'mode', (newVal, oldVal) ->
      $scope.editor.getSession().setMode newVal unless newVal is oldVal or newVal is ''
    
    nodeWindow.removeAllListeners 'on'
    nodeWindow.on 'loaded', () ->
      try
        if Session.state.theme
          $scope.$apply $scope.theme = Session.state.theme
        if Session.state.files.length
          $scope.editor.loadFile '' + fs.readFileSync(file), file for file in Session.state.files
        else
          $scope.editor.newFile true
        if Session.state.project
          $scope.$apply Project.loadProject Session.state.project
      catch e
        do $scope.editor.newFile
        
    nodeWindow.on 'loading', () ->
      do session?.watcher?.close for session in $scope.sessions
      
    $scope.$on 'modeChange', (evt, args) ->
      $scope.mode = args
      
    $scope.$on 'closeSession', (evt, args) ->
      do args.watcher?.close
      $scope.sessions = _.filter $scope.sessions, (session) ->
        session.path isnt args.path
      if $scope.editor.getSession().path is args.path
        if $scope.sessions?.length isnt 0
          $scope.editor.setSession _.last($scope.sessions)
        else
          do $scope.editor.newFile
        
      $scope.mode = ''
      $scope.mode = $scope.editor.getSession().$mode.$id
      
      Session.state.files = _.chain $scope.sessions
                      .where (session) -> session.path isnt 'untitled.txt'
                      .pluck 'path'
                      .value()
      do Session.writeSession
]

.controller 'ProjectCtrl', [
  '$scope'
  '$rootScope'
  'Session'
  'Project'
  ($scope, $rootScope, Session, Project) ->
    $scope.collapsed = true
    
    addDirectory = document.querySelector '#addDirectory'
    saveProject = document.querySelector '#saveProject'
    
    addListener = (evt) ->
      projectPath = @value
      Project.project.directories.push projectPath unless _.find Project.project.directories, (existingPath) -> existingPath is projectPath
      
    saveListener = (evt) ->
      Project.writeProject @value
      Session.state.project = @value
      do Session.writeSession
      
    addDirectory.removeEventListener 'change', addListener, false
    addDirectory.addEventListener 'change', addListener, false
    
    saveProject.removeEventListener 'change', saveListener, false
    saveProject.addEventListener 'change', saveListener, false
]