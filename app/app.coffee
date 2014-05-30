'use strict'
NWEditor = {}
NWEditor.FS = require 'fs'
NWEditor.Path = require 'path'
NWEditor.Window = do require('nw.gui').Window.get
NWEditor.Sessions = new Array
NWEditor.Editor = null
NWEditor.Domain = require 'domain'
NWEditor.OS = require 'os'

NWEditor.LoadFile = (path, save, activate) ->
  mode = ace.require('ace/ext/modelist').getModeForPath path
  replace = false
  
  currentSession = _.find NWEditor.Sessions, (session) -> session.path is path or session.path is 'untitled.txt'
  # given the behavior of the editor on load, we will *always* have a session
  if !currentSession
    session = new ace.EditSession '' + NWEditor.FS.readFileSync(path), mode.mode
  else if currentSession.path is 'untitled.txt'
    replace = true
    session = new ace.EditSession '' + NWEditor.FS.readFileSync(path), mode.mode
  else
    replace = true
    session = currentSession
    
  session.path = path
  session.setUndoManager new ace.UndoManager
  # close any file watcher we currently have
  do session.watcher?.close
  session.watcher = NWEditor.FS.watch path, (event, filename) ->
    do session.watcher.close
    NWEditor.LoadFile path
  
  if replace
    index = NWEditor.Sessions.indexOf(_.find NWEditor.Sessions, (oldSession) -> oldSession.path is currentSession.path)
    NWEditor.Sessions[index] = session
  else
    NWEditor.Sessions.push session
    
  if activate
    NWEditor.Editor.setSession session
    do NWEditor.Editor.navigateFileStart
  
  if save
    NWEditor.State.get().files = _.chain NWEditor.Sessions
                                  .filter (session) -> session.path isnt 'untitled.txt'
                                  .map (session) -> session.path
                                  .value()
    do NWEditor.State.get().Write
    
  NWEditor.Settings.get().applyAceSettings session, 'session'
    
NWEditor.NewFile = ->
  session = new ace.EditSession '', 'ace/mode/text'
  session.path = 'untitled.txt'
  NWEditor.Editor.setSession session
  NWEditor.Sessions.push session
  NWEditor.Settings.get().applyAceSettings session, 'session'

NWEditor.State = class
  instance = null
  @get: ->
    instance ?= new State

  class State
    _path = ''
    constructor: ->
      _path = NWEditor.Path.join process.env.HOME || process.env.USERPROFILE, '.nweditor', 'session.json'
      try
        data = JSON.parse '' + NWEditor.FS.readFileSync _path
        @files = data.files or []
        @theme = data.theme or ''
        @project = data.project or ''
      catch
        #probably bad JSON or file doesn't exist, continue onwards
        @files = []
        @theme = ''
        @project = ''
    
    Write: ->
      try
        NWEditor.FS.readdirSync NWEditor.Path.dirname _path
      catch
        #doesn't exist, so make it
        NWEditor.FS.mkdirSync NWEditor.Path.dirname _path
      NWEditor.FS.writeFile _path, JSON.stringify this
      
NWEditor.Settings = class
  instance = null
  @get: ->
    instance ?= new Settings
    
  class Settings
    _basePath = ''
    _userPath = ''
    constructor: ->
      _basePath = 'settings/settings.json'
      _userPath = NWEditor.Path.join process.env.HOME || process.env.USERPROFILE, '.nweditor', 'settings.json'
      
      try
        userDelta = JSON.parse '' + NWEditor.FS.readFileSync _userPath
        settings = jsondiffpatch.patch JSON.parse('' + NWEditor.FS.readFileSync _basePath), userDelta
      catch
        #either the patch file doesn't exist, or it's poorly formed, use default settings
        settings = JSON.parse '' + NWEditor.FS.readFileSync _basePath
        
      @editor = settings.editor
      @session = settings.session
      @user = settings.user
      @renderer = settings.renderer
      
    applyAceSettings: (target, objKey) ->
      _.keys(@[objKey]).forEach (setting) =>
        target["set#{setting.replace /\s/g, ''}"] @[objKey][setting]
      
NWEditor.Project = class
  instance = null
  @get: ->
    instance ?= new Project
    
  class Project
    _path = ''
    constructor: ->
      @directories = []
      
    Load: (file) ->
      _path = file
      try
        data = JSON.parse '' + NWEditor.FS.readFileSync _path
        @directories = data.directories or []
      catch
        #either bad JSON or no file, carry on
        @directories = []
        
    Write: (file) ->
      _path = file if file
      try
        NWEditor.FS.readdirSync NWEditor.Path.dirname _path
      catch
        #doesn't exist, so make it
        NWEditor.FS.mkdirSync NWEditor.Path.dirname _path
      NWEditor.FS.writeFileSync _path, JSON.stringify this
      
NWEditor.Directory = class
  constructor: (root) ->
    @root = root
    @files = []
    @directories = []
    @name = NWEditor.Path.basename root
    @loaded = false
    if NWEditor.Settings.get().user["Watch Project Tree"]
      watchFunction = _.throttle (event, filename) =>
        do @LoadChildren
      , 2000, trailing: false
      @watcher = NWEditor.FS.watch @root, watchFunction
    
  Clear: ->
    @loaded = false
    
  LoadChildren: ->
    d = do NWEditor.Domain.create
    d.on 'error', (err) ->
      #the only error i've ever seen here is a "i can't find the folder" error
      #i can't seem to catch them with a try/catch, and a global handler is
      #less than optimal, so we will handle it locally here by doing nothing
    d.run =>
      do m.startComputation
      NWEditor.FS.readdir @root, (err, files) =>
        if !err
          files = files.map (file) => NWEditor?.Path.join(@root, file)
          @directories = _.reject @directories, (dir) ->
            files.indexOf(dir.root) is -1
          @files = _.reject @files, (file) ->
            files.indexOf(file) is -1
          for file in files
            stat = NWEditor.FS.statSync file
            if do stat.isDirectory
              @directories.push new NWEditor.Directory file unless _.find @directories, (dir) -> dir.root is file
            else
              @files.push file unless _.find @files, (existing) -> existing is file
          @directories = _.sortBy @directories, (directory) -> do directory.root.toLowerCase
          @files = _.sortBy @files, (file) -> do file.toLowerCase
          @loaded = true
        do m.endComputation
  
#clear off any listeners that might be hanging around across a refresh
NWEditor.Window.removeAllListeners 'on'