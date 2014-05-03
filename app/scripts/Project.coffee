FileNode =
  controller: class
    constructor: (@file) ->
      
  view: (ctrl) ->
    m 'li.file', [
      m 'span',
          onclick: -> NWEditor.LoadFile ctrl.file, true, true
        , NWEditor.Path.basename ctrl.file
    ]

DirectoryTree =
  controller: class
    constructor: (@root) ->
      
    expand: ->
      do @root.LoadChildren
      
    collapse: =>
      do @root.Clear
      
  view: (ctrl) ->
    m 'li.directory', [
      m '.expander',
        class: if ctrl.root.loaded then 'expanded' else ''
      , '>'
      m 'span',
        onclick: -> if ctrl.root.loaded then do ctrl.collapse else do ctrl.expand
      , m.trust ctrl.root.name
      m 'ul.tree',
          class: if ctrl.root.loaded then 'expanded' else ''
        , [
          ctrl.root.directories.map (directory) ->
            new DirectoryTree.view(new DirectoryTree.controller directory)
          ctrl.root.files.map (file) ->
            new FileNode.view(new FileNode.controller file)
      ]
    ]

ProjectTree =
  controller: class
    constructor: ->
      @collapsed = true
      @project = do NWEditor.Project.get
      @state = do NWEditor.State.get
      @directoryListing = []
      
    populate: ->
      for path in @project.directories
        unless(_.find @directoryListing, (dir) -> dir.root is path)
          directory = new NWEditor.Directory path
          do directory.LoadChildren
          @directoryListing.push directory
      
  view: (ctrl) -> [
    m 'ul.tree.root', [
      do ctrl.populate && ctrl.directoryListing.map (directory) ->
        new DirectoryTree.view(new DirectoryTree.controller directory)
    ]
    m 'input#addDirectory',
        type: 'file'
        nwdirectory: true
        onchange: ->
          projectPath = @value
          unless _.find(ctrl.project.directories, (existingPath) -> existingPath is projectPath)
            ctrl.project.directories.push projectPath
            directory = new NWEditor.Directory projectPath
            do directory.LoadChildren
            ctrl.directoryListing.push directory
    m 'input#saveProject',
        type: 'file'
        nwsaveas: ''
        accept: '.nwproj'
        onchange: (evt) ->
          ctrl.project.Write @value
          ctrl.state.project = @value
          do ctrl.state.Write
  ]
  
m.module document.querySelector('div.project'), ProjectTree