ng = angular.module 'myApp'

gadgetTypes =
  Pipe:
    width: 80
    height: 60
    shade: 'lightyellow'
    pins: [
      { name:'In', type:'i' }
      { name:'Out', type:'o' }
    ]
  Printer:
    width: 120
    height: 40
    shade: 'lightblue'
    pins: [
      { name:'In', type:'i' }
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
      .on 'dragend', (d) ->
        console.log 'save wire', d # TODO: save to server

    diag = d3.svg.diagonal()
    
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
    g.append('circle')
      .on 'mousedown', (d) ->
        console.log 'c1', d
        d3.event.sourceEvent.stopPropagation()
      .attr class: 'pin', cx: ((d) -> 0.5 - d.hw), r: 3
    g.append('circle')
      .on 'mousedown', (d) ->
        console.log 'c2', d
        d3.event.sourceEvent.stopPropagation()
      .attr class: 'pin', cx: ((d) -> 0.5 + d.hw), r: 3

    # FIXME
    diag.source scope.data.gadgets[0]
    diag.target scope.data.gadgets[1]

    wires = svg.selectAll('.wire').data(scope.data.gadgets)
    wires.enter().append('path')
      .attr class: 'wire', d: diag

    gadgets.attr
      transform: (d) -> "translate(#{d.x},#{d.y})"
