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
        @parentNode.appendChild @ # arrange this gadget in front
      .on 'drag', (d) ->
        d.x += d3.event.dx
        d.y += d3.event.dy
        d3.select(@).attr
          transform: (d) -> "translate(#{d.x},#{d.y})"
      .on 'dragend', (d) ->
        console.log d # TODO: save to server

    wireDrag = d3.behavior.drag()
      .origin Object
      .on 'dragstart', (d) ->
        console.log 'wireDrag', d
        @parentNode.appendChild @ # arrange this gadget in front
      .on 'drag', (d) ->
        d.x += d3.event.dx
        d.y += d3.event.dy
        d3.select(@).attr
          transform: (d) -> "translate(#{d.x},#{d.y})"
      .on 'dragend', (d) ->
        console.log d # TODO: save to server

    gadgets = svg.selectAll('.gadget').data(scope.data.gadgets)
  
    g = gadgets.enter().append('g').call(gadgetDrag)
      .attr class: 'gadget'
    g.append('rect')
      .each (d) ->
        d.gt = gadgetTypes[d.type]
        d.hw = d.gt.width >> 1  # half width, truncated
        d.hh = d.gt.height >> 1 # half height, truncated
        me = d3.select(@)
        me.attr
          x: -d.hw
          y: -d.hh
          width: 2 * d.hw
          height: 2 * d.hh
      .style
        fill: (d) -> d.gt.shade
    g.append('text')
      .text (d) -> d.title
      .attr
        class: 'title'
        'text-anchor': 'middle'
        y: (d) -> 12 - d.hh
    g.append('text')
      .text (d) -> d.type
      .attr
        class: 'type'
        'text-anchor': 'middle'
        y: (d) -> -5 + d.hh
    g.append('circle').call(wireDrag)
      .attr
        class: 'pin'
        cx: (d) -> -d.hw
        r: 3
    g.append('circle').call(wireDrag)
      .attr
        class: 'pin'
        cx: (d) -> d.hw
        r: 3

    # 1px lines render sharply when placed on a 0.5px offset
    gadgets.attr
      transform: (d) -> "translate(#{d.x+.5},#{d.y+.5})"
