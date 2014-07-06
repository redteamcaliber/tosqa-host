ng = angular.module 'myApp'

ng.directive 'jbCircuitEditor', ->
  restrict: 'E'
  
  scope:
    defs: '='
    data: '='
    
  link: (scope, elem, attr) ->
    svg = d3.select(elem[0]).append 'svg'
      .attr width: '100%', height: '400px'
    diag = d3.svg.diagonal()
      .projection (d) -> [d.x, d.y]
    
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
        dragInfo.target = x: orig.x+mx-d.x, y: orig.y+my-d.y
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
      g.append('rect') #the gadget outline
        .each (d) ->
          d3.select(@).attr
            class: 'gadget-container'
            # 1px lines render sharply when on a 0.5px offset
            x: 0, y: 0
            width: 140, height: 40
            rx: 5
            ry: 5
        .on 'mousedown', (d) ->
          # TODO: remove 'selected' class if gadget is already selected
          d3.selectAll('.gadget-container').classed 'selected', false
          d3.select(this).classed 'selected', true
          emit 'selectGadget', d.id
        .style fill: (d) -> d.def.shade
      g.append('text').text (d) -> d.type
        .attr class: 'title', x: 10, y: 24
      g.append('text').text (d) -> "#{d.id}"
        .attr class: 'label', x: 140, y: - 8
      # g.append('text').text (d) -> d.def.icon #disable the icon for now
      #   .attr class: 'iconfont', x: 16, y: 20
      g.append('text').text (d) -> '\uf014' # fa-trash-o
        .attr class: 'delete iconfont', x: 130, y: 10
        .style 'font-size': '12px'
        .on 'mouseup', (d) ->
          d3.event.stopPropagation()
          emit 'delGadget', d.id
      gadgets.exit().remove()


      # Add input and output pins
      pins = gadgets.selectAll('.pin').data (d) -> d.pins
      p = pins.enter().append('g').classed('pins', true)
      p.append('circle')
        .attr class: 'pin', cx: ((d) -> d.x+0.5), cy: ((d) -> d.y+.5), r: 3
      p.append('circle').call(pinDrag)
        .attr class: 'hit', cx: ((d) -> d.x+0.5), cy: ((d) -> d.y+.5), r: 9
        .on 'mouseup',  (d) -> dragInfo.to = d.pin
        .on 'mouseover', (d) -> d3.select(this.parentNode).classed('hover',true)
        .on 'mouseout',  (d) -> d3.select(this.parentNode).classed('hover',false)
      p.append('text').text (d) -> d.name
        .attr
          class: (d) -> d.dir
          x: (d) -> if d.dir is 'in' then d.x-4 else d.x+16
          y: (d) -> if d.dir is 'in' then d.y-10 else d.y+20
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
        console.log wireUnderCursor.classList
        emit 'delWire', wireUnderCursor.from, wireUnderCursor.to
        # wireUnderCursor = null
      else # unselect all selected gadgets
        d3.selectAll('.gadget-container').classed('selected', false)
    svg.on 'dblclick', ->
      [x,y] = d3.mouse(@)
      emit 'addGadget', x|0, y|0 # convert to ints

    findPin = (pin) ->
      [gid,pname] = pin.split '.'
      for g in glist when gid is g.id
        for p in g.pins when pname is p.name
          # uses projection to get horizontal splines
          return y: g.y + p.y + .5, x: g.x + p.x + .5, id: gid

    prepareData = ->
      xstep = 20  # horizontal separation between pins
      width = 140 # fixed width for now
      height = 40

      # set up a list of gadgets with sizes and relative pin coordinates
      glist = for id, g of scope.data.gadgets
        {x,y,title,type} = g
        def = scope.defs[type]
        pins = []

        placePins = (pnames, dir, yi) ->
          nlist = if pnames then pnames.split ' ' else []
          xi = 10 # xstep * (nlist.length-1) #>> 1 # why this bitshift?
          for name in nlist
            pins.push { x: xi, y: yi, name, dir, pin: "#{id}.#{name}" }
            xi += xstep
          nlist.length

        hw = width / 2
        hh = height / 2
        ins = placePins def.inputs, 'in', 0
        outs = placePins def.outputs, 'out', height

        { id, x, y, title, type, def, pins, hw, width, hh, height }

      # convert object to list and lookup the wire endpoints in the gadgets
      wlist = for id, cap of scope.data.wires
        [from,to] = id.split '/'
        source = findPin from
        target = findPin to
        { id, from, to, source, target, cap }
    
    scope.$watch "data", (->
      redraw()
    ), true
    
    redraw()
