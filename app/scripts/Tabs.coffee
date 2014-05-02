Tabs =
  controller: class
    constructor: ->
      @state = NWEditor.State.get()
  
    isActive: (session) ->
      NWEditor.Editor?.getSession() is session
      
    update: (session) ->
      NWEditor.Editor?.setSession session
      
    filename: (path) ->
      NWEditor.Path.basename path
      
    close: (session) ->
      do session.watcher?.close
      NWEditor.Sessions = _.filter NWEditor.Sessions, (innerSession) -> innerSession isnt session
      if NWEditor.Editor.getSession() is session
        if NWEditor.Sessions.length isnt 0
          NWEditor.Editor.setSession _.last(NWEditor.Sessions)
        else
          do NWEditor.Editor.newFile
      @state.files = _.chain NWEditor.Sessions
                                    .filter (session) -> session.path isnt 'untitled.txt'
                                    .map (session) -> session.path
                                    .value()
      do @state.Write
  
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