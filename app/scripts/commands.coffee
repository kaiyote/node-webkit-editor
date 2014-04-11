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
    fs.writeFile editor.path, editor.getValue()
  readOnly: false
,
  name: 'saveAs'
  bindKey:
    win: 'Ctrl-Shift-S'
    mac: 'Command-Shift-S'
  exec: (editor) ->
    document.querySelector('#saveFile').click()
  readOnly: false
]