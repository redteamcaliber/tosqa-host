ng = angular.module 'myApp'

ng.directive 'circuitEditor', ->
  restrict: 'E'
  
  scope:
    defs: '='
    data: '='
    type: '='
    select: '='
    
  link: (scope, elem, attr) ->
    for k of scope.defs
      scope.type = k # set initial type to a valid key from the definitions
      break
    
    svg = d3.select(elem[0]).append 'svg'
      .attr height: '60%'
    diag = d3.svg.diagonal()
      .projection (d) -> [d.y, d.x] # undo the x/y reversal from findPin
    
    lastg = gadgets = wires = null
    
    updateSelect = (d) ->
      scope.$apply -> scope.select = d
    
    gadgetDrag = d3.behavior.drag()
      .origin Object
      .on 'dragstart', (d) ->
        @parentNode.appendChild @ # move to front
        d3.event.sourceEvent.stopPropagation()
      .on 'drag', (d) ->
        d.moved = true
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
        if d.moved
          delete d.moved
          console.log 'save gadget', d # TODO: save to server

    dragInfo = {}
    dragWire = svg.append('path').datum(dragInfo).attr id: 'drag'
    wireUnderCursor = null

    pinDrag = d3.behavior.drag()
      .origin Object
      .on 'dragstart', (d) ->
        d3.event.sourceEvent.stopPropagation()
        @parentNode.appendChild @ # move to front
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
            console.log 'add wire', nw # TODO: save to server
            scope.data.wires.push nw
          redraw()

    redraw = (cb) ->
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
        .on 'mousedown', updateSelect # same as: (d) -> updateSelect d
        .style fill: (d) -> d.def.shade
      g.append('text').text (d) -> d.title or "#{d.type} #{d.id}"
        .attr class: 'title', y: (d) -> 12 - d.hh
      g.append('text').text (d) -> d.def.name
        .attr class: 'type', y: (d) -> -4 + d.hh
      g.append('text').text (d) -> d.def.icon
        .attr class: 'iconfont', x: 0, y: 0
      g.append('text').text (d) -> '\uf014' # fa-trash-o
        .attr class: 'iconfont', x: ((d) -> d.hw-8), y: ((d) -> 8-d.hh)
        .style 'font-size': '12px'
        .on 'mousedown', (d) ->
          d3.event.stopPropagation()
          # delete all attached wires
          sdw = scope.data.wires
          n = sdw.length
          while n
            w = sdw[--n]
            if w.from.split('.')[0] is d.id or w.to.split('.')[0] is d.id
              console.log 'del attached', w # TODO: save to server
              sdw.splice n, 1
          console.log 'del gadget', d # TODO: save to server
          for i, g of scope.data.gadgets when g is d
            scope.data.gadgets.splice i, 1
            updateSelect null
            break
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
      cb?()
    
    redraw()
    
    svg.on 'mousedown', ->
      # return  if d3.event.defaultPrevented
      if wireUnderCursor
        console.log 'del wire', wireUnderCursor # TODO: save to server
        for i, w of scope.data.wires when w is wireUnderCursor
          scope.data.wires.splice i, 1
          break
      else
        [x,y] = d3.mouse @
        ng = id: "g#{++lastg}", x: x|0, y: y|0, type: scope.type
        console.log 'add gadget', ng # TODO: save to server
        scope.data.gadgets.push ng
      redraw -> updateSelect ng # update scope after ng has been filled in

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
