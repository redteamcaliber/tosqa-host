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
      .attr height: "70%"

    findPin = (name) ->
      [gid,pname] = name.split '.'
      for g in scope.data.gadgets
        if gid is g.id
          for p in g.gt.pins
            if pname is p.name
              # console.log 'gp', name, g, p
              return x: g.x + p.x, y: g.y + p.y, g: g, p: p

    for _, d of scope.data.gadgets
      d.gt = gadgetTypes[d.type]
      d.hw = d.gt.width / 2
      d.hh = d.gt.height / 2

    for _, d of scope.data.wires
      d.source = findPin d.from
      d.target = findPin d.to

    gadgets = svg.selectAll('.gadget').data(scope.data.gadgets)
    wires = svg.selectAll('.wire').data(scope.data.wires)

    diag = d3.svg.diagonal()
    
    gadgetDrag = d3.behavior.drag()
      .origin Object
      .on 'dragstart', (d) ->
        @parentNode.appendChild @ # move to front
      .on 'drag', (d) ->
        d.x = d3.event.x | 0 # stay on int coordinates
        d.y = d3.event.y | 0 # stay on int coordinates
        d3.select(@).attr
          transform: (d) -> "translate(#{d.x},#{d.y})"
        # recalculate endpoints and redraw all wires attached to this gadget
        wires.filter (w) -> w.source.g is d or w.target.g is d
          .each (d) ->
            d.source = findPin d.from
            d.target = findPin d.to
          .attr d: diag
      .on 'dragend', (d) ->
        console.log 'save gadget', d # TODO: save to server

    g = gadgets.enter().append('g').call(gadgetDrag)
      .attr class: 'gadget'
    g.append('rect')
      .each (d) ->
        d3.select(@).attr
          class: 'outline'
          # 1px lines render sharply when on a 0.5px offset
          x: 0.5 - d.hw
          y: 0.5 - d.hh
          width: 2 * d.hw
          height: 2 * d.hh
      .style fill: (d) -> d.gt.shade
    g.append('text').text (d) -> d.title
      .attr class: 'title', y: (d) -> 12 - d.hh
    g.append('text').text (d) -> d.type
      .attr class: 'type', y: (d) -> -4 + d.hh
        
    pins = gadgets.selectAll('rect .pin').data (d) -> d.gt.pins
    pins.enter().append('circle')
      .attr class: 'pin', cx: ((d) -> d.x), cy: ((d) -> d.y), r: 3
      .on 'mousedown', (d) ->
        console.log 'c1', d
    pins.exit().remove()

    wires.enter().append('path')
      .attr class: 'wire', d: diag
    wires.exit().remove()

    gadgets.attr
      transform: (d) -> "translate(#{d.x},#{d.y})"
