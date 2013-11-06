level = require 'level'
nulldel = require 'level-nulldel'


module.exports = (app, plugin) ->
  
  #create database  
  app.db2 = level("./view5.db")

  # emit functioncall on change
  emitOnPrefix = (key, value) ->
    prefix = "view5"
    app.emit "db2.#{prefix}", key, value 
      
  app.db2.on 'put', emitOnPrefix
  app.db2.on 'del', emitOnPrefix
  app.db2.on 'batch', (array) ->
    emitOnPrefix x.key, x.value  for x in array

  # capture all requests to set up a live feed
  app.on 'running', (primus) ->
    primus.on 'connection', (spark) ->
      spark.on 'save', (data) ->
        # put key and value in database
        key = data.prefix + "~" +data.key
        value = data.value
        
        if value? 
          app.db2.put key, value, (err) ->
            # read the whole store as a stream and print each entry to stdout
            app.db2.createReadStream().on("data", console.log)
        else  
          app.db2.del key, (err) ->
            # read the whole store as a stream and print each entry to stdout
            app.db2.createReadStream().on("data", console.log)
#          
      spark.on 'dead', (prefix) ->
        console.info 'replay', prefix
        livePrefix = "dead.#{prefix}"
        
        app.db2.createReadStream
          start:  prefix
          end:    prefix + '\xFF'
          keys:   true
          # valueEncoding: 'json'
        .on 'data', (data) ->
          # console.info data
          spark.write [livePrefix, 'put', data]
        .on 'end', ->
          console.log 'dead', prefix
          
          app.on "db2.#{prefix}", (key, value) ->
            # console.info "db2.#{prefix}"
            if value? or value isnt ""
              data = {key, value}
              spark.write [livePrefix, 'put', data]
              console.log "added" + key
            else
              data = {key, 'null'}
              spark.write [livePrefix, 'del', data]
              console.log "removed" + key

      spark.on 'getdb', (prefix) ->
        livePrefix = "getdb.#{prefix}"
        
        app.db2.createReadStream
          start:  prefix
          end:    prefix + '\xFF'
          keys:   true
          # valueEncoding: 'json'
        .on 'data', (data) ->
          # console.info data
          spark.write [livePrefix, 'put', data]
        .on 'end', ->
          console.log 'getdb', prefix
          

