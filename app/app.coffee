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
      
      Load: ->
        _filename = NWEditor.Path.join process.env.HOME || process.env.USERPROFILE, '.nweditor', 'session.json'
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
        _filename = NWEditor.Path.join process.env.HOME || process.env.USERPROFILE, '.nweditor', 'session.json'
        NWEditor.FS.writeFile _filename, JSON.stringify this
  Sessions: new Array
        
#clear off any listeners that might be hanging around across a refresh
NWEditor.Window.removeAllListeners 'on'