ng = angular.module 'myApp'

gadgetTypes =
  Pipe:
    width: 80
    height: 60
    shade: 'lightyellow'
    pins: [
      { name:'In', type:'i', x: -40, y: 0 }
      { name:'Out', type:'o', x: 40, y: 0 }
    ]
  Printer:
    width: 120
    height: 40
    shade: 'lightblue'
    pins: [
      { name:'In', type:'i', x: -60, y: 0 }
      { name:'Out', type:'o', x: 60, y: 0 }
    ]

ng.directive 'circuitEditor', ->
  restrict: 'E'
  
  scope:
    data: '='
    
  link: (scope, elem, attr) ->
    svg = d3.select(elem[0]).append 'svg'
      .attr width: 900, height: 400

    gadgetDrag = d3.behavior.drag()
      .origin Object
      .on 'dragstart', (d) ->
        @parentNode.appendChild @ # move to front
      .on 'drag', (d) ->
        d.x = d3.event.x | 0 # stay on int coordinates
        d.y = d3.event.y | 0 # stay on int coordinates
        d3.select(@).attr
          transform: (d) -> "translate(#{d.x},#{d.y})"
      .on 'dragend', (d) ->
        console.log 'save gadget', d # TODO: save to server

    diag = d3.svg.diagonal()
    
    wireDrag = d3.behavior.drag()
      .origin Object
      .on 'dragstart', (d) ->
        console.log 'wireDrag', d
        @parentNode.appendChild @ # move to front
        d3.event.sourceEvent.stopPropagation()
      .on 'drag', (d) ->
        d.x = d3.event.x
        d.y = d3.event.y
        d3.select(@).attr
          transform: (d) -> "translate(#{d.x},#{d.y})"
        svg.selectAll('.wire').attr d: diag
      .on 'dragend', (d) ->
        console.log 'save wire', d # TODO: save to server

    gadgets = svg.selectAll('.gadget').data(scope.data.gadgets)
  
    g = gadgets.enter().append('g').call(gadgetDrag)
      .attr class: 'gadget'
      .each (d) ->
        d.gt = gadgetTypes[d.type]
        d.hw = d.gt.width / 2
        d.hh = d.gt.height / 2
    g.append('rect')
      .each (d) ->
        d3.select(@).attr
          # 1px lines render sharply when on a 0.5px offset
          x: 0.5 - d.hw
          y: 0.5 - d.hh
          width: 2 * d.hw
          height: 2 * d.hh
      .style
        fill: (d) -> d.gt.shade
    g.append('text')
      .text (d) -> d.title
      .attr class: 'title', y: (d) -> 12 - d.hh
    g.append('text')
      .text (d) -> d.type
      .attr class: 'type', y: (d) -> -4 + d.hh
        
    pins = gadgets.selectAll('rect .pin').data (d) -> d.gt.pins
    pins.enter().append('circle')
      .attr class: 'pin', cx: ((d) -> d.x), cy: ((d) -> d.y), r: 3
      .on 'mousedown', (d) ->
        console.log 'c1', d

    findPin = (name) ->
      [gid,pname] = name.split '.'
      for g in scope.data.gadgets
        if gid is g.id
          for p in g.gt.pins
            if pname is p.name
              # console.log 'gp', name, g, p
              return x: g.x + p.x, y: g.y + p.y, g: g, p: p

    diag.source (d) -> findPin d.from
    diag.target (d) -> findPin d.to
      
    wires = svg.selectAll('.wire').data(scope.data.wires)
    wires.enter().append('path')
      .attr class: 'wire', d: diag
    wires.exit().remove()

    gadgets.attr
      transform: (d) -> "translate(#{d.x},#{d.y})"
