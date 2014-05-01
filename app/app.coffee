'use strict'

NWEditor =
  FS: require 'fs'
  Path: require 'path'
  Window: do require('nw.gui').Window.get
  Sessions: new Array
  Editor: null
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
          NWEditor.FS.readdirSync NWEditor.Path.dirname _path
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
      @loaded = false
      
    clear: ->
      @files = []
      @directories = []
      @loaded = false
      
    loadChildren: ->
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