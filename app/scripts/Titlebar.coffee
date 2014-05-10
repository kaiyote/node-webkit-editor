Menubar =
  controller: class
    constructor: ->
      _.mixin deepExtend: underscoreDeepExtend _
      try
        @userMenu = JSON.parse '' + NWEditor.FS.readFileSync NWEditor.Path.join process.env.HOME || process.env.USERPROFILE, '.nweditor', 'menu.json'
      catch
        @userMenu = {}
      @menu = _.deepExtend JSON.parse('' + NWEditor.FS.readFileSync 'settings/menu.json'), @userMenu
      
      document.body.onclick = (evt) ->
        document.querySelector('ul.menu.active')?.classList.remove 'active' unless evt.target.webkitMatchesSelector '.menubar *'
      
    toggleMenu: (evt) ->
      target = evt.target.nextSibling
      applyActive = !target.classList.contains 'active'
      document.querySelector('ul.menu.active')?.classList.remove 'active'
      target.classList.add 'active' if applyActive
      
    toggleMenuMotion: (evt) ->
      if document.querySelector('ul.menu.active')?
        document.querySelector('ul.menu.active')?.classList.remove 'active'
        evt.target.nextSibling?.classList.add 'active'
    
    runCommand: (command) ->
      NWEditor.Editor.execCommand command
      document.querySelector('ul.menu.active')?.classList.remove 'active'
      
  view: (ctrl) ->
    m 'ul.menubar', [
      _.keys(ctrl.menu).map (item) ->
        m 'li', [
          m 'span',
            onclick: ctrl.toggleMenu
            onmousemove: ctrl.toggleMenuMotion
          , item
          m 'ul.menu', [
            _.keys(ctrl.menu[item]).map (subItem) ->
              m 'li',
                onclick: () -> ctrl.runCommand ctrl.menu[item][subItem]
              , [
                m 'span', subItem
                m 'span.shortcut', NWEditor.Editor?.commands.byName[ctrl.menu[item][subItem]].bindKey.win
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