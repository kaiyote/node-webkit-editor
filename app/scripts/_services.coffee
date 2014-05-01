'use strict'

angular.module 'app.services', []
.service 'Session', Session
.service 'Project', Project
.factory 'RecursionHelper', [
  '$compile'
  ($compile) ->
    compile: (element, link) ->
      if angular.isFunction link
        link = post: link
          
      contents = element.contents().remove()
      
      pre: if (link && link.pre) then link.pre else null
      post: (scope, element) ->
        if !compiledContents
          compiledContents = $compile contents
        
        compiledContents scope, (clone) ->
          element.append clone
        
        if link && link.post
          link.post.apply null, arguments
]