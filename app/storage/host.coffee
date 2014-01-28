level = require 'level'
nulldel = require 'level-nulldel'

setupDatabase = (path) ->
  # the "nulldel" adds support for treating puts of null values as deletions
  db = nulldel level path, { valueEncoding: 'json' }, (err) ->
    throw err  if err
    if true
      # console.log 'db opened', db.db.getProperty 'leveldb.stats'
      db.db.approximateSize ' ', '~', (err, size) ->
        throw err  if err
        console.log 'storage size ~ %d bytes', size

  # internal helper to scan a specific range of keys
  keyBoundaryFinder = (from, to, rev) ->
    (prefix, cb) ->
      result = undefined
      db.createKeyStream
        start: prefix + from
        end: prefix + to
        reverse: rev
        limit: 1
      .on 'data', (data) ->
        result = data
      .on 'end', ->
        cb result

  db.firstKey = keyBoundaryFinder '~', '~~', false
  db.lastKey = keyBoundaryFinder '~~', '~', true

  # the dumb approach of scanning all keys to find the prefixes won't work for
  # lots of keys, we nned to skip over each prefix found when filling the list
  db.getPrefixDetails = (cb) ->
    result = {}

    # use a recursive function to handle the asynchronous callbacks
    iterator = (key) ->
      return cb result  unless key
      prefix = key.replace /~.*/, ''
      db.db.approximateSize prefix + '~', prefix + '~~', (err, size) ->
        throw err  if err
        result[prefix] = size
        keyBoundaryFinder(prefix + '~~', '~', false) '', iterator

    keyBoundaryFinder('', '~', false) '', iterator

  db.collectValues = (prefix, cb) ->
    result = []
    db.createValueStream
      start: prefix + '~'
      end: prefix + '~~'
      valueEncoding: 'json'
    .on 'data', (data) ->
      result.push data
    .on 'end', ->
      cb result

  # convert del events into put events, to match nulldel behaviour
  db.on 'del', (key) -> db.emit 'put', key

  db

module.exports = (app, plugin) ->
  app.db = setupDatabase './storage_old'

  # generate "top-level" events for changes, so that we can hook in per-prefix

  emitOnPrefix = (key, value) ->
    prefix = key.replace /~.*/, ''
    key = key.substr(prefix.length+1)
    value = JSON.parse value  if value?[0] is '{'
    app.emit "db.#{prefix}", key, value

  app.db.on 'put', emitOnPrefix
  app.db.on 'batch', (array) ->
    emitOnPrefix x.key, x.value  for x in array



  # capture all requests to set up a live feed
  app.on 'running', (primus) ->
    primus.on 'connection', (spark) ->
      console.log "primus connection"
      # create save event for different keys 

      spark.on 'saveToStorage', (data) ->
        console.log "test"

        key = data.prefix + "~" +data.key
        value = data.value
        
        if value?
          app.db.put key, value, (err) ->
            # read the whole store as a stream and print each entry to stdout
            app.db.createReadStream().on("data", console.log)
        else  
          app.db.del key, (err) ->
            # read the whole store as a stream and print each entry to stdout
            app.db.createReadStream().on("data", console.log)
      
      # create live event
      spark.on 'live', (prefix) ->
        console.info 'replay', prefix
        livePrefix = "live.#{prefix}"

        # create value stream to initialize nodes on client
        app.db.createReadStream
          start:  prefix
          end:    prefix + '\xFF'
          keys:   true
          #valueEncoding: 'json' #why does this not work?
        .on 'data', (data) ->
          #begin dirty workaround
          key = data.key
          value = data.value
          value = JSON.parse value  if value?[0] is '{'
          data = {key, value}
          #end dirty workaround
          spark.write [livePrefix, 'put', data]
        .on 'end', ->
          console.log 'live', prefix  

          # at db.#{prefix} event update the client
          app.on "db.#{prefix}", (key, value) ->
            if value?
              data = {key, value}
              spark.write [livePrefix, 'put', data]
              console.log "added " + key
            else
              data = {key, 'null'}
              spark.write [livePrefix, 'del', data]
              console.log "removed " + key