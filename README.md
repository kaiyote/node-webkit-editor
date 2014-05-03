Yet Another Desktop Polyglot Editor (YADPE)
===========================================

This is based almost completely on Caret (https://github.com/thomaswilburn/Caret).

Caret is an amazing editor, but the fact that it is a Chrome App prevents me from being able to use it
as my default editor in Windows/Mac/Linux.  As such, and as an excuse to write more Coffeescript, Jade, & Stylus,
I have decided to write my own editor based on the Ace Editor that runs completely offline, and has file access, and
is a legitimate executable file using node-webkit.

When this is finally complete, it will be a semi-ide.
It will have as many integrated console windows as you want, so that you can have your file watchers/compilers/random 
console dev tools running inside of your editor.  It will be glorious.  But that is relatively far in the future.
For now, it will just be a relatively attractive editor, with syntax highlighting, that you will hopefully be able to
set as your default text editor in your OS of choice.

Current Working Features
========================
- Open/Save/Save-As/New File
- Auto-reload when file changes outside the editor
- Tabbed editor
- Themes
- Syntax Highlighting
- Cross-Session state
- Project/Tree-View

Yet-to-be-implemented Features
=============================
- Menus
- Settings
- Integrated Consoles
