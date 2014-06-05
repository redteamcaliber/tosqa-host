(function() {
  var circuitsCtrl, ng,
    __slice = [].slice;

  ng = angular.module('myApp');

  ng.config(function($stateProvider, navbarProvider) {
    $stateProvider.state('circuits', {
      url: '/circuits',
      templateUrl: '/circuits/circuits.html',
      controller: circuitsCtrl
    });
    return navbarProvider.add('/circuits', 'Circuits', 30);
  });

  circuitsCtrl = function($scope, jeebus) {
    var handlers, setup, updatePinList;
    $scope.gadgets = {
      Pipe: {
        name: 'Pipeline',
        shade: 'lightyellow',
        icon: '\uf061',
        inputs: 'In',
        outputs: 'Out'
      },
      Printer: {
        shade: 'lightblue',
        icon: '\uf02f',
        inputs: 'In In2'
      }
    };
    $scope.circuit = {
      gadgets: {
        g1: {
          x: 120,
          y: 100,
          title: 'Gadget One',
          type: 'Printer'
        },
        g2: {
          x: 120,
          y: 200,
          title: 'Gadget Two',
          type: 'Pipe'
        }
      },
      wires: {
        'g2.Out/g1.In': 0
      },
      feeds: {
        'g1.In': [
          'some data', {
            Tag: 'blah',
            Msg: 'tagged data'
          }
        ]
      },
      labels: {
        In: 'g2.In'
      }
    };
    updatePinList = function() {
      var g, gid, ins, p, _i, _len, _ref, _ref1;
      $scope.inputPins = [];
      _ref = $scope.circuit.gadgets;
      for (gid in _ref) {
        g = _ref[gid];
        if (ins = $scope.gadgets[g.type].inputs) {
          _ref1 = ins.split(' ');
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            p = _ref1[_i];
            $scope.inputPins.push("" + gid + "." + p);
          }
        }
      }
      return $scope.inputPins.sort();
    };
    $scope.$watch('addPin', function(pin) {
      var _base;
      if (pin) {
        if ((_base = $scope.circuit.feeds)[pin] == null) {
          _base[pin] = [];
        }
        console.log('addFeed', pin, $scope.circuit.feeds[pin].length);
        $scope.circuit.feeds[pin].push('');
        return $scope.addPin = null;
      }
    });
    $scope.delFeed = function(pin, index) {
      var items;
      items = $scope.circuit.feeds[pin];
      console.log('delFeed', pin, index, items[index]);
      items.splice(index, 1);
      if (items.length === 0) {
        return delete $scope.circuit.feeds[pin];
      }
    };
    $scope.$watch('currSel.id', function(x) {
      console.log('fix id', x);
      return updatePinList();
    });
    $scope.$watch('currSel.title', function(x) {
      return console.log('fix title', x);
    });
    handlers = {
      addGadget: function(x, y) {},
      delGadget: function(id) {},
      addWire: function(from, to) {},
      delWire: function(from, to) {},
      selectGadget: function(id) {},
      moveGadget: function(id, x, y) {}
    };
    $scope.$on('circuit', function() {
      var args, event, type;
      event = arguments[0], type = arguments[1], args = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      console.log.apply(console, ['C:', type].concat(__slice.call(args)));
      return handlers[type].apply(handlers, args);
    });
    setup = function() {
      return jeebus.attach('circuit').on('sync', function() {
        return $scope.circuits = this.rows;
      });
    };
    if ($scope.serverStatus === 'connected') {
      setup();
    }
    return $scope.$on('ws-open', setup);
  };

}).call(this);

