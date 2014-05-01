Tabs =
  controller: class
    constructor: ->
      
    editor: null
  
    isActive: (session) ->
      @editor?.getSession() is session
      
    update: (session) ->
      @editor?.setSession session
      
    filename: (path) ->
      NWEditor.Path.basename path
      
    close: (session) ->
      do session.watcher?.close
      NWEditor.Sessions = _.filter NWEditor.Sessions, (innerSession) -> innerSession isnt session
      if @editor.getSession() is session
        if NWEditor.Sessions.length isnt 0
          @editor.setSession _.last(NWEditor.Sessions)
        else
          do @editor.newFile
      NWEditor.State.get().files = _.chain NWEditor.Sessions
                                    .filter (session) -> session.path isnt 'untitled.txt'
                                    .map (session) -> session.path
                                    .value()
      do NWEditor.State.get().Write
  
  view: (ctrl) ->
    NWEditor.Sessions.map (session, index) ->
      m '.tab',
          class: if ctrl.isActive session then 'active' else ''
        , [
          m 'span',
              onclick: () -> ctrl.update session
            , ctrl.filename session.path
          m 'a.status',
              onclick: () -> ctrl.close session
            , 'x'
        ]
        
Project =
  controller: class
    constructor: ->
      @collapsed = true
      
  view: (ctrl) ->
    m '#project',
        class: if ctrl.collapsed then 'collapsed' else ''
        onmouseenter: () -> ctrl.collapsed = false
        onmouseleave: () -> ctrl.collapsed = true
      , ''

Editor =
  controller: class
    constructor: ->
      @tabsCtrl = new Tabs.controller
      @projectCtrl = new Project.controller
      
    state: do NWEditor.State.get
    themes: []
    modes: {modes: []}
    theme: ''
    
    showDevTools: ->
      do NWEditor.Window.showDevTools
      
    reload: ->
      do NWEditor.Window.reloadIgnoringCache
      
    changeTheme: (theme) ->
      @editor.setTheme theme
      @state.theme = theme
      do @state.Write
    
    setup: (element, isInitialized) =>
      unless isInitialized
        do @state.Load
        @editor = ace.edit element
        @editor.commands.addCommand command for command in commands
        
        @editor.loadFile = (content, path, save) =>
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
            @editor.loadFile '' + NWEditor.FS.readFileSync(path), path
          
          unless _.find(NWEditor.Sessions, (innerSession) -> innerSession.path is session.path)
            if replace
              NWEditor.Sessions[NWEditor.Sessions.indexOf(_.find NWEditor.Sessions, (foundSession) -> foundSession.path is origSession.path)] = session
            else
              NWEditor.Sessions.push session
          @editor.setSession session
          do @editor.navigateFileStart
          
          if save
            @state.files = _.chain NWEditor.Sessions
                            .filter (session) -> session.path isnt 'untitled.txt'
                            .map (session) -> session.path
                            .value()
            do @state.Write
          
        @editor.newFile = =>
          session = new ace.EditSession '', 'ace/mode/text'
          session.path = 'untitled.txt'
          @editor.setSession session
          NWEditor.Sessions.push session
        
        @tabsCtrl.editor = @editor
        @themes = ace.require('ace/ext/themelist').themes
        @modes = ace.require 'ace/ext/modelist'
        ace.config.set 'workerPath', 'js/workers'
        @theme = @state.theme || 'ace/theme/chrome'
        @editor.setTheme @theme
        if @state.files.length then @editor.loadFile '' + NWEditor.FS.readFileSync(file), file for file in @state.files else do @editor.newFile
    
  view: (ctrl) -> [
    m '.holder', [
      new Project.view ctrl.projectCtrl
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
                selected: mode.mode is ctrl.editor.getSession().$modeId
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
              ctrl.editor.loadFile '' + data, path, true
              do m.redraw
            else
              alert err
          this.value = ''
    m 'input#saveFile',
        type: 'file'
        nwsaveas: ''
        onchange: ->
          session = do ctrl.editor.getSession
          NWEditor.FS.writeFile this.value, ctrl.editor.getValue()
          ctrl.state.files = _.reject ctrl.state.files, (file) -> file is session.path
          #update editor path and state
          session.path = this.value
          ctrl.state.files.push this.value
          do ctrl.state.Write
          do m.redraw
  ]

m.module document.querySelector('div.editor'), Editor