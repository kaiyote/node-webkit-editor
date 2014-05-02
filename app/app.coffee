'use strict'
NWEditor = {}
NWEditor.FS = require 'fs'
NWEditor.Path = require 'path'
NWEditor.Window = do require('nw.gui').Window.get
NWEditor.Sessions = new Array
NWEditor.Editor = null

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
    
NWEditor.NewFile = ->
  session = new ace.EditSession '', 'ace/mode/text'
  session.path = 'untitled.txt'
  NWEditor.Editor.setSession session
  NWEditor.Sessions.push session

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
    
  Clear: ->
    @files = []
    @directories = []
    @loaded = false
    
  LoadChildren: ->
    unless @loaded
      files = NWEditor.FS.readdirSync @root
      for file in files
        if file[0] isnt '.'
          filePath = NWEditor.Path.join @root, file
          stat = NWEditor.FS.statSync filePath
          if do stat.isDirectory
            @directories.push new NWEditor.Directory filePath
          else
            @files.push filePath
      @loaded = true
  
#clear off any listeners that might be hanging around across a refresh
NWEditor.Window.removeAllListeners 'on'