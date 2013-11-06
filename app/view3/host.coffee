level = require('level')

module.exports = (app, plugin) ->  
  app.on 'setup', ->
  
    # RPC demo, returns an increasing counter, callable from clients
    counter = 0
    app.host.view3_next = ->
      ++counter
      console.log counter
      
      db = level("./view3db")      
      # open a data store
  
      # a simple Put operation
      db.put "name", "Kim Jong-un", (err) ->
        
        # a Batch operation made up of 3 Puts
        db.batch [
          type: "put"
          key: "spouse"
          value: "Ri Sol-ju"
        ,
          type: "put"
          key: "dob"
          value: "8 January 1985"
        ,
          type: "put"
          key: "occupation"
          value: "Clown"
        ], (err) ->
          
          # read the whole store as a stream and print each entry to stdout
          db.createReadStream().on("data", console.log).on "close", ->
            db.close()
            
         
            
