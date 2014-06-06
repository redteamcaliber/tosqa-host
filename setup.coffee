#!/usr/bin/env coffee

circuits = {}

# tosqa-host setup
circuits.main =
  gadgets: [
    { name: "http", type: "HTTPServer" }
    { name: "init", type: "init" }
  ]
  feeds: [
    { tag: "/", data: "./app",  to: "http.Handlers" }
    { tag: "/base/", data: "./base",  to: "http.Handlers" }
    { tag: "/ws", data: "<websocket>",  to: "http.Handlers" }
    { data: ":3333",  to: "http.Port" }
  ]

# init circuit for HouseMon, which starts its own http server.
circuits.init =
  gadgets: [
    { name: "reload", type: "WSLiveReload" } # needed if using node in dev mode
    { name: "dummy", type: "Pipe" } # needed for dispatcher in HouseMon
    { name: "driverFill", type: "driverFill" } # pre-load the database
    { name: "tableFill", type: "tableFill" }   # pre-load the database
  ]
  labels: [
    { external: "In", internal: "dummy.In" }
    { external: "Out", internal: "dummy.Out" }
  ]

# define the websocket handler using a loop in and out of RpcHandler
circuits["WebSocket-tosqa"] =
  gadgets: [
    { name: "rpc", type: "RpcHandler" }
  ]
  labels: [
    { external: "In", internal: "rpc.In" }
    { external: "Out", internal: "rpc.Out" }
  ]

# simple never-ending demo
circuits.demo =
  gadgets: [
    { name: "c", type: "Clock" }
  ]
  feeds: [
    { data: "1s", to: "c.Rate" }
  ]
  
# pre-load some table info into the database
circuits.tableFill =
  gadgets: [
    { name: "db", type: "LevelDB" }
  ]
  feeds: [
    { to: "db.In", tag: "/table/table", data: { attr: "id attr" } }
    { to: "db.In", tag: "/column/table/id", data: { name: "Ident" } }
    { to: "db.In", tag: "/column/table/attr", data: { name: "Attributes" } }

    { to: "db.In", tag: "/table/column", data: { attr: "id name" } }
    { to: "db.In", tag: "/column/column/id", data: { name: "Ident" } }
    { to: "db.In", tag: "/column/column/name", data: { name: "Name" } }

    { to: "db.In", tag: "/table/driver", data: { attr: "id name unit factor scale" } }
    { to: "db.In", tag: "/column/driver/id", data: { name: "Parameter" } }
    { to: "db.In", tag: "/column/driver/name", data: { name: "Name" } }
    { to: "db.In", tag: "/column/driver/unit", data: { name: "Unit" } }
    { to: "db.In", tag: "/column/driver/factor", data: { name: "Factor" } }
    { to: "db.In", tag: "/column/driver/scale", data: { name: "Scale" } }

    { to: "db.In", tag: "/table/reading", data: { attr: "id loc val ms typ" } }
    { to: "db.In", tag: "/column/reading/id", data: { name: "Ident" } }
    { to: "db.In", tag: "/column/reading/loc", data: { name: "Location" } }
    { to: "db.In", tag: "/column/reading/val", data: { name: "Values" } }
    { to: "db.In", tag: "/column/reading/ms", data: { name: "Timestamp" } }
    { to: "db.In", tag: "/column/reading/typ", data: { name: "Type" } }
  ]

# trial circuit
circuits.try1 =
  gadgets: [
    { name: "db", type: "LevelDB" }
  ]
  feeds: [
    { tag: "<range>", data: "/reading/", to: "db.In" }
  ]

# write configuration to file, but keep a backup of the original, just in case
fs = require 'fs'
try fs.renameSync 'setup.json', 'setup-prev.json'
fs.writeFileSync 'setup.json', JSON.stringify circuits, null, 4
