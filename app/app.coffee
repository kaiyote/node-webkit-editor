'use strict'

NWEditor =
  FS: require 'fs'
  Path: require 'path'
  Window: do require('nw.gui').Window.get
  State: ->
    if NWEditor.State.prototype._singletonInstance?
      return NWEditor.State.prototype._singletonInstance
    NWEditor.State.prototype._singletonInstance = this
    
    _filename = NWEditor.Path.join process.env.HOME || process.env.USERPROFILE, '.nweditor', 'session.json'
    
    @Load = ->
      try
        NWEditor.FS.readFile _filename, (err, data) =>
          if !err
            data = JSON.parse data
            @files = m.prop data.files or []
            @theme = m.prop data.theme or ''
            @paths = m.prop data.paths or []
            @project = m.prop data.project or ''
          else
            #file doesn't exist, continue onwards
            @files = m.prop []
            @theme = m.prop ''
            @paths = m.prop []
            @project = m.prop ''
      catch
        #file doesn't exist, continue onwards
        @files = m.prop []
        @theme = m.prop ''
        @paths = m.prop []
        @project = m.prop ''
        
    @Write = ->
      NWEditor.FS.writeFile _filename, JSON.stringify this
    
    this