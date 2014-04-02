ng = angular.module 'myApp'

ng.directive 'jbCircuitEditor', ->
  restrict: 'E'
  
  scope:
    defs: '='
    data: '='
    
  link: (scope, elem, attr) ->
    svg = d3.select(elem[0]).append 'svg'
      .attr height: '60%'
    diag = d3.svg.diagonal()
      .projection (d) -> [d.y, d.x] # undo the x/y reversal from findPin
    
    lastg = gadgets = wires = null
    
    emit = (args...) ->
      # force a digest, since d3 events happen outside of ng's event context
      scope.$apply -> scope.$emit attr.event ? 'circuit', args...
      
    gadgetDrag = d3.behavior.drag()
      .origin Object
      .on 'dragstart', (d) ->
        d3.event.sourceEvent.stopPropagation()
        @parentNode.appendChild @ # move to front
      .on 'drag', (d) ->
        d.x = d3.event.x | 0 # stay on int coordinates
        d.y = d3.event.y | 0 # stay on int coordinates
        d3.select(@).attr transform: (d) -> "translate(#{d.x},#{d.y})"
        # recalculate endpoints and redraw all wires attached to this gadget
        wires.filter (w) -> w.source.g is d or w.target.g is d
          .each (d) ->
            d.source = findPin d.from, scope.data.gadgets
            d.target = findPin d.to, scope.data.gadgets
          .attr d: diag
      .on 'dragend', (d) ->
        emit 'moveGadget', d.id, d.x, d.y

    dragInfo = {}
    dragWire = svg.append('path').datum(dragInfo).attr id: 'drag'
    wireUnderCursor = null

    pinDrag = d3.behavior.drag()
      .origin Object
      .on 'dragstart', (d) ->
        d3.event.sourceEvent.stopPropagation()
        dragInfo.from = d.pin
        delete dragInfo.to
        dragInfo.source = findPin d.pin, scope.data.gadgets
      .on 'drag', (d) ->
        [mx,my] = d3.mouse(@)
        orig = dragInfo.source
        dragInfo.target = x: orig.x+my-d.y, y: orig.y+mx-d.x # flipped
        dragWire.attr class: 'drawing', fill: 'none', d: diag
      .on 'dragend', (d) ->
        dragWire.classed 'drawing', false
        if dragInfo.to
          nw = from: dragInfo.from, to: dragInfo.to
          unless nw.from is nw.to
            emit 'addWire', nw.from, nw.to
          redraw()

    redraw = ->
      lastg = prepareData scope.defs, scope.data
      gadgets = svg.selectAll('.gadget').data scope.data.gadgets, (d) -> d.id
      wires = svg.selectAll('.wire').data scope.data.wires, (d) ->
                "#{d.from}/#{d.to}" # essential for adding or removing wires

      g = gadgets.enter().append('g').call(gadgetDrag)
        .attr class: 'gadget'
      g.append('rect')
        .each (d) ->
          d.def = scope.defs[d.type]
          d.hw = d.def.width / 2
          d.hh = d.def.height / 2
          d3.select(@).attr
            class: 'outline'
            # 1px lines render sharply when on a 0.5px offset
            x: 0.5 - d.hw, y: 0.5 - d.hh
            width: 2 * d.hw, height: 2 * d.hh
        .on 'mousedown', (d) -> emit 'selectGadget', d.id
        .style fill: (d) -> d.def.shade
      g.append('text').text (d) -> d.title or d.def.name
        .attr class: 'title', y: (d) -> 12 - d.hh
      g.append('text').text (d) -> "#{d.type} - #{d.id}"
        .attr class: 'type', y: (d) -> -4 + d.hh
      g.append('text').text (d) -> d.def.icon
        .attr class: 'iconfont', x: 0, y: 0
      g.append('text').text (d) -> '\uf014' # fa-trash-o
        .attr class: 'iconfont', x: ((d) -> d.hw-8), y: ((d) -> 8-d.hh)
        .style 'font-size': '12px'
        .on 'mousedown', (d) ->
          d3.event.stopPropagation()
          emit 'delGadget', d.id
          redraw()
      gadgets.exit().remove()
        
      pins = gadgets.selectAll('.pin').data (d) ->
        d.conn = for p in d.def.pins
          x: p.x, y: p.y, name: p.name, dir: p.dir, pin: "#{d.id}.#{p.name}"
      p = pins.enter()
      p.append('circle')
        .attr class: 'pin', cx: ((d) -> d.x+.5), cy: ((d) -> d.y+.5), r: 3
      p.append('circle').call(pinDrag)
        .attr class: 'hit', cx: ((d) -> d.x+.5), cy: ((d) -> d.y+.5), r: 7
        .on 'mouseup', (d) -> dragInfo.to = d.pin
      p.append('text').text (d) -> d.name
        .attr
          class: (d) -> d.dir
          x: (d) -> if d.dir is 'in' then d.x + 10 else d.x - 10
          y: (d) -> d.y + 5
      pins.exit().remove()

      wires.enter().insert('path', 'g') # uses insert to move to back right away
        .attr class: 'wire', fill: 'none', d: diag
        # can't use mouseclick, see
        # https://groups.google.com/d/msg/d3-js/gHzOj91X2NA/65BEf2DuRV4J
        .on 'mouseenter', (d) -> wireUnderCursor = d
        .on 'mouseleave', (d) -> wireUnderCursor = null
      wires.exit().remove()

      gadgets.attr transform: (d) -> "translate(#{d.x},#{d.y})"
    
    redraw()
    
    svg.on 'mousedown', ->
      # return  if d3.event.defaultPrevented
      if wireUnderCursor
        emit 'delWire', wireUnderCursor.from, wireUnderCursor.to
        wireUnderCursor = null
      else
        [x,y] = d3.mouse @
        emit 'addGadget', x: x|0, y: y|0
      redraw()

findPin = (name, gdata) ->
  [gid,pname] = name.split '.'
  for g in gdata when gid is g.id
    for p in g.def.pins when pname is p.name
      # reverses x and y and uses projection to get horizontal splines
      return y: g.x + p.x + .5, x: g.y + p.y + .5, g: g, p: p

prepareData = (gdefs, gdata) ->
  # pre-calculate sizes and relative pin coordinates
  for n, d of gdefs
    d.name or= n
    ins = 0
    for p in d.pins
      p.x = d.width / 2
      if p.dir is 'in'
        p.x = -p.x
        ++ins
    outs = d.pins.length - ins
    step = 20
    yIn = - (ins - 1) * step / 2
    yOut = - (outs - 1) * step / 2
    for p in d.pins
      if p.dir is 'in'
        p.y = yIn
        yIn += step
      else
        p.y = yOut
        yOut += step
    d.height = 40 + step * (if ins > outs then ins else outs)

  seq = 0 # find the largest "g<n>" id to help generate the next one
  for d in gdata.gadgets
    if /^g\d+$/.test(d.id)
      n = d.id.slice(1) | 0 # drop the leading "g" and convert to int
      seq = n  if n > seq
    d.def = gdefs[d.type]
    d.hw = d.def.width / 2
    d.hh = d.def.height / 2

  for d in gdata.wires
    d.source = findPin d.from, gdata.gadgets
    d.target = findPin d.to, gdata.gadgets
    
  return seq
