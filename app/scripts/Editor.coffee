Editor =
  controller: ->
    @state = new NWEditor.State
    @themes = m.prop []
    @modes = m.prop {modes: []}
    
    @showDevTools = ->
      do NWEditor.Window.showDevTools
      
    @reload = ->
      do NWEditor.Window.reloadIgnoringCache
      
    @setup = =>
      @editor = ace.edit 'editor'
      @themes(ace.require('ace/ext/themelist').themes)
      @modes(ace.require 'ace/ext/modelist')
      ace.config.set 'workerPath', 'js/workers'
      
    this
    
  view: (ctrl) -> [
    m '.tabs', [
      #tabs component
    ]
    m '#editor', config: ctrl.setup
    m '.bottom-bar', [
      m '.position', 'lolz'
      m '.devTools', [
        m 'a', onclick: ctrl.reload, 'Reload'
        m 'a', onclick: ctrl.showDevTools, 'Show Dev Tools'
      ]
      m '.selectors', [
        m 'select.syntax', [
          ctrl.modes().modes.map (mode, index) ->
            m 'option', value: mode.mode, mode.caption
        ]
        m 'select.theme', [
          ctrl.themes().map (theme, index) ->
            m 'option', value: theme.theme, theme.caption
        ]
      ]
    ]
  ]

m.module document.querySelector('div.holder'), Editor