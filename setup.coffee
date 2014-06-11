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
    { name: "tableFill", type: "tableFill" }      # pre-load the database
    { name: "circuitFill", type: "circuitFill" }  # pre-load the database
    # { name: "cb", type: "CanBridge" }
    { name: "cb", type: "CanSerial" }
    { name: "sp", type: "SerialPort" }
    { name: "bm", type: "BootMaster" }
  ]
  feeds: [
    { data: "/dev/tty.usbserial-A6006eRB", to: "sp.Port" }
  ]
  wires: [
    { from: "cb.Out", to: "bm.In" }
    { from: "bm.Out", to: "cb.In" }
    { from: "sp.From", to: "cb.SerIn" }
    { from: "cb.SerOut", to: "sp.To" }
  ]
  labels: [
    { external: "In", internal: "dummy.In" }
    { external: "Out", internal: "dummy.Out" }
  ]

# define the websocket handler using a loop in and out of RpcHandler
circuits["WebSocket-jeebus"] =
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

# pre-load some circuit info into the database
circuits.circuitFill =
  gadgets: [
    { name: "db", type: "LevelDB" }
  ]
  feeds: [
    { to: "db.In", tag: "/circuit/demo1/g3", data: {
      x: 320, y:  60, title: 'StepGen-X',  type: 'StepGen'
      feed: { Params: [ 1000, 500 ] }
      wire: { Out: 'g4.Cmds' }
    }}
    { to: "db.In", tag: "/circuit/demo1/g4", data: {
      x: 540, y:  70, title: 'SSB-X',      type: 'SSB'
    }}
    { to: "db.In", tag: "/circuit/demo1/g5", data: {
      x: 340, y: 140, title: 'StepGen-Y',  type: 'StepGen'
      feed: { Params: [ 300, 900 ] }
      wire: { Out: 'g6.Cmds' }
    }}
    { to: "db.In", tag: "/circuit/demo1/g6", data: {
      x: 520, y: 150, title: 'SSB-Y',      type: 'SSB'
    }}
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
