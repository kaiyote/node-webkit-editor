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