FileNode =
  controller: class
    constructor: (@file) ->
      
  view: (ctrl) ->
    m '.tree.file', [
      m 'span',
          onclick: -> NWEditor.Editor.loadFile '' + NWEditor.FS.readFileSync(ctrl.file), ctrl.file, true, true
        , NWEditor.Path.basename ctrl.file
    ]

DirectoryTree =
  controller: class
    constructor: (@root) ->
      @loaded = false
      
    expand: ->
      do @root.loadChildren
      
    collapse: ->
      do @root.clear
      
  view: (ctrl) ->
    m '.tree', [
      m '.tree-container', [
        m '.expander',
            class: if ctrl.root.loaded then 'expanded' else ''
          , '>'
        m 'span',
          onclick: -> if ctrl.root.loaded then do ctrl.collapse else do ctrl.expand
        , ctrl.root.name
      ]
      ctrl.root.directories.map (directory) ->
        new DirectoryTree.view(new DirectoryTree.controller directory)
      ctrl.root.files.map (file) ->
        new FileNode.view(new FileNode.controller file)
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
          do directory.loadChildren
          @directoryListing.push directory
      
  view: (ctrl) -> [
    m '#project',
        class: if ctrl.collapsed then 'collapsed' else ''
        onmouseenter: () -> ctrl.collapsed = false
        onmouseleave: () -> ctrl.collapsed = true
      , [
        m '.project-name', ctrl.project.name
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
            do directory.loadChildren
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