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
    var handlers, obj, setup, updatePinList;
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
      },
      StepGen: {
        shade: 'lightgreen',
        icon: '\uf013',
        inputs: 'Params',
        outputs: 'Out'
      },
      SSB: {
        shade: 'lightgray',
        icon: '\uf0b2',
        inputs: 'Cmds'
      }
    };
    $scope.circuit = {
      gadgets: {
        g1: {
          x: 120,
          y: 220,
          title: 'Gadget One',
          type: 'Pipe'
        },
        g2: {
          x: 300,
          y: 250,
          title: 'Gadget Two',
          type: 'Printer'
        },
        g3: {
          x: 320,
          y: 60,
          title: 'StepGen-X',
          type: 'StepGen'
        },
        g4: {
          x: 540,
          y: 70,
          title: 'SSB-X',
          type: 'SSB'
        },
        g5: {
          x: 340,
          y: 140,
          title: 'StepGen-Y',
          type: 'StepGen'
        },
        g6: {
          x: 520,
          y: 150,
          title: 'SSB-Y',
          type: 'SSB'
        }
      },
      wires: {
        'g1.Out/g2.In': 0,
        'g3.Out/g4.Cmds': 0,
        'g5.Out/g6.Cmds': 0
      },
      feeds: {
        'g2.In': [
          'some data', {
            Tag: 'blah',
            Msg: 'tagged data'
          }
        ],
        'g3.Params': [1000, 500],
        'g5.Params': [500, 1000]
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
    $scope.$watchCollection("circuits", (function(newNames, oldNames) {
      if (newNames != null) {
        return console.log(newNames.length);
      }
    }), true);
    $scope.$watch("circuits", (function(newValue, oldValue) {
      return console.log(oldValue, newValue);
    }), true);
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
    obj = 'demo1';
    handlers = {
      addGadget: function(x, y) {
        var date, id, type;
        if ($scope.newtype != null) {
          date = String(Date.now());
          id = "g" + date;
          type = $scope.newtype;
          obj = {
            title: "" + type + "-" + id,
            type: $scope.newtype,
            x: x,
            y: y
          };
          return jeebus.put("/circuit/demo1/" + id, obj);
        }
      },
      delGadget: function(id) {
        return jeebus.put("/circuit/demo1/" + id);
      },
      addWire: function(from, to) {
        return jeebus.send({
          cmd: 'ced-aw',
          obj: obj,
          from: from,
          to: to
        });
      },
      delWire: function(from, to) {
        return jeebus.send({
          cmd: 'ced-dw',
          obj: obj,
          from: from,
          to: to
        });
      },
      selectGadget: function(id) {
        return jeebus.send({
          cmd: 'ced-sg',
          obj: obj,
          id: id
        });
      },
      moveGadget: function(id, x, y) {
        return jeebus.send({
          cmd: 'ced-mg',
          obj: obj,
          id: id,
          x: x,
          y: y
        });
      }
    };
    $scope.$on('circuit', function() {
      var args, event, type;
      event = arguments[0], type = arguments[1], args = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      console.log.apply(console, ['C:', type].concat(__slice.call(args)));
      return handlers[type].apply(handlers, args);
    });
    setup = function() {
      return jeebus.attach('circuit').on('sync', function() {
        $scope.circuits = this.rows;
        return angular.forEach(this.rows, function(value) {
          return console.log(value);
        });
      }).on('data', function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return console.log(111, args);
      });
    };
    if ($scope.serverStatus === 'connected') {
      setup();
    }
    return $scope.$on('ws-open', setup);
  };

}).call(this);

