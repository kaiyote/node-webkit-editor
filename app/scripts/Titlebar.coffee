Titlebar =
  controller: class
    constructor: ->
      NWEditor.Window.removeAllListeners 'maximize'
      NWEditor.Window.on 'maximize', () =>
        @maximized = true
        #have to force it because the redraw appears to happen before these events fire
        do m.redraw
      
      NWEditor.Window.removeAllListeners 'unmaximize'
      NWEditor.Window.on 'unmaximize', () =>
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
    #m 'menubar'
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