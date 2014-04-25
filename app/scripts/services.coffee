'use strict'

class Session
  fs = require 'fs'
  path = require 'path'
  sessionPath = path.join process.env.HOME || process.env.USERPROFILE, '.nweditor', 'session.json'

  constructor: ->
    try
        @state = JSON.parse '' + fs.readFileSync sessionPath
        if !@state.files?
          @state.files = []
        if !@state.mode?
          @state.mode = 'ace/mode/text'
        if !@state.theme
          @state.theme = ''
        if !@state.paths
          @state.paths = []
      catch
        #no session to load
        @state =
          files: []
          mode: 'ace/mode/text'
          theme: ''
          paths: []
  
  writeSession: ->
    try
      fs.readdirSync path.dirname sessionPath
    catch
      #doesn't exist, so make it
      fs.mkdirSync path.dirname sessionPath
    fs.writeFileSync sessionPath, JSON.stringify @state

angular.module 'app.services', []
.service 'Session', Session
