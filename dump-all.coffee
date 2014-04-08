#!/usr/bin/env coffee
# This standalone script dumps all stored data to stdout

level = require 'level'
db = level 'data'
db.createReadStream().on 'data', (data) ->
  console.log data.key, '=', data.value
