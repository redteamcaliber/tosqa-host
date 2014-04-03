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
    
    glist = wlist = gadgets = wires = null
    
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
        # recalculate endpoints and move all wires attached to this gadget
        wires.filter (w) -> w.source.id is d.id or w.target.id is d.id
          .each (d) ->
            d.source = findPin d.from
            d.target = findPin d.to
          .attr d: diag
      .on 'dragend', (d) ->
        g = scope.data.gadgets[d.id]
        unless g.x is d.x and g.y is d.y
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
        dragInfo.source = findPin d.pin
      .on 'drag', (d) ->
        [mx,my] = d3.mouse(@)
        orig = dragInfo.source
        dragInfo.target = x: orig.x+my-d.y, y: orig.y+mx-d.x # flipped
        dragWire.attr class: 'drawing', fill: 'none', d: diag
      .on 'dragend', (d) ->
        dragWire.classed 'drawing', false
        if dragInfo.to and dragInfo.to isnt dragInfo.from
          emit 'addWire', dragInfo.from, dragInfo.to

    redraw = ->
      prepareData()

      gadgets = svg.selectAll('.gadget').data glist, (d) -> d.id
      wires = svg.selectAll('.wire').data wlist, (d) -> d.id

      g = gadgets.enter().append('g').call(gadgetDrag)
        .attr class: 'gadget'
      g.append('rect')
        .each (d) ->
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
      gadgets.exit().remove()

      pins = gadgets.selectAll('.pin').data (d) -> d.pins
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
    
    svg.on 'mousedown', ->
      # return  if d3.event.defaultPrevented
      if wireUnderCursor
        emit 'delWire', wireUnderCursor.from, wireUnderCursor.to
        wireUnderCursor = null
      else
        [x,y] = d3.mouse(@)
        emit 'addGadget', x|0, y|0 # convert to ints

    findPin = (pin) ->
      [gid,pname] = pin.split '.'
      for g in glist when gid is g.id
        for p in g.pins when pname is p.name
          # reverses x and y and uses projection to get horizontal splines
          return y: g.x + p.x + .5, x: g.y + p.y + .5, id: gid

    prepareData = ->
      ystep = 20  # vertical separation between pins
      width = 140 # fixed width for now

      # set up a list of gadgets with sizes and relative pin coordinates
      glist = for id, g of scope.data.gadgets
        {x,y,title,type} = g
        def = scope.defs[type]
        pins = []
        placePins = (pnames, dir, xi) ->
          nlist = if pnames then pnames.split ' ' else []
          yi = -ystep * (nlist.length - 1) >> 1
          for name in nlist
            pins.push { x: xi, y: yi, name, dir, pin: "#{id}.#{name}" }
            yi += ystep
          nlist.length
        hw = width / 2
        ins = placePins def.inputs, 'in', -hw
        outs = placePins def.outputs, 'out', hw
        height = 40 + ystep * (if ins > outs then ins else outs)
        hh = height / 2
        { id, x, y, title, type, def, pins, hw, hh, height }

      # convert object to list and lookup the wire endpoints in the gadgets
      wlist = for id, cap of scope.data.wires
        [from,to] = id.split '/'
        source = findPin from
        target = findPin to
        { id, from, to, source, target, cap }
    
    redraw()
