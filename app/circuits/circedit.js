(function() {
  var gadgetTypes, ng;

  ng = angular.module('myApp');

  gadgetTypes = {
    Pipe: {
      width: 80,
      height: 60,
      shade: 'lightyellow',
      pins: [
        {
          name: 'In',
          type: 'i',
          x: -40,
          y: 0
        }, {
          name: 'Out',
          type: 'o',
          x: 40,
          y: 0
        }
      ]
    },
    Printer: {
      width: 120,
      height: 40,
      shade: 'lightblue',
      pins: [
        {
          name: 'In',
          type: 'i',
          x: -60,
          y: 0
        }, {
          name: 'Out',
          type: 'o',
          x: 60,
          y: 0
        }
      ]
    }
  };

  ng.directive('circuitEditor', function() {
    return {
      restrict: 'E',
      scope: {
        data: '='
      },
      link: function(scope, elem, attr) {
        var d, diag, findPin, g, gadgetDrag, gadgets, pins, svg, wires, _, _ref, _ref1;
        svg = d3.select(elem[0]).append('svg').attr({
          height: "70%"
        });
        findPin = function(name) {
          var g, gid, p, pname, _i, _j, _len, _len1, _ref, _ref1, _ref2;
          _ref = name.split('.'), gid = _ref[0], pname = _ref[1];
          _ref1 = scope.data.gadgets;
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            g = _ref1[_i];
            if (gid === g.id) {
              _ref2 = g.gt.pins;
              for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
                p = _ref2[_j];
                if (pname === p.name) {
                  return {
                    x: g.x + p.x,
                    y: g.y + p.y,
                    g: g,
                    p: p
                  };
                }
              }
            }
          }
        };
        _ref = scope.data.gadgets;
        for (_ in _ref) {
          d = _ref[_];
          d.gt = gadgetTypes[d.type];
          d.hw = d.gt.width / 2;
          d.hh = d.gt.height / 2;
        }
        _ref1 = scope.data.wires;
        for (_ in _ref1) {
          d = _ref1[_];
          d.source = findPin(d.from);
          d.target = findPin(d.to);
        }
        gadgets = svg.selectAll('.gadget').data(scope.data.gadgets);
        wires = svg.selectAll('.wire').data(scope.data.wires);
        diag = d3.svg.diagonal();
        gadgetDrag = d3.behavior.drag().origin(Object).on('dragstart', function(d) {
          return this.parentNode.appendChild(this);
        }).on('drag', function(d) {
          d.x = d3.event.x | 0;
          d.y = d3.event.y | 0;
          d3.select(this).attr({
            transform: function(d) {
              return "translate(" + d.x + "," + d.y + ")";
            }
          });
          return wires.filter(function(w) {
            return w.source.g === d || w.target.g === d;
          }).each(function(d) {
            d.source = findPin(d.from);
            return d.target = findPin(d.to);
          }).attr({
            d: diag
          });
        }).on('dragend', function(d) {
          return console.log('save gadget', d);
        });
        g = gadgets.enter().append('g').call(gadgetDrag).attr({
          "class": 'gadget'
        });
        g.append('rect').each(function(d) {
          return d3.select(this).attr({
            "class": 'outline',
            x: 0.5 - d.hw,
            y: 0.5 - d.hh,
            width: 2 * d.hw,
            height: 2 * d.hh
          });
        }).style({
          fill: function(d) {
            return d.gt.shade;
          }
        });
        g.append('text').text(function(d) {
          return d.title;
        }).attr({
          "class": 'title',
          y: function(d) {
            return 12 - d.hh;
          }
        });
        g.append('text').text(function(d) {
          return d.type;
        }).attr({
          "class": 'type',
          y: function(d) {
            return -4 + d.hh;
          }
        });
        pins = gadgets.selectAll('rect .pin').data(function(d) {
          return d.gt.pins;
        });
        pins.enter().append('circle').attr({
          "class": 'pin',
          cx: (function(d) {
            return d.x;
          }),
          cy: (function(d) {
            return d.y;
          }),
          r: 3
        }).on('mousedown', function(d) {
          return console.log('c1', d);
        });
        pins.exit().remove();
        wires.enter().append('path').attr({
          "class": 'wire',
          d: diag
        });
        wires.exit().remove();
        return gadgets.attr({
          transform: function(d) {
            return "translate(" + d.x + "," + d.y + ")";
          }
        });
      }
    };
  });

}).call(this);