//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiY2lyY3VpdHMuY29mZmVlIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBO0FBQUEsTUFBQSxnQkFBQTtJQUFBLGtCQUFBOztBQUFBLEVBQUEsRUFBQSxHQUFLLE9BQU8sQ0FBQyxNQUFSLENBQWUsT0FBZixDQUFMLENBQUE7O0FBQUEsRUFFQSxFQUFFLENBQUMsTUFBSCxDQUFVLFNBQUMsY0FBRCxFQUFpQixjQUFqQixHQUFBO0FBQ1IsSUFBQSxjQUFjLENBQUMsS0FBZixDQUFxQixVQUFyQixFQUNFO0FBQUEsTUFBQSxHQUFBLEVBQUssV0FBTDtBQUFBLE1BQ0EsV0FBQSxFQUFhLHlCQURiO0FBQUEsTUFFQSxVQUFBLEVBQVksWUFGWjtLQURGLENBQUEsQ0FBQTtXQUlBLGNBQWMsQ0FBQyxHQUFmLENBQW1CLFdBQW5CLEVBQWdDLFVBQWhDLEVBQTRDLEVBQTVDLEVBTFE7RUFBQSxDQUFWLENBRkEsQ0FBQTs7QUFBQSxFQVNBLFlBQUEsR0FBZSxTQUFDLE1BQUQsRUFBUyxNQUFULEdBQUE7QUFFYixRQUFBLDhCQUFBO0FBQUEsSUFBQSxNQUFNLENBQUMsT0FBUCxHQUNFO0FBQUEsTUFBQSxJQUFBLEVBQ0U7QUFBQSxRQUFBLElBQUEsRUFBTSxVQUFOO0FBQUEsUUFDQSxLQUFBLEVBQU8sYUFEUDtBQUFBLFFBRUEsSUFBQSxFQUFNLFFBRk47QUFBQSxRQUdBLE1BQUEsRUFBUSxJQUhSO0FBQUEsUUFJQSxPQUFBLEVBQVMsS0FKVDtPQURGO0FBQUEsTUFNQSxPQUFBLEVBQ0U7QUFBQSxRQUFBLEtBQUEsRUFBTyxXQUFQO0FBQUEsUUFDQSxJQUFBLEVBQU0sUUFETjtBQUFBLFFBRUEsTUFBQSxFQUFRLFFBRlI7T0FQRjtLQURGLENBQUE7QUFBQSxJQVlBLE1BQU0sQ0FBQyxPQUFQLEdBQ0U7QUFBQSxNQUFBLE9BQUEsRUFDRTtBQUFBLFFBQUEsRUFBQSxFQUFJO0FBQUEsVUFBRSxDQUFBLEVBQUcsR0FBTDtB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dUIsV0FBbkM7QUFBQSxNQUFBLEtBQUEsQ0FBQSxDQUFBLENBQUE7S0FuRUE7V0FvRUEsTUFBTSxDQUFDLEdBQVAsQ0FBVyxTQUFYLEVBQXNCLEtBQXRCLEVBdEVhO0VBQUEsQ0FUZixDQUFBO0FBQUEiLCJzb3VyY2VzQ29udGVudCI6WyJuZyA9IGFuZ3VsYXIubW9kdWxlICdteUFwcCdcblxubmcuY29uZmlnICgkc3RhdGVQcm92aWRlciwgbmF2YmFyUHJvdmlkZXIpIC0+XG4gICRzdGF0ZVByb3ZpZGVyLnN0YXRlICdjaXJjdWl0cycsXG4gICAgdXJsOiAnL2NpcmN1aXRzJ1xuICAgIHRlbXBsYXRlVXJsOiAnL2NpcmN1aXRzL2NpcmN1aXRzLmh0bWwnXG4gICAgY29udHJvbGxlcjogY2lyY3VpdHNDdHJsXG4gIG5hdmJhclByb3ZpZGVyLmFkZCAnL2NpcmN1aXRzJywgJ0NpcmN1aXRzJywgMzBcblxuY2lyY3VpdHNDdHJsID0gKCRzY29wZSwgamVlYnVzKSAtPlxuICAgIFxuICAkc2NvcGUuZ2FkZ2V0cyA9XG4gICAgUGlwZTpcbiAgICAgIG5hbWU6ICdQaXBlbGluZSdcbiAgICAgIHNoYWRlOiAnbGlnaHR5ZWxsb3cnXG4gICAgICBpY29uOiAnXFx1ZjA2MScgIyBmYS1hcnJvdy1yaWdodFxuICAgICAgaW5wdXRzOiAnSW4nXG4gICAgICBvdXRwdXRzOiAnT3V0J1xuICAgIFByaW50ZXI6XG4gICAgICBzaGFkZTogJ2xpZ2h0Ymx1ZSdcbiAgICAgIGljb246ICdcXHVmMDJmJyAjIGZhLXByaW50XG4gICAgICBpbnB1dHM6ICdJbiBJbjInXG4gICAgICBcbiAgJHNjb3BlLmNpcmN1aXQgPVxuICAgIGdhZGdldHM6XG4gICAgICBnMTogeyB4OiAxMjAsIHk6IDEwMCwgdGl0bGU6ICdHYWRnZXQgT25lJywgdHlwZTogJ1ByaW50ZXInIH1cbiAgICAgIGcyOiB7IHg6IDEyMCwgeTogMjAwLCB0aXRsZTogJ0dhZGdldCBUd28nLCB0eXBlOiAnUGlwZScgfVxuICAgIHdpcmVzOlxuICAgICAgJ2cyLk91dC9nMS5Jbic6IDBcbiAgICBmZWVkczpcbiAgICAgICdnMS5Jbic6IFsgJ3NvbWUgZGF0YScsIHsgVGFnOiAnYmxhaCcsIE1zZzogJ3RhZ2dlZCBkYXRhJyB9IF1cbiAgICBsYWJlbHM6XG4gICAgICBJbjogJ2cyLkluJ1xuICAgICAgXG4gIHVwZGF0ZVBpbkxpc3QgPSAoKSAtPlxuICAgICRzY29wZS5pbnB1dFBpbnMgPSBbXVxuICAgIGZvciBnaWQsIGcgb2YgJHNjb3BlLmNpcmN1aXQuZ2FkZ2V0c1xuICAgICAgaWYgaW5zID0gJHNjb3BlLmdhZGdldHNbZy50eXBlXS5pbnB1dHNcbiAgICAgICAgZm9yIHAgaW4gaW5zLnNwbGl0ICcgJ1xuICAgICAgICAgICRzY29wZS5pbnB1dFBpbnMucHVzaCBcIiN7Z2lkfS4je3B9XCJcbiAgICAkc2NvcGUuaW5wdXRQaW5zLnNvcnQoKVxuICBcbiAgJHNjb3BlLiR3YXRjaCAnYWRkUGluJywgKHBpbikgLT5cbiAgICBpZiBwaW5cbiAgICAgICRzY29wZS5jaXJjdWl0LmZlZWRzW3Bpbl0gPz0gW11cbiAgICAgIGNvbnNvbGUubG9nICdhZGRGZWVkJywgcGluLCAkc2NvcGUuY2lyY3VpdC5mZWVkc1twaW5dLmxlbmd0aFxuICAgICAgJHNjb3BlLmNpcmN1aXQuZmVlZHNbcGluXS5wdXNoICcnXG4gICAgICAkc2NvcGUuYWRkUGluID0gbnVsbFxuXG4gICRzY29wZS5kZWxGZWVkID0gKHBpbiwgaW5kZXgpIC0+XG4gICAgaXRlbXMgPSAkc2NvcGUuY2lyY3VpdC5mZWVkc1twaW5dXG4gICAgY29uc29sZS5sb2cgJ2RlbEZlZWQnLCBwaW4sIGluZGV4LCBpdGVtc1tpbmRleF1cbiAgICBpdGVtcy5zcGxpY2UgaW5kZXgsIDFcbiAgICBkZWxldGUgJHNjb3BlLmNpcmN1aXQuZmVlZHNbcGluXSAgaWYgaXRlbXMubGVuZ3RoIGlzIDBcbiAgXG4gICRzY29wZS4kd2F0Y2ggJ2N1cnJTZWwuaWQnLCAoeCkgLT5cbiAgICBjb25zb2xlLmxvZyAnZml4IGlkJywgeFxuICAgIHVwZGF0ZVBpbkxpc3QoKSAjIGZvciBuZXcgYW5kIGRlbGV0ZWQgZ2FkZ2V0c1xuICAkc2NvcGUuJHdhdGNoICdjdXJyU2VsLnRpdGxlJywgKHgpIC0+XG4gICAgY29uc29sZS5sb2cgJ2ZpeCB0aXRsZScsIHhcbiAgXG4gIGhhbmRsZXJzID1cbiAgICBhZGRHYWRnZXQ6ICh4LCB5KSAtPlxuICAgIGRlbEdhZGdldDogKGlkKSAtPlxuICAgIGFkZFdpcmU6IChmcm9tLCB0bykgLT5cbiAgICBkZWxXaXJlOiAoZnJvbSwgdG8pIC0+XG4gICAgc2VsZWN0R2FkZ2V0OiAoaWQpIC0+XG4gICAgbW92ZUdhZGdldDogKGlkLCB4LCB5KSAtPlxuICAgICAgXG4gICRzY29wZS4kb24gJ2NpcmN1aXQnLCAoZXZlbnQsIHR5cGUsIGFyZ3MuLi4pIC0+XG4gICAgY29uc29sZS5sb2cgJ0M6JywgdHlwZSwgYXJncy4uLlxuICAgIGhhbmRsZXJzW3R5cGVdIGFyZ3MuLi5cbiAgICBcbiAgc2V0dXAgPSAtPlxuICAgIGplZWJ1cy5hdHRhY2ggJ2NpcmN1aXQnXG4gICAgICAub24gJ3N5bmMnLCAtPlxuICAgICAgICAkc2NvcGUuY2lyY3VpdHMgPSBAcm93c1xuXG4gIHNldHVwKCkgIGlmICRzY29wZS5zZXJ2ZXJTdGF0dXMgaXMgJ2Nvbm5lY3RlZCdcbiAgJHNjb3BlLiRvbiAnd3Mtb3BlbicsIHNldHVwXG4iXX0=
