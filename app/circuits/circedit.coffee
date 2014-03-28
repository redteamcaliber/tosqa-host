ng = angular.module 'myApp'

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
        @parentNode.appendChild @ # put this gadget on top
      .on 'drag', (d) ->
        d.x = d3.event.x
        d.y = d3.event.y
        d3.select(@).attr transform: (d) -> "translate(#{d.x},#{d.y})"
      .on 'dragend', (d) ->
        console.log d # TODO: save to server

    gadgets = svg.selectAll('.gadget').data(scope.data.gadgets)
  
    g = gadgets.enter().append('g').attr('class', 'gadget').call(gadgetDrag)
    g.append('rect')
      .attr width: 120, height: 80
    g.append('text').text (d) -> d.title
      .attr x: 5, y: 15

    gadgets.attr transform: (d) -> "translate(#{d.x},#{d.y})"
