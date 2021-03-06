Footer =
  controller: class
    constructor: ->
      @themes = ace.require('ace/ext/themelist').themes
      @modes = ace.require 'ace/ext/modelist'
      
    changeTheme: (theme) ->
      NWEditor.Editor.setTheme theme
      NWEditor.State.get().theme = theme
      do NWEditor.State.get().Write
      
    changeMode: (mode) ->
      NWEditor.Editor.getSession().setMode mode
      
    showDevTools: ->
      do NWEditor.Window.showDevTools
      
    reload: ->
      do NWEditor.Window.reloadIgnoringCache
      
    collapseProject: ->
      if (project = document.querySelector '.project.collapsed') isnt null
        project.classList.remove 'collapsed'
      else
        document.querySelector('.project').classList.add 'collapsed'
      
  view: (ctrl) -> [
    m '.toggle-holder',
        onclick: () -> do ctrl.collapseProject
      , [1,2,3].map () ->
          m '.project-toggle',
              class: if document.querySelector '.project.collapsed' then 'expand' else ''
            , '<'
    m '.devTools', [
      m 'a', onclick: ctrl.reload, 'Reload'
      m 'a', onclick: ctrl.showDevTools, 'Show Dev Tools'
    ]
    m '.selectors', [
      m 'select.syntax',
          onchange: (evt) -> ctrl.changeMode evt.target.value
        , [
          ctrl.modes.modes.map (mode, index) ->
            m 'option',
                value: mode.mode
                selected: mode.mode is NWEditor.Editor?.getSession().$modeId
              , mode.caption
      ]
      m 'select.theme',
          onchange: (evt) -> ctrl.changeTheme evt.target.value
        , [
          ctrl.themes.map (theme, index) ->
            m 'option',
                value: theme.theme
                selected: theme.theme is NWEditor.Editor?.getTheme()
              , theme.caption
      ]
    ]
  ]
    
m.module document.querySelector('div.bottom-bar'), Footer