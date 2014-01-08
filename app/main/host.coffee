module.exports = (app, plugin) ->
  
  app.on 'running', ->
    
    # app.db.on 'put', (key, val) ->
    #   console.log 'db:', key, '=', val
    # app.db.on 'batch', (array) ->
    #   console.log 'db#', array.length
    #   for x in array
    #     console.log ' ', x.key, '=', x.value
