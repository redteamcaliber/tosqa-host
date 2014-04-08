circuit =
  "gadgets": [
    "name": "sp", "type": "SerialPort"
  ,
    "name": "rf", "type": "Sketch-RF12demo"
  ,
    "name": "sk", "type": "Sink"
  ,
    "name": "cf", "type": "ReadFileJSON"
  ,
    "name": "jb", "type": "JeeBoot"
  ,
    "name": "rd", "type": "ReadFileText"
  ,
    "name": "hx", "type": "IntelHexToBin"
  ,
    "name": "bf", "type": "BinaryFill"
  ,
    "name": "cs", "type": "CalcCrc16"
  ,
    "name": "bd", "type": "BootData"
  ,
    "name": "sv", "type": "BootServer"
  ]
  "wires": [
    "from": "sp.From", "to": "rf.In", "capacity": 0
  ,
    "from": "rf.Out", "to": "sv.In", "capacity": 0
  ,
    "from": "rf.Rej", "to": "sk.In", "capacity": 0
  ,
    "from": "rf.Oob", "to": "jb.In", "capacity": 0
  ,
    "from": "cf.Out", "to": "jb.Cfg", "capacity": 0
  ,
    "from": "jb.Files", "to": "rd.In", "capacity": 0
  ,
    "from": "rd.Out", "to": "hx.In", "capacity": 0
  ,
    "from": "hx.Out", "to": "bf.In", "capacity": 0
  ,
    "from": "bf.Out", "to": "cs.In", "capacity": 0
  ,
    "from": "cs.Out", "to": "bd.In", "capacity": 0
  ,
    "from": "jb.Out", "to": "sp.To", "capacity": 0
  ,
    "from": "sv.Out", "to": "sp.To", "capacity": 0
  ]
  "feeds": [
    "data": "/dev/ttyUSB0", "to": "sp.Port"
  ,
    "data": "config.json", "to": "cf.In"
  ,
    "data": 64, "to": "bf.Len"
  ]
