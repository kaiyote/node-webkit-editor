Editor =
  controller: class
    constructor: ->
      @tabsCtrl = new Tabs.controller
      @state = do NWEditor.State.get
      ace.config.set 'workerPath', 'js/workers'
      
      try
        userDelta = JSON.parse '' + NWEditor.FS.readFileSync NWEditor.Path.join process.env.HOME || process.env.USERPROFILE, '.nweditor', 'settings.json'
        @settings = jsondiffpatch.patch JSON.parse('' + NWEditor.FS.readFileSync 'settings/settings.json'), userDelta
      catch
        #either the patch file doesn't exist, or it's poorly formed, use default settings
        @settings = JSON.parse '' + NWEditor.FS.readFileSync 'settings/settings.json'
    
    setup: (element, isInitialized) =>
      unless isInitialized
        NWEditor.Editor = ace.edit element
        NWEditor.Editor.commands.addCommand command for command in commands
        
        settingFunctions = ace.require('ace/ext/menu_tools/get_set_functions').getSetFunctions NWEditor.Editor
        
        _.keys(@settings).forEach (setting) =>
          settingFunction = _.find settingFunctions, (item) -> item.functionName is "set#{setting.replace ' ', ''}"
          settingFunction.parentObj[settingFunction.functionName] @settings[setting] if settingFunction
        
        NWEditor.Editor.setTheme @state.theme || 'ace/theme/chrome'
        if @state.files.length then NWEditor.LoadFile file, false, true for file in @state.files else do NWEditor.NewFile
    
  view: (ctrl) -> [
    m '.tabs', [
      new Tabs.view ctrl.tabsCtrl
    ]
    m '#editor', config: (element, isInitialized) -> ctrl.setup element, isInitialized
    m 'input#openFile',
        type: 'file'
        onchange: ->
          path = this.value
          NWEditor.FS.readFile path, null, (err, data) ->
            if !err
              NWEditor.LoadFile path, true, true
              do m.redraw
            else
              alert err
          this.value = ''
    m 'input#saveFile',
        type: 'file'
        nwsaveas: ''
        onchange: ->
          session = do NWEditor.Editor.getSession
          NWEditor.FS.writeFile this.value, NWEditor.Editor.getValue()
          ctrl.state.files = _.reject ctrl.state.files, (file) -> file is session.path
          #update editor path and state
          session.path = this.value
          ctrl.state.files.push this.value
          do ctrl.state.Write
          do m.redraw
  ]

m.module document.querySelector('div.container'), Editor
#tabs refuses to redraw the first time a session is added
do m.redraw