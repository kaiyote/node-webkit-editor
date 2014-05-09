Editor =
  controller: class
    constructor: ->
      @tabsCtrl = new Tabs.controller
      @projectCtrl = new ProjectTree.controller
      @state = do NWEditor.State.get
      ace.config.set 'workerPath', 'js/workers'
    
    setup: (element, isInitialized) =>
      unless isInitialized
        NWEditor.Editor = ace.edit element
        NWEditor.Editor.commands.addCommand command for command in commands
        
        NWEditor.Editor.setTheme @state.theme || 'ace/theme/chrome'
        if @state.files.length then NWEditor.LoadFile file, false, true for file in @state.files else do NWEditor.NewFile
    
  view: (ctrl) -> [
    m '.tabs', [
      new Tabs.view ctrl.tabsCtrl
    ]
    m '#editor', config: (element, isInitialized) -> ctrl.setup element, isInitialized
    m 'input#openFile',
        type: 'file'
        onchange: ->
          path = this.value
          NWEditor.FS.readFile path, null, (err, data) ->
            if !err
              NWEditor.LoadFile path, true, true
              do m.redraw
            else
              alert err
          this.value = ''
    m 'input#saveFile',
        type: 'file'
        nwsaveas: ''
        onchange: ->
          session = do NWEditor.Editor.getSession
          NWEditor.FS.writeFile this.value, NWEditor.Editor.getValue()
          ctrl.state.files = _.reject ctrl.state.files, (file) -> file is session.path
          #update editor path and state
          session.path = this.value
          ctrl.state.files.push this.value
          do ctrl.state.Write
          do m.redraw
  ]

m.module document.querySelector('div.container'), Editor
#tabs refuses to redraw the first time a session is added
do m.redraw