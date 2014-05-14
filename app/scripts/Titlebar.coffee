MenuItem =
  controller: class
    constructor: (@parent, @key, @nested) ->
      
    runCommand: (command) ->
      NWEditor.Editor.execCommand command
      document.querySelector('ul.menu.active')?.classList.remove 'active'
      
    expandSubMenu: (evt) ->
      evt.target.parentElement.lastChild.classList?.add 'active'
      
    hideSubMenus: ->
      if !@nested
        _.each document.querySelectorAll('ul.menu ul.menu.active'), (element) ->
          element.classList.remove 'active'
    
    renderSubMenu: (type, menuItem) ->
      if type is 'nested'
        m 'ul.menu', [
          _.keys(menuItem).map (item) ->
            new MenuItem.view(new MenuItem.controller menuItem, item, true)
        ]
      
  view: (ctrl) ->
    menuItem = ctrl.parent[ctrl.key]
    menuType = if typeof menuItem is 'string' then 'command' else 'nested'
    m 'li',
        onclick: () -> if menuType is 'command' then ctrl.runCommand menuItem
        onmouseover: (evt) -> if menuType is 'nested' then ctrl.expandSubMenu evt else do ctrl.hideSubMenus
      , [
        m 'span.label', ctrl.key
        m 'span.shortcut', if menuType is 'command' then NWEditor.Editor?.commands.byName[menuItem]?.bindKey?[if do NWEditor.OS.platform is 'darwin' then 'mac' else 'win'] else '>'
        ctrl.renderSubMenu menuType, menuItem
      ]

Menubar =
  controller: class
    constructor: ->
      try
        userDelta = JSON.parse '' + NWEditor.FS.readFileSync NWEditor.Path.join process.env.HOME || process.env.USERPROFILE, '.nweditor', 'menu.json'
        @menu = jsondiffpatch.patch JSON.parse('' + NWEditor.FS.readFileSync 'settings/menu.json'), userDelta
      catch
        #either the patch file doesn't exist, or it's poorly formed, use default menu
        @menu = JSON.parse '' + NWEditor.FS.readFileSync 'settings/menu.json'
      
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
              new MenuItem.view(new MenuItem.controller ctrl.menu[item], subItem)
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
    m 'b.app-name',
      class: if do NWEditor.OS.platform is 'darwin' then 'mac' else ''
    , 'Node Webkit Editor'
    new Menubar.view ctrl.menuCtrl
    m '.window-controls',
      class: if do NWEditor.OS.platform is 'darwin' then 'mac' else ''
    , [
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