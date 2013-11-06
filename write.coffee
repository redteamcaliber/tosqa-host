#!/usr/bin/env coffee
# This standalone script dumps all stored data to stdout

level = require('level')

# open a data store
db = level("./newdb.db")

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
    value: "8 January 1983"
  ,
    type: "put"
    key: "occupation"
    value: "Clown"
  ], (err) ->
    
    # read the whole store as a stream and print each entry to stdout
    db.createReadStream().on("data", console.log).on "close", ->
      db.close()