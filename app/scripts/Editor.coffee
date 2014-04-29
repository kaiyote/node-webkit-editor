Tabs =
  controller: class
    constructor: (@sessions)->
      
    editor: null
  
    isActive: (path) ->
      @editor?.getSession().path is path
      
    update: (session) =>
      currentActive = document.querySelector 'div.tab.active'
      nextActive = document.querySelector("span[data-text='#{@filename session.path}']").parentElement
      currentActive?.classList.remove 'active'
      nextActive?.classList.add 'active'
      
      @editor?.setSession session
      
    filename: (path) ->
      NWEditor.Path.basename path
      
    close: ->
      console.log this
  
  view: (ctrl) ->
    ctrl.sessions.map (session, index) ->
      m '.tab',
          class: if ctrl.isActive session.path then 'active' else ''
        , [
          m 'span',
              onclick: -> ctrl.update session
              'data-text': ctrl.filename session.path
            , ctrl.filename session.path
          m 'a.status', onclick: ctrl.close, 'x'
        ]

Editor =
  controller: class
    constructor: ->
      @sessions = []
      @tabsCtrl = new Tabs.controller(@sessions)
      
    state: do NWEditor.State.get
    themes: []
    modes: {modes: []}
    theme: ''
    mode: 'ace/mode/text'
    
    showDevTools: ->
      do NWEditor.Window.showDevTools
      
    reload: ->
      do NWEditor.Window.reloadIgnoringCache
      
    setup: =>
      do @state.Load
      @editor = ace.edit 'editor'
      
      @editor.loadFile = (content, path, save) =>
        mode = @modes.getModeForPath path
        try
          session = _.find @sessions, (session) -> session.path is path or session.path is 'untitled.txt'
          if !session?
            session = new ace.EditSession content, mode.mode
          else if session.path is 'untitled.txt'
            session.setDocument new Document content
            session.setMode mode.mode
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
        
        @sessions.push session unless _.find @sessions, (innerSession) -> innerSession.path is session.path
        @editor.setSession session
        do @editor.navigateFileStart
        
        @mode = mode.mode
        if save
          @state.files.push path
          do @state.Write
        
      @editor.newFile = =>
        session = new ace.EditSession '', 'ace/mode/text'
        session.path = 'untitled.txt'
        @editor.setSession session
        @sessions.push session
        @mode = 'ace/mode/text'
      
      @tabsCtrl.editor = @editor
      @themes = ace.require('ace/ext/themelist').themes
      @modes = ace.require 'ace/ext/modelist'
      ace.config.set 'workerPath', 'js/workers'
      @theme = @state.theme || 'ace/theme/chrome'
      if @state.files.length then @editor.loadFile file for file in @state.files else do @editor.newFile
    
  view: (ctrl) -> [
    m '.tabs', [
      new Tabs.view ctrl.tabsCtrl
    ]
    m '#editor', config: -> ctrl.setup()
    m '.bottom-bar', [
      m '.position', 'lolz'
      m '.devTools', [
        m 'a', onclick: ctrl.reload, 'Reload'
        m 'a', onclick: ctrl.showDevTools, 'Show Dev Tools'
      ]
      m '.selectors', [
        m 'select.syntax', [
          ctrl.modes.modes.map (mode, index) ->
            m 'option', value: mode.mode, mode.caption
        ]
        m 'select.theme', [
          ctrl.themes.map (theme, index) ->
            m 'option', value: theme.theme, theme.caption
        ]
      ]
    ]
  ]

m.module document.querySelector('div.holder'), Editor