//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiY2lyY2VkaXQuY29mZmVlIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBO0FBQUEsTUFBQSxlQUFBOztBQUFBLEVBQUEsRUFBQSxHQUFLLE9BQU8sQ0FBQyxNQUFSLENBQWUsT0FBZixDQUFMLENBQUE7O0FBQUEsRUFFQSxXQUFBLEdBQ0U7QUFBQSxJQUFBLElBQUEsRUFDRTtBQUFBLE1BQUEsS0FBQSxFQUFPLEVBQVA7QUFBQSxNQUNBLE1BQUEsRUFBUSxFQURSO0FBQUEsTUFFQSxLQUFBLEVBQU8sYUFGUDtBQUFBLE1BR0EsSUFBQSxFQUFNO1FBQ0o7QUFBQSxVQUFFLElBQUEsRUFBSyxJQUFQO0FBQUEsVUFBYSxJQUFBLEVBQUssR0FBbEI7QUFBQSxVQUF1QixDQUFBLEVBQUcsQ0FBQSxFQUExQjtBQUFBLFVBQStCLENBQUEsRUFBRyxDQUFsQztTQURJLEVBRUo7QUFBQSxVQUFFLElBQUEsRUFBSyxLQUFQO0FBQUEsVUFBYyxJQUFBLEVBQUssR0FBbkI7QUFBQSxVQUF3QixDQUFBLEVBQUcsRUFBM0I7QUFBQSxVQUErQixDQUFBLEVBQUcsQ0FBbEM7U0FGSTtPQUhOO0tBREY7QUFBQSxJQVFBLE9BQUEsRUFDRTtBQUFBLE1BQUEsS0FBQSxFQUFPLEdBQVA7QUFBQSxNQUNBLE1BQUEsRUFBUSxFQURSO0FBQUEsTUFFQSxLQUFBLEVBQU8sV0FGUDtBQUFBLE1BR0EsSUFBQSxFQUFNO1FBQ0o7QUFBQSxVQUFFLElBQUEsRUFBSyxJQUFQO0FBQUEsVUFBYSxJQUFBLEVBQUssR0FBbEI7QUFBQSxVQUF1QixDQUFBLEVBQUcsQ0FBQSxFQUExQjtBQUFBLFVBQStCLENBQUEsRUFBRyxDQUFsQztTQURJLEVBRUo7QUFBQSxVQUFFLElBQUEsRUFBSyxLQUFQO0FBQUEsVUFBYyxJQUFBLEVBQUssR0FBbkI7QUFBQSxVQUF3QixDQUFBLEVBQUcsRUFBM0I7QUFBQSxVQUErQixDQUFBLEVBQUcsQ0FBbEM7U0FGSTtP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Q0FBQSxDQXRFQSxDQUFBO2VBd0VBLE9BQU8sQ0FBQyxJQUFSLENBQ0U7QUFBQSxVQUFBLFNBQUEsRUFBVyxTQUFDLENBQUQsR0FBQTttQkFBUSxZQUFBLEdBQVcsQ0FBQyxDQUFDLENBQWIsR0FBZ0IsR0FBaEIsR0FBa0IsQ0FBQyxDQUFDLENBQXBCLEdBQXVCLElBQS9CO1VBQUEsQ0FBWDtTQURGLEVBekVJO01BQUEsQ0FMTjtNQUQ0QjtFQUFBLENBQTlCLENBcEJBLENBQUE7QUFBQSIsInNvdXJjZXNDb250ZW50IjpbIm5nID0gYW5ndWxhci5tb2R1bGUgJ215QXBwJ1xuXG5nYWRnZXRUeXBlcyA9XG4gIFBpcGU6XG4gICAgd2lkdGg6IDgwXG4gICAgaGVpZ2h0OiA2MFxuICAgIHNoYWRlOiAnbGlnaHR5ZWxsb3cnXG4gICAgcGluczogW1xuICAgICAgeyBuYW1lOidJbicsIHR5cGU6J2knLCB4OiAtNDAsIHk6IDAgfVxuICAgICAgeyBuYW1lOidPdXQnLCB0eXBlOidvJywgeDogNDAsIHk6IDAgfVxuICAgIF1cbiAgUHJpbnRlcjpcbiAgICB3aWR0aDogMTIwXG4gICAgaGVpZ2h0OiA0MFxuICAgIHNoYWRlOiAnbGlnaHRibHVlJ1xuICAgIHBpbnM6IFtcbiAgICAgIHsgbmFtZTonSW4nLCB0eXBlOidpJywgeDogLTYwLCB5OiAwIH1cbiAgICAgIHsgbmFtZTonT3V0JywgdHlwZTonbycsIHg6IDYwLCB5OiAwIH1cbiAgICBdXG5cbm5nLmRpcmVjdGl2ZSAnY2lyY3VpdEVkaXRvcicsIC0+XG4gIHJlc3RyaWN0OiAnRSdcbiAgXG4gIHNjb3BlOlxuICAgIGRhdGE6ICc9J1xuICAgIFxuICBsaW5rOiAoc2NvcGUsIGVsZW0sIGF0dHIpIC0+XG4gICAgc3ZnID0gZDMuc2VsZWN0KGVsZW1bMF0pLmFwcGVuZCAnc3ZnJ1xuICAgICAgLmF0dHIgaGVpZ2h0OiBcIjcwJVwiXG5cbiAgICBmaW5kUGluID0gKG5hbWUpIC0+XG4gICAgICBbZ2lkLHBuYW1lXSA9IG5hbWUuc3BsaXQgJy4nXG4gICAgICBmb3IgZyBpbiBzY29wZS5kYXRhLmdhZGdldHNcbiAgICAgICAgaWYgZ2lkIGlzIGcuaWRcbiAgICAgICAgICBmb3IgcCBpbiBnLmd0LnBpbnNcbiAgICAgICAgICAgIGlmIHBuYW1lIGlzIHAubmFtZVxuICAgICAgICAgICAgICAjIGNvbnNvbGUubG9nICdncCcsIG5hbWUsIGcsIHBcbiAgICAgICAgICAgICAgcmV0dXJuIHg6IGcueCArIHAueCwgeTogZy55ICsgcC55LCBnOiBnLCBwOiBwXG5cbiAgICBmb3IgXywgZCBvZiBzY29wZS5kYXRhLmdhZGdldHNcbiAgICAgIGQuZ3QgPSBnYWRnZXRUeXBlc1tkLnR5cGVdXG4gICAgICBkLmh3ID0gZC5ndC53aWR0aCAvIDJcbiAgICAgIGQuaGggPSBkLmd0LmhlaWdodCAvIDJcblxuICAgIGZvciBfLCBkIG9mIHNjb3BlLmRhdGEud2lyZXNcbiAgICAgIGQuc291cmNlID0gZmluZFBpbiBkLmZyb21cbiAgICAgIGQudGFyZ2V0ID0gZmluZFBpbiBkLnRvXG5cbiAgICBnYWRnZXRzID0gc3ZnLnNlbGVjdEFsbCgnLmdhZGdldCcpLmRhdGEoc2NvcGUuZGF0YS5nYWRnZXRzKVxuICAgIHdpcmVzID0gc3ZnLnNlbGVjdEFsbCgnLndpcmUnKS5kYXRhKHNjb3BlLmRhdGEud2lyZXMpXG5cbiAgICBkaWFnID0gZDMuc3ZnLmRpYWdvbmFsKClcbiAgICBcbiAgICBnYWRnZXREcmFnID0gZDMuYmVoYXZpb3IuZHJhZygpXG4gICAgICAub3JpZ2luIE9iamVjdFxuICAgICAgLm9uICdkcmFnc3RhcnQnLCAoZCkgLT5cbiAgICAgICAgQHBhcmVudE5vZGUuYXBwZW5kQ2hpbGQgQCAjIG1vdmUgdG8gZnJvbnRcbiAgICAgIC5vbiAnZHJhZycsIChkKSAtPlxuICAgICAgICBkLnggPSBkMy5ldmVudC54IHwgMCAjIHN0YXkgb24gaW50IGNvb3JkaW5hdGVzXG4gICAgICAgIGQueSA9IGQzLmV2ZW50LnkgfCAwICMgc3RheSBvbiBpbnQgY29vcmRpbmF0ZXNcbiAgICAgICAgZDMuc2VsZWN0KEApLmF0dHJcbiAgICAgICAgICB0cmFuc2Zvcm06IChkKSAtPiBcInRyYW5zbGF0ZSgje2QueH0sI3tkLnl9KVwiXG4gICAgICAgICMgcmVjYWxjdWxhdGUgZW5kcG9pbnRzIGFuZCByZWRyYXcgYWxsIHdpcmVzIGF0dGFjaGVkIHRvIHRoaXMgZ2FkZ2V0XG4gICAgICAgIHdpcmVzLmZpbHRlciAodykgLT4gdy5zb3VyY2UuZyBpcyBkIG9yIHcudGFyZ2V0LmcgaXMgZFxuICAgICAgICAgIC5lYWNoIChkKSAtPlxuICAgICAgICAgICAgZC5zb3VyY2UgPSBmaW5kUGluIGQuZnJvbVxuICAgICAgICAgICAgZC50YXJnZXQgPSBmaW5kUGluIGQudG9cbiAgICAgICAgICAuYXR0ciBkOiBkaWFnXG4gICAgICAub24gJ2RyYWdlbmQnLCAoZCkgLT5cbiAgICAgICAgY29uc29sZS5sb2cgJ3NhdmUgZ2FkZ2V0JywgZCAjIFRPRE86IHNhdmUgdG8gc2VydmVyXG5cbiAgICBnID0gZ2FkZ2V0cy5lbnRlcigpLmFwcGVuZCgnZycpLmNhbGwoZ2FkZ2V0RHJhZylcbiAgICAgIC5hdHRyIGNsYXNzOiAnZ2FkZ2V0J1xuICAgIGcuYXBwZW5kKCdyZWN0JylcbiAgICAgIC5lYWNoIChkKSAtPlxuICAgICAgICBkMy5zZWxlY3QoQCkuYXR0clxuICAgICAgICAgIGNsYXNzOiAnb3V0bGluZSdcbiAgICAgICAgICAjIDFweCBsaW5lcyByZW5kZXIgc2hhcnBseSB3aGVuIG9uIGEgMC41cHggb2Zmc2V0XG4gICAgICAgICAgeDogMC41IC0gZC5od1xuICAgICAgICAgIHk6IDAuNSAtIGQuaGhcbiAgICAgICAgICB3aWR0aDogMiAqIGQuaHdcbiAgICAgICAgICBoZWlnaHQ6IDIgKiBkLmhoXG4gICAgICAuc3R5bGUgZmlsbDogKGQpIC0+IGQuZ3Quc2hhZGVcbiAgICBnLmFwcGVuZCgndGV4dCcpLnRleHQgKGQpIC0+IGQudGl0bGVcbiAgICAgIC5hdHRyIGNsYXNzOiAndGl0bGUnLCB5OiAoZCkgLT4gMTIgLSBkLmhoXG4gICAgZy5hcHBlbmQoJ3RleHQnKS50ZXh0IChkKSAtPiBkLnR5cGVcbiAgICAgIC5hdHRyIGNsYXNzOiAndHlwZScsIHk6IChkKSAtPiAtNCArIGQuaGhcbiAgICAgICAgXG4gICAgcGlucyA9IGdhZGdldHMuc2VsZWN0QWxsKCdyZWN0IC5waW4nKS5kYXRhIChkKSAtPiBkLmd0LnBpbnNcbiAgICBwaW5zLmVudGVyKCkuYXBwZW5kKCdjaXJjbGUnKVxuICAgICAgLmF0dHIgY2xhc3M6ICdwaW4nLCBjeDogKChkKSAtPiBkLngpLCBjeTogKChkKSAtPiBkLnkpLCByOiAzXG4gICAgICAub24gJ21vdXNlZG93bicsIChkKSAtPlxuICAgICAgICBjb25zb2xlLmxvZyAnYzEnLCBkXG4gICAgcGlucy5leGl0KCkucmVtb3ZlKClcblxuICAgIHdpcmVzLmVudGVyKCkuYXBwZW5kKCdwYXRoJylcbiAgICAgIC5hdHRyIGNsYXNzOiAnd2lyZScsIGQ6IGRpYWdcbiAgICB3aXJlcy5leGl0KCkucmVtb3ZlKClcblxuICAgIGdhZGdldHMuYXR0clxuICAgICAgdHJhbnNmb3JtOiAoZCkgLT4gXCJ0cmFuc2xhdGUoI3tkLnh9LCN7ZC55fSlcIlxuIl19
