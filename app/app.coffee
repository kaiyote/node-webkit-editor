'use strict'

NWEditor =
  FS: require 'fs'
  Path: require 'path'
  Window: do require('nw.gui').Window.get
  Sessions: new Array
  State: class
    instance = null
    @get: ->
      instance ?= new State
  
    class State
      _filename = ''
      constructor: ->
        _filename = NWEditor.Path.join process.env.HOME || process.env.USERPROFILE, '.nweditor', 'session.json'
      
      Load: ->
        try
          data = JSON.parse '' + NWEditor.FS.readFileSync _filename
          @files = data.files or []
          @theme = data.theme or ''
          @project = data.project or ''
        catch
          #probably bad JSON or file doesn't exist, continue onwards
          @files = []
          @theme = ''
          @project = ''
          
      Write: ->
        NWEditor.FS.writeFile _filename, JSON.stringify this
  Project: class
    instance = null
    @get: ->
      instance ?= new Project
      
    class Project
      _path = ''
      constructor: ->
        @directories = []
        @name = ''
        
      Load: (file) ->
        _path = file
        try
          data = JSON.parse '' + NWEditor.FS.readFileSync _path
          @directories = data.directories or []
          @name = data.name or ''
        catch
          #either bad JSON or no file, carry on
          @directories = []
          @name = ''
          
      Write: (file) ->
        _path = file if file
        try
          NWEditor.FS.readdirSync path.dirname _path
        catch
          #doesn't exist, so make it
          NWEditor.FS.mkdirSync NWEditor.Path.dirname _path
        NWEditor.FS.writeFileSync _path, JSON.stringify this
  Directory: class
    constructor: (root) ->
      @root = root
      @files = []
      @directories = []
      @name = NWEditor.Path.basename root
  
#clear off any listeners that might be hanging around across a refresh
NWEditor.Window.removeAllListeners 'on'