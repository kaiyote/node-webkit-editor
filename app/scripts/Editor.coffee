Tabs =
  controller: class
    constructor: (@sessions)->
      
    editor: m.prop null
  
    isActive: (path) ->
      @editor()?.getSession().path is path
      
    update: (session) =>
      currentActive = document.querySelector 'div.tab.active'
      nextActive = document.querySelector("span[data-text='#{@filename session.path}']").parentElement
      currentActive?.classList.remove 'active'
      nextActive?.classList.add 'active'
      
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
      @sessions = [{path: 'test.txt'}]
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
      
    setup: ->
      do @state.Load
      @editor = ace.edit 'editor'
      @tabsCtrl.editor @editor
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