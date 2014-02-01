console.log "tqNodes"
ng = angular.module 'myApp'


ng.factory "tqNodeTypes", ->

  #factory function body that constructs objects for each type of node in the diagram
  ssb:
    description: "this is a driver for ssb"
    driver: "ssbDriver"
    diagramX: 400
    diagramY: 50
    attributes:
      temp:
        varType: "int"
        editable: false
        default: 0
      stepSize:
        varType: "float"
        editable: true
    pads:
      'frequency': {}
      'timbre': {}
      'modulation': {}
  
  host:
    description: "this the host"
    driver: "hostDriver"
    diagramX: 200
    diagramY: 50
    attributes:
      temp:
        varType: "int"
        editable: false
        default: 0
      stepSize:
        varType: "float"
        editable: true
    pads:
      'in1': {}
      'in2': {}
      'x': 
        wires: {}
          # 10: ['']
      'y':
        wires: {}
          # 10: ['']
      'z':
        wires: {}
          # 10: ['']
      'r':
        wires: {}
          # 10: ['']
  
  sensor:
    description: "this a sensor"
    driver: "sensorDriver"
    diagramX: 50
    diagramY: 50
    attributes:
      value:
        varType: "int"
        editable: false
        default: 0
    pads:
      'measure out':
        wires: {}
          # 10: ['']