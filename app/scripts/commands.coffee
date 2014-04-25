commands = [
  name: 'open'
  bindKey:
    win: 'Ctrl-O'
    mac: 'Command-O'
  exec: (editor) ->
    document.querySelector('#openFile').click()
  readOnly: true # false if this command should not apply in readOnly mode
,
  name: 'save'
  bindKey:
    win: 'Ctrl-S'
    mac: 'Command-S'
  exec: (editor) ->
    fs = require 'fs'
    session = do editor.getSession
    unless session.path is 'untitled.txt'
      do session.watcher?.close
      fs.writeFile session.path, editor.getValue(), () ->
        session.watcher = fs.watch session.path, (event, filename) ->
          do session.watcher.close
          editor.loadFile '' + fs.readFileSync(session.path), session.path
    else
      document.querySelector('#saveFile').click()
  readOnly: false
,
  name: 'saveAs'
  bindKey:
    win: 'Ctrl-Shift-S'
    mac: 'Command-Shift-S'
  exec: (editor) ->
    document.querySelector('#saveFile').click()
  readOnly: false
,
  name: 'newFile'
  bindKey:
    win: 'Ctrl-N'
    mac: 'Command-N'
  exec: (editor) ->
    do editor.newFile true
  readOnly: false
,
  name: 'addDirectory'
  bindKey:
    win: 'Ctrl-.'
    mac: 'Command-.'
  exec: (editor) ->
    document.querySelector('#addDirectory').click()
  readOnly: true
]