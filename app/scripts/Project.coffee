FileNode =
  controller: class
    constructor: (@file) ->
      
  view: (ctrl) ->
    m '.tree', [
      m 'span', NWEditor.Path.basename ctrl.file
    ]

DirectoryTree =
  controller: class
    constructor: (@root) ->
      
    loadChildren: ->
      files = NWEditor.FS.readdirSync @root.root
      for file in files
        if file[0] isnt '.'
          filePath = NWEditor.Path.join @root.root, file
          stat = NWEditor.FS.statSync filePath
          if do stat.isDirectory
            @root.directories.push new NWEditor.Directory filePath
          else
            @root.files.push filePath
      
  view: (ctrl) ->
    m '.tree', [
      m 'div',
        onclick: -> do ctrl.loadChildren
      , m 'span', ctrl.root.name
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
      @rootCtrl = new DirectoryTree.controller
      @directoryListing = []
      
  view: (ctrl) -> [
    m '#project',
        class: if ctrl.collapsed then 'collapsed' else ''
        onmouseenter: () -> ctrl.collapsed = false
        onmouseleave: () -> ctrl.collapsed = true
      , [
        m '.project-name', ctrl.project.name
        ctrl.directoryListing.map (directory) ->
          new DirectoryTree.view(new DirectoryTree.controller directory)
      ]
    m 'input#addDirectory',
        type: 'file'
        nwdirectory: true
        onchange: ->
          projectPath = @value
          unless _.find(ctrl.project.directories, (existingPath) -> existingPath is projectPath)
            ctrl.project.directories.push projectPath
            ctrl.directoryListing.push new NWEditor.Directory projectPath
    m 'input#saveProjectAs',
        type: 'file'
        nwsaveas: ''
        onchange: (evt) ->
          ctrl.project.Write @value
          ctrl.state.project = @value
          do ctrl.state.Write
  ]