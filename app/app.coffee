'use strict'

NWEditor =
  FS: require 'fs'
  Path: require 'path'
  Window: do require('nw.gui').Window.get
  State: class
    instance = null
    @get: ->
      instance ?= new State
  
    class State
      constructor: ->
        _filename = NWEditor.Path.join process.env.HOME || process.env.USERPROFILE, '.nweditor', 'session.json'
      
      Load: ->
        try
          NWEditor.FS.readFile _filename, (err, data) =>
            if !err
              data = JSON.parse data
              @files = data.files or []
              @theme = data.theme or ''
              @paths = data.paths or []
              @project = data.project or ''
            else
              #file doesn't exist, continue onwards
              @files = []
              @theme = ''
              @paths = []
              @project = ''
        catch
          #probably bad JSON, continue onwards
          @files = []
          @theme = ''
          @paths = []
          @project = ''
          
      Write: ->
        NWEditor.FS.writeFile _filename, JSON.stringify this