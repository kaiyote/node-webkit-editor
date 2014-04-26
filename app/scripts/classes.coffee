class Directory
  fs = require 'fs'
  path = require 'path'
  
  constructor: (root) ->
    @root = root
    @files = []
    @dirs = []
    @name = path.basename root
  
  loadChildren: ->
    self = this
    fs.readdir @root, (err, files) ->
      for file in files
        if file[0] isnt '.'
          filePath = path.join self.root, file
          stat = fs.statSync filePath
          if do stat.isDirectory
            self.dirs.push new Directory filePath
          else
            self.files.push filePath
    
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
      if !@state.project
        @state.project = ''
    catch
      #no session to load
      @state =
        files: []
        mode: 'ace/mode/text'
        theme: ''
        paths: [],
        project: ''
  
  writeSession: ->
    try
      fs.readdirSync path.dirname sessionPath
    catch
      #doesn't exist, so make it
      fs.mkdirSync path.dirname sessionPath
    fs.writeFileSync sessionPath, JSON.stringify @state
    
class Project
  fs = require 'fs'
  path = require 'path'
  
  constructor: ->
    @project =
      directories: []
      name: 'project!!!'
    
  loadProject: (projectFile) ->
    @path = projectFile
    try
      @project = JSON.parse '' + fs.readFileSync @path
      if !@project.directories?
        @project.directories = []
      if !@project.name?
        @project.name = ''
    catch
      #no session to load
      @project =
        directories: []
        name: 'project!!!'
        
  writeProject: ->
    try
      fs.readdirSync path.dirname @path
    catch
      #doesn't exist, so make it
      fs.mkdirSync path.dirname @path
    fs.writeFileSync @path, JSON.stringify @project