//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiY2lyY3VpdHMuY29mZmVlIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBO0FBQUEsTUFBQSxnQkFBQTtJQUFBLGtCQUFBOztBQUFBLEVBQUEsRUFBQSxHQUFLLE9BQU8sQ0FBQyxNQUFSLENBQWUsT0FBZixDQUFMLENBQUE7O0FBQUEsRUFFQSxFQUFFLENBQUMsTUFBSCxDQUFVLFNBQUMsY0FBRCxFQUFpQixjQUFqQixHQUFBO0FBQ1IsSUFBQSxjQUFjLENBQUMsS0FBZixDQUFxQixVQUFyQixFQUNFO0FBQUEsTUFBQSxHQUFBLEVBQUssV0FBTDtBQUFBLE1BQ0EsV0FBQSxFQUFhLHlCQURiO0FBQUEsTUFFQSxVQUFBLEVBQVksWUFGWjtLQURGLENBQUEsQ0FBQTtXQUlBLGNBQWMsQ0FBQyxHQUFmLENBQW1CLFdBQW5CLEVBQWdDLFVBQWhDLEVBQTRDLEVBQTVDLEVBTFE7RUFBQSxDQUFWLENBRkEsQ0FBQTs7QUFBQSxFQVNBLFlBQUEsR0FBZSxTQUFDLE1BQUQsRUFBUyxNQUFULEdBQUE7QUFFYixRQUFBLG1DQUFBO0FBQUEsSUFBQSxNQUFNLENBQUMsT0FBUCxHQUNFO0FBQUEsTUFBQSxJQUFBLEVBQ0U7QUFBQSxRQUFBLElBQUEsRUFBTSxVQUFOO0FBQUEsUUFDQSxLQUFBLEVBQU8sYUFEUDtBQUFBLFFBRUEsSUFBQSxFQUFNLFFBRk47QUFBQSxRQUdBLE1BQUEsRUFBUSxJQUhSO0FBQUEsUUFJQSxPQUFBLEVBQVMsS0FKVDtPQURGO0FBQUEsTUFNQSxPQUFBLEVBQ0U7QUFBQSxRQUFBLEtBQUEsRUFBTyxXQUFQO0FBQUEsUUFDQSxJQUFBLEVBQU0sUUFETjtBQUFBLFFBRUEsTUFBQSxFQUFRLFFBRlI7T0FQRjtBQUFBLE1BVUEsT0FBQSxFQUNFO0FBQUEsUUFBQSxLQUFBLEVBQU8sWUFBUDtBQUFBLFFBQ0EsSUFBQSxFQUFNLFFBRE47QUFBQSxRQUVBLE1BQUEsRUFBUSxRQUZSO0FBQUEsUUFHQSxP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cHAnXG5cbm5nLmNvbmZpZyAoJHN0YXRlUHJvdmlkZXIsIG5hdmJhclByb3ZpZGVyKSAtPlxuICAkc3RhdGVQcm92aWRlci5zdGF0ZSAnY2lyY3VpdHMnLFxuICAgIHVybDogJy9jaXJjdWl0cydcbiAgICB0ZW1wbGF0ZVVybDogJy9jaXJjdWl0cy9jaXJjdWl0cy5odG1sJ1xuICAgIGNvbnRyb2xsZXI6IGNpcmN1aXRzQ3RybFxuICBuYXZiYXJQcm92aWRlci5hZGQgJy9jaXJjdWl0cycsICdDaXJjdWl0cycsIDMwXG5cbmNpcmN1aXRzQ3RybCA9ICgkc2NvcGUsIGplZWJ1cykgLT5cbiAgICBcbiAgJHNjb3BlLmdhZGdldHMgPVxuICAgIFBpcGU6XG4gICAgICBuYW1lOiAnUGlwZWxpbmUnXG4gICAgICBzaGFkZTogJ2xpZ2h0eWVsbG93J1xuICAgICAgaWNvbjogJ1xcdWYwNjEnICMgZmEtYXJyb3ctcmlnaHRcbiAgICAgIGlucHV0czogJ0luJ1xuICAgICAgb3V0cHV0czogJ091dCdcbiAgICBQcmludGVyOlxuICAgICAgc2hhZGU6ICdsaWdodGJsdWUnXG4gICAgICBpY29uOiAnXFx1ZjAyZicgIyBmYS1wcmludFxuICAgICAgaW5wdXRzOiAnSW4gSW4yJ1xuICAgIFN0ZXBHZW46XG4gICAgICBzaGFkZTogJ2xpZ2h0Z3JlZW4nXG4gICAgICBpY29uOiAnXFx1ZjAxMycgIyBmYS1jb2dcbiAgICAgIGlucHV0czogJ1BhcmFtcydcbiAgICAgIG91dHB1dHM6ICdPdXQnXG4gICAgU1NCOlxuICAgICAgc2hhZGU6ICdsaWdodGdyYXknXG4gICAgICBpY29uOiAnXFx1ZjBiMicgIyBmYS1hcnJvd3MtYWx0XG4gICAgICBpbnB1dHM6ICdDbWRzJ1xuICAgICAgXG4gICRzY29wZS5jaXJjdWl0ID1cbiAgICBnYWRnZXRzOlxuICAgICAgZzE6IHsgeDogMTIwLCB5OiAyMjAsIHRpdGxlOiAnR2FkZ2V0IE9uZScsIHR5cGU6ICdQaXBlJywgICAgfVxuICAgICAgZzI6IHsgeDogMzAwLCB5OiAyNTAsIHRpdGxlOiAnR2FkZ2V0IFR3bycsIHR5cGU6ICdQcmludGVyJywgfVxuICAgICAgZzM6IHsgeDogMzIwLCB5OiAgNjAsIHRpdGxlOiAnU3RlcEdlbi1YJywgIHR5cGU6ICdTdGVwR2VuJywgfVxuICAgICAgZzQ6IHsgeDogNTQwLCB5OiAgNzAsIHRpdGxlOiAnU1NCLVgnLCAgICAgIHR5cGU6ICdTU0InLCAgICAgfVxuICAgICAgZzU6IHsgeDogMzQwLCB5OiAxNDAsIHRpdGxlOiAnU3RlcEdlbi1ZJywgIHR5cGU6ICdTdGVwR2VuJywgfVxuICAgICAgZzY6IHsgeDogNTIwLCB5OiAxNTAsIHRpdGxlOiAnU1NCLVknLCAgICAgIHR5cGU6ICdTU0InLCAgICAgfVxuICAgIHdpcmVzOlxuICAgICAgJ2cxLk91dC9nMi5Jbic6IDBcbiAgICAgICdnMy5PdXQvZzQuQ21kcyc6IDBcbiAgICAgICdnNS5PdXQvZzYuQ21kcyc6IDBcbiAgICBmZWVkczpcbiAgICAgICdnMi5Jbic6IFsgJ3NvbWUgZGF0YScsIHsgVGFnOiAnYmxhaCcsIE1zZzogJ3RhZ2dlZCBkYXRhJyB9IF1cbiAgICAgICdnMy5QYXJhbXMnOiBbIDEwMDAsIDUwMCBdXG4gICAgICAnZzUuUGFyYW1zJzogWyA1MDAsIDEwMDAgXVxuICAgIGxhYmVsczpcbiAgICAgIEluOiAnZzIuSW4nXG4gICAgICBcbiAgdXBkYXRlUGluTGlzdCA9ICgpIC0+XG4gICAgJHNjb3BlLmlucHV0UGlucyA9IFtdXG4gICAgZm9yIGdpZCwgZyBvZiAkc2NvcGUuY2lyY3VpdC5nYWRnZXRzXG4gICAgICBpZiBpbnMgPSAkc2NvcGUuZ2FkZ2V0c1tnLnR5cGVdLmlucHV0c1xuICAgICAgICBmb3IgcCBpbiBpbnMuc3BsaXQgJyAnXG4gICAgICAgICAgJHNjb3BlLmlucHV0UGlucy5wdXNoIFwiI3tnaWR9LiN7cH1cIlxuICAgICRzY29wZS5pbnB1dFBpbnMuc29ydCgpXG4gIFxuICAjICRzY29wZS4kd2F0Y2ggXCJjaXJjdWl0c1wiLCAobmV3VmFsdWUsIG9sZFZhbHVlKSAtPlxuICAjICAgY29uc29sZS5sb2cgXCIkd2F0Y2hcIlxuICBcbiAgJHNjb3BlLiR3YXRjaENvbGxlY3Rpb24gXCJjaXJjdWl0c1wiLCAoKG5ld05hbWVzLCBvbGROYW1lcykgLT5cbiAgICBpZiBuZXdOYW1lcz9cbiAgICAgIGNvbnNvbGUubG9nIG5ld05hbWVzLmxlbmd0aCAgXG4gICksIHRydWVcbiAgXG4gICRzY29wZS4kd2F0Y2ggXCJjaXJjdWl0c1wiLCAoKG5ld1ZhbHVlLCBvbGRWYWx1ZSkgLT5cbiAgICBjb25zb2xlLmxvZyBvbGRWYWx1ZSwgbmV3VmFsdWVcbiAgICAjIGFuZ3VsYXIuZm9yRWFjaCBuZXdWYWx1ZSwgKHZhbHVlLCBrZXkpIC0+XG4gICAgIyAgIGNvbnNvbGUubG9nIFwiJHdhdGNoIGlkXCIsIHZhbHVlLmlkXG4gICksIHRydWVcbiAgXG4gICRzY29wZS4kd2F0Y2ggJ2FkZFBpbicsIChwaW4pIC0+XG4gICAgaWYgcGluXG4gICAgICAkc2NvcGUuY2lyY3VpdC5mZWVkc1twaW5dID89IFtdXG4gICAgICBjb25zb2xlLmxvZyAnYWRkRmVlZCcsIHBpbiwgJHNjb3BlLmNpcmN1aXQuZmVlZHNbcGluXS5sZW5ndGhcbiAgICAgICRzY29wZS5jaXJjdWl0LmZlZWRzW3Bpbl0ucHVzaCAnJ1xuICAgICAgJHNjb3BlLmFkZFBpbiA9IG51bGxcblxuICAkc2NvcGUuZGVsRmVlZCA9IChwaW4sIGluZGV4KSAtPlxuICAgIGl0ZW1zID0gJHNjb3BlLmNpcmN1aXQuZmVlZHNbcGluXVxuICAgIGNvbnNvbGUubG9nICdkZWxGZWVkJywgcGluLCBpbmRleCwgaXRlbXNbaW5kZXhdXG4gICAgaXRlbXMuc3BsaWNlIGluZGV4LCAxXG4gICAgZGVsZXRlICRzY29wZS5jaXJjdWl0LmZlZWRzW3Bpbl0gIGlmIGl0ZW1zLmxlbmd0aCBpcyAwXG4gIFxuICAkc2NvcGUuJHdhdGNoICdjdXJyU2VsLmlkJywgKHgpIC0+XG4gICAgY29uc29sZS5sb2cgJ2ZpeCBpZCcsIHhcbiAgICB1cGRhdGVQaW5MaXN0KCkgIyBmb3IgbmV3IGFuZCBkZWxldGVkIGdhZGdldHNcbiAgJHNjb3BlLiR3YXRjaCAnY3VyclNlbC50aXRsZScsICh4KSAtPlxuICAgIGNvbnNvbGUubG9nICdmaXggdGl0bGUnLCB4XG4gICAgXG4gIG9iaiA9ICdkZW1vMSdcbiAgXG4gIGhhbmRsZXJzID1cbiAgICBhZGRHYWRnZXQ6ICh4LCB5KSAtPiAgICAgIFxuICAgICAgaWYgJHNjb3BlLm5ld3R5cGU/IFxuICAgICAgICAjIHtcImZlZWRcIjp7XCJQYXJhbXNcIjpbMTAwMCw1MDBdfSxcInRpdGxlXCI6XCJTdGVwR2VuLVhcIixcInR5cGVcIjpcIlN0ZXBHZW5cIixcIndpcmVcIjp7XCJPdXRcIjpcImc0LkNtZHNcIn0sXCJ4XCI6MzIwLFwieVwiOjYwfVxuICAgICAgICBkYXRlID0gU3RyaW5nIERhdGUubm93KCkgXG4gICAgICAgIGlkPSBcImdcIiArIGRhdGUgI2RhdGUuc3Vic3RyKGRhdGUgLmxlbmd0aCAtIDkpICMgPT4gXCJUYWJzMVwiXG4gICAgICAgIHR5cGUgPSAkc2NvcGUubmV3dHlwZVxuICAgICAgICBvYmogPSB7dGl0bGU6XCIje3R5cGV9LSN7aWR9XCIsIHR5cGU6JHNjb3BlLm5ld3R5cGUsIHg6eCwgeTp5fVxuXG4gICAgICAgICMgamVlYnVzLnNlbmQgeyBjbWQ6ICdjZWQtYWcnLCBvYmp9XG4gICAgICAgIGplZWJ1cy5wdXQoXCIvY2lyY3VpdC9kZW1vMS8je2lkfVwiLCBvYmopXG4gICAgZGVsR2FkZ2V0OiAoaWQpIC0+ICAgICAgICBcbiAgICAgICMgamVlYnVzLnNlbmQgeyBjbWQ6ICdjZWQtZGcnLCBvYmosIGlkfVxuICAgICAgIyBwdXQgbmlsIHZhbHVlIHRvIGRlbGV0ZSBpZFxuICAgICAgamVlYnVzLnB1dChcIi9jaXJjdWl0L2RlbW8xLyN7aWR9XCIpICBcbiAgICBhZGRXaXJlOiAoZnJvbSwgdG8pIC0+ICAgIGplZWJ1cy5zZW5kIHsgY21kOiAnY2VkLWF3Jywgb2JqLCBmcm9tLCB0byB9XG4gICAgZGVsV2lyZTogKGZyb20sIHRvKSAtPiAgICBqZWVidXMuc2VuZCB7IGNtZDogJ2NlZC1kdycsIG9iaiwgZnJvbSwgdG8gfVxuICAgIHNlbGVjdEdhZGdldDogKGlkKSAtPiAgICAgamVlYnVzLnNlbmQgeyBjbWQ6ICdjZWQtc2cnLCBvYmosIGlkICAgICAgIH1cbiAgICBtb3ZlR2FkZ2V0OiAoaWQsIHgsIHkpIC0+IGplZWJ1cy5zZW5kIHsgY21kOiAnY2VkLW1nJywgb2JqLCBpZCwgeCwgeSB9XG5cbiAgJHNjb3BlLiRvbiAnY2lyY3VpdCcsIChldmVudCwgdHlwZSwgYXJncy4uLikgLT5cbiAgICBjb25zb2xlLmxvZyAnQzonLCB0eXBlLCBhcmdzLi4uXG4gICAgaGFuZGxlcnNbdHlwZV0gYXJncy4uLlxuICAgIFxuICBzZXR1cCA9IC0+XG4gICAgamVlYnVzLmF0dGFjaCAnY2lyY3VpdCdcbiAgICAgIC5vbiAnc3luYycsIC0+XG4gICAgICAgICRzY29wZS5jaXJjdWl0cyA9IEByb3dzXG4gICAgICAgIGFuZ3VsYXIuZm9yRWFjaCBAcm93cywgKHZhbHVlKSAtPlxuICAgICAgICAgIGNvbnNvbGUubG9nIHZhbHVlXG4gICAgICAub24gJ2RhdGEnLCAoYXJncy4uLikgLT4gXG4gICAgICAgIGNvbnNvbGUubG9nIDExMSwgYXJnc1xuICAgICAgXG4gICAgICAgICMxLiBUT0RPOiBjaGVjayBmb3IgdmFsdWUsIGVsc2UgcmVtb3ZlXG4gICAgICAgICMyLiBhZGQgdG8gY2lyY3VpdHNcbiAgICAgICAgIyAkc2NvcGUuY2lyY3VpdHMgcHVzaCBrLCB2XG4gICAgICAgICMzLiB0ZWxsIGVkaXRvclxuXG5cbiAgc2V0dXAoKSAgaWYgJHNjb3BlLnNlcnZlclN0YXR1cyBpcyAnY29ubmVjdGVkJ1xuICAkc2NvcGUuJG9uICd3cy1vcGVuJywgc2V0dXBcbiJdfQ==
