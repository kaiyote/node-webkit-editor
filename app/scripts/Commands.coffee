commands = [
  name: 'open'
  bindKey:
    win: 'Ctrl-O'
    mac: 'Command-O'
  exec: (editor) ->
    do document.querySelector('#openFile').click
  readOnly: true # false if this command should not apply in readOnly mode
,
  name: 'save'
  bindKey:
    win: 'Ctrl-S'
    mac: 'Command-S'
  exec: (editor) ->
    session = do editor.getSession
    unless session.path is 'untitled.txt'
      do session.watcher?.close
      NWEditor.FS.writeFile session.path, editor.getValue(), () ->
        session.watcher = NWEditor.FS.watch session.path, (event, filename) ->
          do session.watcher.close
          NWEditor.LoadFile session.path
    else
      do document.querySelector('#saveFile').click
  readOnly: false
,
  name: 'saveAs'
  bindKey:
    win: 'Ctrl-Shift-S'
    mac: 'Command-Shift-S'
  exec: (editor) ->
    do document.querySelector('#saveFile').click
  readOnly: false
,
  name: 'newFile'
  bindKey:
    win: 'Ctrl-N'
    mac: 'Command-N'
  exec: (editor) ->
    do NWEditor.NewFile
    do m.redraw
  readOnly: false
,
  name: 'addDirectory'
  bindKey:
    win: 'Ctrl-.'
    mac: 'Command-.'
  exec: (editor) ->
    document.querySelector('#addDirectory').click()
  readOnly: false
,
  name: 'saveProjectAs'
  bindKey:
    win: 'Ctrl-Alt-S'
    mac: 'Command-Alt-S'
  exec: (editor) ->
    document.querySelector('#saveProject').click()
  readOnly: false
,
  name: 'editSettings'
  exec: (editor) ->
    alert 'totally gonna edit the user settings soon'
  readOnly: true
,
  name: 'exit'
  bindKey:
    win: 'Ctrl-Q'
    mac: 'Command-Q'
  exec: (editor) ->
    do NWEditor.Window.close
  readOnly: true
]