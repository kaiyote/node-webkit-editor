module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON '_public/package.json'
    nodewebkit:
      options:
        version: "0.9.2"
        build_dir: './dist'
        #specifiy what to build
        mac: false
        win: true
        linux32: false
        linux64: false
      src: './_public/**/*'

  grunt.loadNpmTasks 'grunt-node-webkit-builder'
  
  grunt.registerTask 'fixWorkers', 'Copy all of the ace worker.js files into app/assets so that they will get copied to _public and work', () ->
    grunt.file.copy file, "app/assets/js/workers/#{file.split('/')[-1..-1]}" for file in [
            "bower_components/ace-builds/src-noconflict/worker-coffee.js"
            "bower_components/ace-builds/src-noconflict/worker-css.js"
            "bower_components/ace-builds/src-noconflict/worker-html.js"
            "bower_components/ace-builds/src-noconflict/worker-javascript.js"
            "bower_components/ace-builds/src-noconflict/worker-json.js"
            "bower_components/ace-builds/src-noconflict/worker-lua.js"
            "bower_components/ace-builds/src-noconflict/worker-php.js"
            "bower_components/ace-builds/src-noconflict/worker-xquery.js"
          ]
    
  grunt.registerTask 'default', ['nodewebkit']
