Editor =
  controller: class
    constructor: ->
      @tabsCtrl = new Tabs.controller
      @projectCtrl = new ProjectTree.controller
      
    state: do NWEditor.State.get
    themes: []
    modes: {modes: []}
    theme: ''
    
    showDevTools: ->
      do NWEditor.Window.showDevTools
      
    reload: ->
      do NWEditor.Window.reloadIgnoringCache
      
    changeTheme: (theme) ->
      NWEditor.Editor.setTheme theme
      @state.theme = theme
      do @state.Write
    
    setup: (element, isInitialized) =>
      unless isInitialized
        do @state.Load
        NWEditor.Editor = ace.edit element
        NWEditor.Editor.commands.addCommand command for command in commands
        
        NWEditor.Editor.loadFile = (content, path, save, activate) =>
          mode = @modes.getModeForPath path
          replace = false
          try
            origSession = _.find NWEditor.Sessions, (session) -> session.path is path or session.path is 'untitled.txt'
            if !origSession?
              session = new ace.EditSession content, mode.mode
            else if origSession.path is 'untitled.txt'
              replace = true
              session = new ace.EditSession content, mode.mode
            else
              session = origSession
          catch
            #something weird is going on, the first attempt to make an EditSession always fails because it can't call "split" on undefined
            #no idea why, but the second attempt works
            session = new ace.EditSession content, mode.mode
          session.path = path
          # close any file watcher we currently have
          do session.watcher?.close
          session.watcher = NWEditor.FS.watch path, (event, filename) =>
            do session.watcher.close
            NWEditor.Editor.loadFile '' + NWEditor.FS.readFileSync(path), path
          
          unless _.find(NWEditor.Sessions, (innerSession) -> innerSession.path is session.path)
            if replace
              NWEditor.Sessions[NWEditor.Sessions.indexOf(_.find NWEditor.Sessions, (foundSession) -> foundSession.path is origSession.path)] = session
            else
              NWEditor.Sessions.push session
          if activate
            NWEditor.Editor.setSession session
            do NWEditor.Editor.navigateFileStart
          
          if save
            @state.files = _.chain NWEditor.Sessions
                            .filter (session) -> session.path isnt 'untitled.txt'
                            .map (session) -> session.path
                            .value()
            do @state.Write
          
        NWEditor.Editor.newFile = =>
          session = new ace.EditSession '', 'ace/mode/text'
          session.path = 'untitled.txt'
          NWEditor.Editor.setSession session
          NWEditor.Sessions.push session
        
        @themes = ace.require('ace/ext/themelist').themes
        @modes = ace.require 'ace/ext/modelist'
        ace.config.set 'workerPath', 'js/workers'
        @theme = @state.theme || 'ace/theme/chrome'
        NWEditor.Editor.setTheme @theme
        if @state.files.length then NWEditor.Editor.loadFile '' + NWEditor.FS.readFileSync(file), file, false, true for file in @state.files else do NWEditor.Editor.newFile
        if @state.project then NWEditor.Project.get().Load @state.project
    
  view: (ctrl) -> [
    m '.holder', [
      new ProjectTree.view ctrl.projectCtrl
      m '.container', [
        m '.tabs', [
          new Tabs.view ctrl.tabsCtrl
        ]
        m '#editor', config: (element, isInitialized) -> ctrl.setup element, isInitialized
      ]
    ]
    m '.bottom-bar', [
      m '.position', 'lolz'
      m '.devTools', [
        m 'a', onclick: ctrl.reload, 'Reload'
        m 'a', onclick: ctrl.showDevTools, 'Show Dev Tools'
      ]
      m '.selectors', [
        m 'select.syntax', [
          ctrl.modes.modes.map (mode, index) ->
            m 'option',
                value: mode.mode
                selected: mode.mode is NWEditor.Editor?.getSession().$modeId
              , mode.caption
        ]
        m 'select.theme',
            onchange: (evt) ->
              ctrl.changeTheme evt.target.value
          , [
            ctrl.themes.map (theme, index) ->
              m 'option',
                  value: theme.theme
                  selected: theme.theme is ctrl.theme
                , theme.caption
        ]
      ]
    ]
    m 'input#openFile',
        type: 'file'
        onchange: ->
          path = this.value
          NWEditor.FS.readFile path, null, (err, data) ->
            if !err
              NWEditor.Editor.loadFile '' + data, path, true, true
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

m.module document.querySelector('div.editor'), Editor
#tabs refuses to redraw the first time a session is added
do m.redraw