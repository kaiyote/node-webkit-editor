Menubar =
  controller: class
    constructor: ->
      
    toggleMenu: (evt) ->
      target = evt.target.nextSibling
      applyActive = !target.classList.contains 'active'
      document.querySelector('ul.menu.active')?.classList.remove 'active'
      target.classList.add 'active' if applyActive
    
    runCommand: (command) ->
      NWEditor.Editor.execCommand command
      document.querySelector('ul.menu.active')?.classList.remove 'active'
      
  view: (ctrl) ->
    m 'ul.menubar', [
      menu.map (item) ->
        m 'li', [
          m 'span',
            onclick: ctrl.toggleMenu
          , item.name
          m 'ul.menu', [
            item.subMenu.map (subItem) ->
              m 'li',
                onclick: () -> ctrl.runCommand subItem.command
              , [
                m 'span', subItem.name
                m 'span.shortcut', subItem.shortcut.win
              ]
          ]
        ]
    ]

Titlebar =
  controller: class
    constructor: ->
      @menuCtrl = new Menubar.controller
      
      NWEditor.Window.removeAllListeners 'maximize'
      NWEditor.Window.on 'maximize', =>
        @maximized = true
        #have to force it because the redraw appears to happen before these events fire
        do m.redraw
      
      NWEditor.Window.removeAllListeners 'unmaximize'
      NWEditor.Window.on 'unmaximize', =>
        @maximized = false
        do m.redraw
      
    maximized: false
    
    minimize: ->
      do NWEditor.Window.minimize
      
    maximize: ->
      if @maximized then do NWEditor.Window.unmaximize else do NWEditor.Window.maximize
      
    close: ->
      do NWEditor.Window.close
      
  view: (ctrl) -> [
    m 'b.app-name', 'Node Webkit Editor'
    new Menubar.view ctrl.menuCtrl
    m '.window-controls', [
      m 'a', onclick: ctrl.minimize, '-'
      m 'a',
          onclick: -> ctrl.maximize()
          class: if ctrl.maximized then 'maximized' else ''
        , [
          m 'div', m.trust '&and;'
        ]
      m 'a', onclick: ctrl.close, '~'
    ]
  ]

m.module document.querySelector('div.titlebar'), Titlebar