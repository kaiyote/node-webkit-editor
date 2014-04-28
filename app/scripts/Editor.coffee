Editor =
  controller: ->
    @state = new NWEditor.State
    
    @showDevTools = ->
      do NWEditor.Window.showDevTools
      
    @reload = ->
      do NWEditor.Window.reloadIgnoringCache
      
    
    
  view: (ctrl) ->
    
  