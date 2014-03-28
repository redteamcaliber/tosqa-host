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
        @parentNode.appendChild @ # arrange this wire in front
        d3.event.sourceEvent.stopPropagation()
      .on 'drag', (d) ->
        d.x = d3.event.x
        d.y = d3.event.y
        d3.select(@).attr
          transform: (d) -> "translate(#{d.x},#{d.y})"
      .on 'dragend', (d) ->
        console.log 'save wire', d # TODO: save to server

    gadgets = svg.selectAll('.gadget').data(scope.data.gadgets)
  
    g = gadgets.enter().append('g').call(gadgetDrag)
      .attr class: 'gadget'
    g.append('rect')
      .each (d) ->
        d.gt = gadgetTypes[d.type]
        d.hw = d.gt.width / 2
        d.hh = d.gt.height / 2
        me = d3.select(@)
        me.attr
          # 1px lines render sharply when placed on a 0.5px offset
          x: 0.5 - d.hw
          y: 0.5 - d.hh
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
        y: (d) -> -4 + d.hh
    g.append('circle')
      .on 'mousedown', (d) ->
        console.log 'c1', d
        d3.event.sourceEvent.stopPropagation()
      .attr
        class: 'pin'
        cx: (d) -> 0.5 - d.hw
        r: 3
    g.append('circle')
      .on 'mousedown', (d) ->
        console.log 'c2', d
        d3.event.sourceEvent.stopPropagation()
      .attr
        class: 'pin'
        cx: (d) -> 0.5 + d.hw
        r: 3

    gadgets.attr
      transform: (d) -> "translate(#{d.x},#{d.y})"
