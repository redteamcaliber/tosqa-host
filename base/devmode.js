(function() {
  var compileCoffeeScriptWithMap, compileIfNeeded, config, createWatcher, execFile, fatal, fs, main, moduleDir, npmExe, ok, packages, parseConfig, path, pid, recompileGoFiles, runMain, spawn, traverseDirs, watchDir, _ref,
    __slice = [].slice;

  fs = require('fs');

  path = require('path');

  _ref = require('child_process'), execFile = _ref.execFile, spawn = _ref.spawn;

  moduleDir = function(s) {
    return path.resolve('node_modules', s);
  };

  fatal = function(s) {
    console.error('\n[node] fatal error:', s);
    return process.exit(1);
  };

  main = void 0;

  pid = void 0;

  process.on('SIGINT', function() {
    return console.log(' (interrupt)');
  });

  runMain = function() {
    var args, f, _i, _len, _ref1;
    args = ['run'];
    _ref1 = fs.readdirSync('.');
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      f = _ref1[_i];
      if (/\.go$/i.test(f) && !/_test\./i.test(f)) {
        args.push(f);
        fs.watch(f, recompileGoFiles);
      }
    }
    args = args.concat(process.argv.slice(2));
    console.log('[node] go', args.join(' '));
    main = spawn('go', args, {
      stdio: ['ipc', process.stdout, process.stderr]
    });
    main.on('error', function(err) {
      return fatal('cannot launch "go"');
    });
    main.on('message', function(msg) {
      console.log('[node] pid message:', msg, '\n');
      return pid = msg | 0;
    });
    main.on('close', function(code) {
      if (code > 0) {
        return fatal('unexpected termination of "main", code: ' + code);
      }
    });
    main.on('exit', function() {
      return fatal('main exited');
    });
    main.on('disconnect', function() {
      console.log('[node] child disconnected');
      return process.exit(0);
    });
    return main.send(null);
  };

  recompileGoFiles = function() {
    if (pid > 0) {
      main.removeAllListeners();
      process.kill(pid, 'SIGHUP');
      pid = 0;
      return runMain();
    }
  };

  compileCoffeeScriptWithMap = function(sourceCode, filename) {
    var coffee, comment, compiled, convert;
    coffee = require(moduleDir('coffee-script'));
    compiled = coffee.compile(sourceCode, {
      filename: filename,
      sourceMap: true,
      inline: true,
      literate: path.extname(filename) !== '.coffee'
    });
    convert = require(moduleDir('convert-source-map'));
    comment = convert.fromJSON(compiled.v3SourceMap).setProperty('sources', [filename]).toComment();
    return "" + compiled.js + "\n" + comment + "\n";
  };

  compileIfNeeded = function(srcFile) {
    var destExt, destFile, destStat, err, jade, saveResult, src, srcExt, srcStat, stylus, t;
    if (/\.(coffee|coffee\.md|litcoffee|jade|styl)$/i.test(srcFile)) {
      srcExt = path.extname(srcFile);
      destExt = (function() {
        switch (srcExt) {
          case '.jade':
            return '.html';
          case '.styl':
            return '.css';
          default:
            return '.js';
        }
      })();
      destFile = srcFile.slice(0, -srcExt.length) + destExt;
      t = Date.now();
      saveResult = function(data) {
        var ms, n;
        n = data.length;
        ms = Date.now() - t;
        console.log("[node] compile " + srcFile + " -> " + destExt + " " + n + "b " + ms + " ms");
        return fs.writeFileSync(destFile, data);
      };
      try {
        srcStat = fs.statSync(srcFile);
        if (fs.existsSync(destFile)) {
          destStat = fs.statSync(destFile);
        }
        if (!((destStat != null ? destStat.mtime : void 0) >= srcStat.mtime)) {
          src = fs.readFileSync(srcFile, {
            encoding: 'utf8'
          });
          switch (srcExt) {
            case '.jade':
              jade = require(moduleDir('jade'));
              return saveResult(jade.compile(src, {
                filename: srcFile,
                pretty: true
              })());
            case '.styl':
              stylus = require(moduleDir('stylus'));
              return stylus.render(src, {
                filename: srcFile
              }, function(err, css) {
                if (err) {
                  return console.log('[node] stylus error', srcFile, err);
                } else {
                  return saveResult(css);
                }
              });
            default:
              return saveResult(compileCoffeeScriptWithMap(src, path.basename(srcFile)));
          }
        }
      } catch (_error) {
        err = _error;
        return console.log('[node] cannot compile', srcFile, err);
      }
    } else if (pid > 0) {
      if (/\.(html|js)$/i.test(srcFile)) {
        return main.send(true);
      } else if (/\.(css)$/i.test(srcFile)) {
        return main.send(false);
      } else if (/\.(go)$/i.test(srcFile)) {
        console.log('[node] changed', srcFile);
        return recompileGoFiles();
      }
    }
  };

  traverseDirs = function(dir, cb) {
    var f, stats, _i, _len, _ref1, _results;
    stats = fs.statSync(dir);
    if (stats.isDirectory()) {
      cb(dir);
      _ref1 = fs.readdirSync(dir);
      _results = [];
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        f = _ref1[_i];
        _results.push(traverseDirs(path.join(dir, f), cb));
      }
      return _results;
    }
  };

  watchDir = function(root, cb) {
    return traverseDirs(root, function(dir) {
      return fs.watch(dir, function(event, filename) {
        var file;
        file = path.join(dir, filename);
        return cb(event, file);
      });
    });
  };

  createWatcher = function(root) {
    if (fs.existsSync(root)) {
      console.log(' ', root);
      return traverseDirs(root, function(dir) {
        var f, _i, _len, _ref1;
        _ref1 = fs.readdirSync(dir);
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          f = _ref1[_i];
          compileIfNeeded(path.join(dir, f));
        }
        return fs.watch(dir, function(event, filename) {
          var file;
          file = path.join(dir, filename);
          if (fs.existsSync(file)) {
            return compileIfNeeded(file);
          } else {

          }
        });
      });
    }
  };

  parseConfig = function(fn) {
    var i, k, line, map, v, _i, _len, _ref1;
    map = {};
    if (fs.existsSync(fn)) {
      _ref1 = fs.readFileSync(fn, 'utf8').split('\n');
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        line = _ref1[_i];
        i = line.indexOf('=');
        if (i > 0 && line.trim()[0] !== '#') {
          k = line.slice(0, i).trim();
          v = line.slice(i + 1).trim();
          map[k] = v;
        }
      }
    }
    return map;
  };

  console.log('[node] watching for file changes in:');

  config = parseConfig('./config.txt');

  createWatcher(process.env.APP_DIR || config.APP_DIR || './app');

  createWatcher(process.env.BASE_DIR || config.BASE_DIR || './base');

  createWatcher(process.env.GADGETS_DIR || config.GADGETS_DIR || './gadgets');

  try {
    ok = require(moduleDir('convert-source-map'));
  } catch (_error) {}

  if (ok) {
    runMain();
  } else {
    packages = ['coffee-script', 'convert-source-map', 'jade', 'stylus'];
    console.log('[node] installing npm packages:', packages.join(', '));
    npmExe = process.platform === 'win32' ? 'npm.cmd' : 'npm';
    execFile(npmExe, ['install'].concat(__slice.call(packages)), {
      env: process.env
    }, function(err, o, e) {
      if (err != null) {
        fatal(err);
      }
      return runMain();
    });
  }

}).call(this);

//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiZGV2bW9kZS5jb2ZmZWUiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBR0E7QUFBQSxNQUFBLHNOQUFBO0lBQUEsa0JBQUE7O0FBQUEsRUFBQSxFQUFBLEdBQUssT0FBQSxDQUFRLElBQVIsQ0FBTCxDQUFBOztBQUFBLEVBQ0EsSUFBQSxHQUFPLE9BQUEsQ0FBUSxNQUFSLENBRFAsQ0FBQTs7QUFBQSxFQUVBLE9BQW1CLE9BQUEsQ0FBUSxlQUFSLENBQW5CLEVBQUMsZ0JBQUEsUUFBRCxFQUFVLGFBQUEsS0FGVixDQUFBOztBQUFBLEVBS0EsU0FBQSxHQUFZLFNBQUMsQ0FBRCxHQUFBO1dBQU8sSUFBSSxDQUFDLE9BQUwsQ0FBYSxjQUFiLEVBQTZCLENBQTdCLEVBQVA7RUFBQSxDQUxaLENBQUE7O0FBQUEsRUFPQSxLQUFBLEdBQVEsU0FBQyxDQUFELEdBQUE7QUFDTixJQUFBLE9BQU8sQ0FBQyxLQUFSLENBQWMsdUJBQWQsRUFBdUMsQ0FBdkMsQ0FBQSxDQUFBO1dBQ0EsT0FBTyxDQUFDLElBQVIsQ0FBYSxDQUFiLEVBRk07RUFBQSxDQVBSLENBQUE7O0FBQUEsRUFXQSxJQUFBLEdBQU8sTUFYUCxDQUFBOztBQUFBLEVBWUEsR0FBQSxHQUFNLE1BWk4sQ0FBQTs7QUFBQSxFQWVBLE9BQU8sQ0FBQyxFQUFSLENBQVcsUUFBWCxFQUFxQixTQUFBLEdBQUE7V0FDbkIsT0FBTyxDQUFDLEdBQVIsQ0FBWSxjQUFaLEVBRG1CO0VBQUEsQ0FBckIsQ0FmQSxDQUFBOztBQUFBLEVBbUJBLE9BQUEsR0FBVSxTQUFBLEdBQUE7QUFDUixRQUFBLHdCQUFBO0FBQUEsSUFBQSxJQUFBLEdBQU8sQ0FBQyxLQUFELENBQVAsQ0FBQTtBQUNBO0FBQUEsU0FBQSw0Q0FBQTtvQkFBQTtBQUNFLE1BQUEsSUFBRyxRQUFRLENBQUMsSUFBVCxDQUFjLENBQWQsQ0FBQSxJQUFxQixDQUFBLFVBQWMsQ0FBQyxJQUFYLENBQWdCLENBQWhC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O0FBQUEsRUF5S0EsYUFBQSxDQUFjLE9BQU8sQ0FBQyxHQUFHLENBQUMsV0FBWixJQUEyQixNQUFNLENBQUMsV0FBbEMsSUFBaUQsV0FBL0QsQ0F6S0EsQ0FBQTs7QUE4S0E7QUFBSSxJQUFBLEVBQUEsR0FBSyxPQUFBLENBQVEsU0FBQSxDQUFVLG9CQUFWLENBQVIsQ0FBTCxDQUFKO0dBQUEsa0JBOUtBOztBQStLQSxFQUFBLElBQUcsRUFBSDtBQUNFLElBQUEsT0FBQSxDQUFBLENBQUEsQ0FERjtHQUFBLE1BQUE7QUFHRSxJQUFBLFFBQUEsR0FBVyxDQUFDLGVBQUQsRUFBa0Isb0JBQWxCLEVBQXdDLE1BQXhDLEVBQWdELFFBQWhELENBQVgsQ0FBQTtBQUFBLElBQ0EsT0FBTyxDQUFDLEdBQVIsQ0FBWSxpQ0FBWixFQUErQyxRQUFRLENBQUMsSUFBVCxDQUFjLElBQWQsQ0FBL0MsQ0FEQSxDQUFBO0FBQUEsSUFFQSxNQUFBLEdBQVksT0FBTyxDQUFDLFFBQVIsS0FBb0IsT0FBdkIsR0FBb0MsU0FBcEMsR0FBbUQsS0FGNUQsQ0FBQTtBQUFBLElBR0EsUUFBQSxDQUFTLE1BQVQsRUFBa0IsQ0FBQSxTQUFXLFNBQUEsYUFBQSxRQUFBLENBQUEsQ0FBN0IsRUFBMkM7QUFBQSxNQUFDLEdBQUEsRUFBSSxPQUFPLENBQUMsR0FBYjtLQUEzQyxFQUE4RCxTQUFDLEdBQUQsRUFBTSxDQUFOLEVBQVMsQ0FBVCxHQUFBO0FBQzVELE1BQUEsSUFBYyxXQUFkO0FBQUEsUUFBQSxLQUFBLENBQU0sR0FBTixDQUFBLENBQUE7T0FBQTthQUNBLE9BQUEsQ0FBQSxFQUY0RDtJQUFBLENBQTlELENBSEEsQ0FIRjtHQS9LQTtBQUFBIiwic291cmNlc0NvbnRlbnQiOlsiIyBKZWVCdXMgZGV2ZWxvcG1lbnQgbW9kZTogcmUtY29tcGlsZXMgR28gYW5kIENTL0phZGUvU3R5bHVzIGFzIG5lZWRlZFxuIyAtamN3LCAyMDE0LTAyLTE5XG5cbmZzID0gcmVxdWlyZSAnZnMnXG5wYXRoID0gcmVxdWlyZSAncGF0aCdcbntleGVjRmlsZSxzcGF3bn0gPSByZXF1aXJlICdjaGlsZF9wcm9jZXNzJ1xuXG4jIGxvb2sgZm9yIG1vZHVsZXMgcmVsYXRpdmUgdG8gdGhlIGN1cnJlbnQgZGlyZWN0b3J5LCBub3QgcmVsYXRpdmUgdG8gdGhpcyBmaWxlXG5tb2R1bGVEaXIgPSAocykgLT4gcGF0aC5yZXNvbHZlICdub2RlX21vZHVsZXMnLCBzXG5cbmZhdGFsID0gKHMpIC0+XG4gIGNvbnNvbGUuZXJyb3IgJ1xcbltub2RlXSBmYXRhbCBlcnJvcjonLCBzXG4gIHByb2Nlc3MuZXhpdCAxXG5cbm1haW4gPSB1bmRlZmluZWRcbnBpZCA9IHVuZGVmaW5lZFxuXG4jIGludGVycnVwdHMgZG9uJ3QgcXVpdCB1cywganVzdCB0aGUgY2hpbGQgcHJvY2Vzcywgc2VlIHRoZSBleHBsYW5hdGlvbiBiZWxvd1xucHJvY2Vzcy5vbiAnU0lHSU5UJywgLT5cbiAgY29uc29sZS5sb2cgJyAoaW50ZXJydXB0KSdcblxuIyBsYXVuY2ggdGhlIG1haW4gYXBwIGJ5IGNvbXBpbGluZyBhbGwgaXRzIC5nbyBmaWxlcyB2aWEgXCJnbyBnZXRcIlxucnVuTWFpbiA9IC0+XG4gIGFyZ3MgPSBbJ3J1biddXG4gIGZvciBmIGluIGZzLnJlYWRkaXJTeW5jICcuJ1xuICAgIGlmIC9cXC5nbyQvaS50ZXN0KGYpIGFuZCBub3QgL190ZXN0XFwuL2kudGVzdChmKVxuICAgICAgYXJncy5wdXNoIGZcbiAgICAgIGZzLndhdGNoIGYsIHJlY29tcGlsZUdvRmlsZXNcbiAgYXJncyA9IGFyZ3MuY29uY2F0IHByb2Nlc3MuYXJndi5zbGljZSgyKVxuICBjb25zb2xlLmxvZyAnW25vZGVdIGdvJywgYXJncy5qb2luICcgJ1xuICBtYWluID0gc3Bhd24gJ2dvJywgYXJncywgc3RkaW86IFsnaXBjJywgcHJvY2Vzcy5zdGRvdXQsIHByb2Nlc3Muc3RkZXJyXVxuICBcbiAgIyBUaGVyZSdzIHNvbWUgbmFzdGluZXNzIGludm9sdmVkIGluIG1hbmFnaW5nIHRoZSBcIm1haW5cIiBjaGlsZCBwcm9jZXNzOlxuICAjXG4gICMgTm9kZS5qcyBsYXVuY2hlcyBcImdvIHJ1biAuLi5cIiwgd2hpY2ggY29tcGlsZXMgYW5kIHJ1bnMgYSAqc3ViKiBwcm9jZXNzLCBzb1xuICAjIGFsbCBpbiBhbGwgdGhlcmUgYXJlIHRocmVlIHByb2Nlc3NlcyBydW5uaW5nIGluIGRldiBtb2RlOiBub2RlLmpzLCB0aGUgXCJnb1wiXG4gICMgd3JhcHBlciwgYW5kIHRoZSBjb21waWxlZCB0YXJnZXQgKHNlcnZlcikgYXBwLiBGb3IgbGl2ZSByZWxvYWQsIHdoZW4gdGhlXG4gICMgYXBwIGl0c2VsZiBuZWVkcyB0byBiZSByZXN0YXJ0ZWQsIHdlIG5lZWQgdG8gZmlndXJlIG91dCB0aGUgYXBwJ3MgUElELCBub3RcbiAgIyBqdXN0IHRoZSBwaWQgb2YgdGhlIFwibWFpblwiIGNoaWxkIHByb2Nlc3MuIFRoaXMgaXMgaGFuZGxlZCBieSBoYXZpbmcgdGhlXG4gICMgc2VydmVyIHJlcG9ydCBpdHMgcGlkIG92ZXIgdGhlIG1lc3NhZ2UgY2hhbm5lbCBzZXQgdXAgYnkgbm9kZS5qcydzIFwiaXBjXCIuXG4gICMgT25jZSB0aGUgYXBwJ3MgcGlkIGlzIGtub3duLCByZWNvbXBpbGVHb0ZpbGVzKCkgY2FuIHVzZSB0aGF0IHdoZW4gaXQgd2FudHNcbiAgIyB0byBmb3JjZSBhIHJlc3RhcnQuIFRoaXMgaW52b2x2ZXMgc2VuZGluZyBTSUdIVVAgdG8gdGhlIHNlcnZlciBhcHAsIHdoaWNoXG4gICMgdGhlbiAoY2xlYW5zIHVwIGFuZCkgZXhpdHMsIGNhdXNpbmcgXCJnb1wiIHRvIHJlcG9ydCBcImV4aXQgc3RhdHVzIDJcIiBhbmQgdGhlblxuICAjIGluIHR1cm4gZXhpdHMuIEF0IHRoaXMgcG9pbnQsIHRoZSBpcGMgY2hhbm5lbCBnZXRzIGRpc2Nvbm5lY3RlZCBhbmQgbm9kZS5qc1xuICAjIGl0c2VsZiB3aWxsIGV4aXQuIFRoZXJlJ3MgYSBkdW1teSBcInByb2Nlc3Mub24gJ1NJR0lOVCcsIC0+IC4uLlwiIGFib3ZlLCBzb1xuICAjIHRoYXQgdGhpcyBub2RlLmpzIHNjcmlwdCBkb2Vzbid0IGV4aXQgYmVmb3JlIGFsbCB0aGUgY2hpbGQgY2xlYW51cCBpcyBkb25lLlxuXG4gIG1haW4ub24gJ2Vycm9yJywgKGVycikgLT5cbiAgICBmYXRhbCAnY2Fubm90IGxhdW5jaCBcImdvXCInXG4gIG1haW4ub24gJ21lc3NhZ2UnLCAobXNnKSAtPlxuICAgIGNvbnNvbGUubG9nICdbbm9kZV0gcGlkIG1lc3NhZ2U6JywgbXNnLCAnXFxuJ1xuICAgIHBpZCA9IG1zZyB8IDAgIyB0aGlzIGlzIG9ubHkgPiAwIHdoZW4gYSBwbGFpbiBudW1iZXIgaXMgcmVjZWl2ZWRcbiAgbWFpbi5vbiAnY2xvc2UnLCAoY29kZSkgLT5cbiAgICBmYXRhbCAndW5leHBlY3RlZCB0ZXJtaW5hdGlvbiBvZiBcIm1haW5cIiwgY29kZTogJyArIGNvZGUgIGlmIGNvZGUgPiAwXG4gIG1haW4ub24gJ2V4aXQnLCAtPlxuICAgIGZhdGFsICdtYWluIGV4aXRlZCdcbiAgbWFpbi5vbiAnZGlzY29ubmVjdCcsIC0+XG4gICAgY29uc29sZS5sb2cgJ1tub2RlXSBjaGlsZCBkaXNjb25uZWN0ZWQnXG4gICAgcHJvY2Vzcy5leGl0IDBcbiAgbWFpbi5zZW5kIG51bGxcblxuIyByZS1jb21waWxlIHdoZW4gYSAuZ28gZmlsZXMgY2hhbmdlcywgaWYgdGhlIHJ1bm5pbmcgcHJvY2VzcyBpcyBrbm93blxucmVjb21waWxlR29GaWxlcyA9IC0+XG4gIGlmIHBpZCA+IDBcbiAgICBtYWluLnJlbW92ZUFsbExpc3RlbmVycygpICMgcHJldmVudCB0cmlnZ2VyaW5nIG9uIHRoZSAnZXhpdCcgZXZlbnRcbiAgICBwcm9jZXNzLmtpbGwgcGlkLCAnU0lHSFVQJ1xuICAgIHBpZCA9IDBcbiAgICBydW5NYWluKClcblxuY29tcGlsZUNvZmZlZVNjcmlwdFdpdGhNYXAgPSAoc291cmNlQ29kZSwgZmlsZW5hbWUpIC0+XG4gIGNvZmZlZSA9IHJlcXVpcmUgbW9kdWxlRGlyICdjb2ZmZWUtc2NyaXB0J1xuICBjb21waWxlZCA9IGNvZmZlZS5jb21waWxlIHNvdXJjZUNvZGUsXG4gICAgZmlsZW5hbWU6IGZpbGVuYW1lXG4gICAgc291cmNlTWFwOiB0cnVlXG4gICAgaW5saW5lOiB0cnVlXG4gICAgbGl0ZXJhdGU6IHBhdGguZXh0bmFtZShmaWxlbmFtZSkgaXNudCAnLmNvZmZlZSdcbiAgY29udmVydCA9IHJlcXVpcmUgbW9kdWxlRGlyICdjb252ZXJ0LXNvdXJjZS1tYXAnXG4gIGNvbW1lbnQgPSBjb252ZXJ0XG4gICAgLmZyb21KU09OKGNvbXBpbGVkLnYzU291cmNlTWFwKVxuICAgIC5zZXRQcm9wZXJ0eSgnc291cmNlcycsIFtmaWxlbmFtZV0pIFxuICAgIC50b0NvbW1lbnQoKVxuICBcIiN7Y29tcGlsZWQuanN9XFxuI3tjb21tZW50fVxcblwiXG4gIFxuY29tcGlsZUlmTmVlZGVkID0gKHNyY0ZpbGUpIC0+XG4gIGlmIC9cXC4oY29mZmVlfGNvZmZlZVxcLm1kfGxpdGNvZmZlZXxqYWRlfHN0eWwpJC9pLnRlc3Qgc3JjRmlsZVxuICAgIHNyY0V4dCA9IHBhdGguZXh0bmFtZSBzcmNGaWxlXG4gICAgZGVzdEV4dCA9IHN3aXRjaCBzcmNFeHRcbiAgICAgIHdoZW4gJy5qYWRlJyB0aGVuICcuaHRtbCdcbiAgICAgIHdoZW4gJy5zdHlsJyB0aGVuICcuY3NzJ1xuICAgICAgZWxzZSAgICAgICAgICAgICAgJy5qcydcbiAgICBkZXN0RmlsZSA9IHNyY0ZpbGUuc2xpY2UoMCwgLSBzcmNFeHQubGVuZ3RoKSArIGRlc3RFeHRcblxuICAgIHQgPSBEYXRlLm5vdygpXG4gICAgc2F2ZVJlc3VsdCA9IChkYXRhKSAtPlxuICAgICAgbiA9IGRhdGEubGVuZ3RoXG4gICAgICBtcyA9IERhdGUubm93KCkgLSB0XG4gICAgICBjb25zb2xlLmxvZyBcIltub2RlXSBjb21waWxlICN7c3JjRmlsZX0gLT4gI3tkZXN0RXh0fSAje259YiAje21zfSBtc1wiXG4gICAgICBmcy53cml0ZUZpbGVTeW5jIGRlc3RGaWxlLCBkYXRhXG5cbiAgICB0cnlcbiAgICAgIHNyY1N0YXQgPSBmcy5zdGF0U3luYyBzcmNGaWxlXG4gICAgICBkZXN0U3RhdCA9IGZzLnN0YXRTeW5jIGRlc3RGaWxlICBpZiBmcy5leGlzdHNTeW5jIGRlc3RGaWxlXG4gICAgICB1bmxlc3MgZGVzdFN0YXQ/Lm10aW1lID49IHNyY1N0YXQubXRpbWVcbiAgICAgICAgc3JjID0gZnMucmVhZEZpbGVTeW5jIHNyY0ZpbGUsIGVuY29kaW5nOiAndXRmOCdcbiAgICAgICAgc3dpdGNoIHNyY0V4dFxuICAgICAgICAgIHdoZW4gJy5qYWRlJ1xuICAgICAgICAgICAgamFkZSA9IHJlcXVpcmUgbW9kdWxlRGlyICdqYWRlJ1xuICAgICAgICAgICAgc2F2ZVJlc3VsdCBkbyBqYWRlLmNvbXBpbGUgc3JjLCBmaWxlbmFtZTogc3JjRmlsZSwgcHJldHR5OiB0cnVlXG4gICAgICAgICAgd2hlbiAnLnN0eWwnXG4gICAgICAgICAgICBzdHlsdXMgPSByZXF1aXJlIG1vZHVsZURpciAnc3R5bHVzJ1xuICAgICAgICAgICAgc3R5bHVzLnJlbmRlciBzcmMsIHsgZmlsZW5hbWU6IHNyY0ZpbGUgfSwgKGVyciwgY3NzKSAtPlxuICAgICAgICAgICAgICBpZiBlcnJcbiAgICAgICAgICAgICAgICBjb25zb2xlLmxvZyAnW25vZGVdIHN0eWx1cyBlcnJvcicsIHNyY0ZpbGUsIGVyclxuICAgICAgICAgICAgICBlbHNlXG4gICAgICAgICAgICAgICAgc2F2ZVJlc3VsdCBjc3NcbiAgICAgICAgICBlbHNlXG4gICAgICAgICAgICBzYXZlUmVzdWx0IGNvbXBpbGVDb2ZmZWVTY3JpcHRXaXRoTWFwIHNyYywgcGF0aC5iYXNlbmFtZSBzcmNGaWxlXG4gICAgY2F0Y2ggZXJyXG4gICAgICBjb25zb2xlLmxvZyAnW25vZGVdIGNhbm5vdCBjb21waWxlJywgc3JjRmlsZSwgZXJyXG4gIGVsc2UgaWYgcGlkID4gMFxuICAgIGlmIC9cXC4oaHRtbHxqcykkL2kudGVzdCBzcmNGaWxlXG4gICAgICBtYWluLnNlbmQgdHJ1ZSAjIHJlcXVlc3QgYSBmdWxsIHBhZ2UgcmVsb2FkXG4gICAgZWxzZSBpZiAvXFwuKGNzcykkL2kudGVzdCBzcmNGaWxlXG4gICAgICBtYWluLnNlbmQgZmFsc2UgIyByZXF1ZXN0IGEgc3R5bGVzaGVldCByZWxvYWRcbiAgICBlbHNlIGlmIC9cXC4oZ28pJC9pLnRlc3Qgc3JjRmlsZVxuICAgICAgY29uc29sZS5sb2cgJ1tub2RlXSBjaGFuZ2VkJywgc3JjRmlsZVxuICAgICAgcmVjb21waWxlR29GaWxlcygpXG5cbnRyYXZlcnNlRGlycyA9IChkaXIsIGNiKSAtPiAjIHJlY3Vyc2l2ZSBkaXJlY3RvcnkgdHJhdmVyc2FsXG4gIHN0YXRzID0gZnMuc3RhdFN5bmMgZGlyXG4gIGlmIHN0YXRzLmlzRGlyZWN0b3J5KClcbiAgICBjYiBkaXJcbiAgICBmb3IgZiBpbiBmcy5yZWFkZGlyU3luYyBkaXJcbiAgICAgIHRyYXZlcnNlRGlycyBwYXRoLmpvaW4oZGlyLCBmKSwgY2Jcblxud2F0Y2hEaXIgPSAocm9vdCwgY2IpIC0+ICMgcmVjdXJzaXZlIGRpcmVjdG9yeSB3YXRjaGVyXG4gIHRyYXZlcnNlRGlycyByb290LCAoZGlyKSAtPlxuICAgIGZzLndhdGNoIGRpciwgKGV2ZW50LCBmaWxlbmFtZSkgLT5cbiAgICAgIGZpbGUgPSBwYXRoLmpvaW4gZGlyLCBmaWxlbmFtZVxuICAgICAgY2IgZXZlbnQsIGZpbGVcblxuY3JlYXRlV2F0Y2hlciA9IChyb290KSAtPlxuICBpZiBmcy5leGlzdHNTeW5jIHJvb3RcbiAgICBjb25zb2xlLmxvZyAnICcsIHJvb3RcbiAgICB0cmF2ZXJzZURpcnMgcm9vdCwgKGRpcikgLT5cbiAgICAgIGZvciBmIGluIGZzLnJlYWRkaXJTeW5jIGRpclxuICAgICAgICBjb21waWxlSWZOZWVkZWQgcGF0aC5qb2luIGRpciwgZlxuICAgICAgZnMud2F0Y2ggZGlyLCAoZXZlbnQsIGZpbGVuYW1lKSAtPlxuICAgICAgICBmaWxlID0gcGF0aC5qb2luIGRpciwgZmlsZW5hbWVcbiAgICAgICAgaWYgZnMuZXhpc3RzU3luYyBmaWxlXG4gICAgICAgICAgY29tcGlsZUlmTmVlZGVkIGZpbGVcbiAgICAgICAgZWxzZVxuICAgICAgICAgICMgVE9ETzogZGVsZXRlIGNvbXBpbGVkIGZpbGVcblxucGFyc2VDb25maWcgPSAoZm4pIC0+XG4gIG1hcCA9IHt9XG4gIGlmIGZzLmV4aXN0c1N5bmMgZm5cbiAgICBmb3IgbGluZSBpbiBmcy5yZWFkRmlsZVN5bmMoZm4sICd1dGY4Jykuc3BsaXQgJ1xcbidcbiAgICAgIGkgPSBsaW5lLmluZGV4T2YoJz0nKVxuICAgICAgaWYgaSA+IDAgYW5kIGxpbmUudHJpbSgpWzBdIGlzbnQgJyMnXG4gICAgICAgIGsgPSBsaW5lLnNsaWNlKDAsIGkpLnRyaW0oKVxuICAgICAgICB2ID0gbGluZS5zbGljZShpKzEpLnRyaW0oKVxuICAgICAgICBtYXBba10gPSB2XG4gIG1hcFxuXG4jIFN0YXJ0IG9mIGRldm1vZGUgYXBwbGljYXRpb24gY29kZSAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLVxuXG5jb25zb2xlLmxvZyAnW25vZGVdIHdhdGNoaW5nIGZvciBmaWxlIGNoYW5nZXMgaW46J1xuXG5jb25maWcgPSBwYXJzZUNvbmZpZyAnLi9jb25maWcudHh0J1xuY3JlYXRlV2F0Y2hlciBwcm9jZXNzLmVudi5BUFBfRElSIG9yIGNvbmZpZy5BUFBfRElSIG9yICcuL2FwcCdcbmNyZWF0ZVdhdGNoZXIgcHJvY2Vzcy5lbnYuQkFTRV9ESVIgb3IgY29uZmlnLkJBU0VfRElSIG9yICcuL2Jhc2UnXG5jcmVhdGVXYXRjaGVyIHByb2Nlc3MuZW52LkdBREdFVFNfRElSIG9yIGNvbmZpZy5HQURHRVRTX0RJUiBvciAnLi9nYWRnZXRzJ1xuXG4jIGlmIHRoZSBjb252ZXJ0LXNvdXJjZS1tYXAgcGFja2FnZSBpcyBwcmVzZW50LCB0aGVuIG90aGVycyBwcm9iYWJseSBhbHNvIGFyZVxuIyBkb24ndCBsb2FkIHRoZSBvdGhlcnMgaW4geWV0LCBqYWRlIGluIHBhcnRpY3VsYXIgdGFrZXMgdG9vIG11Y2ggdGltZVxuIyBwYWNrYWdlcyB3aWxsIGJlIGxvYWRlZCBvbiBmaXJzdCBkZXRlY3RlZCBmaWxlIGNoYW5nZSB3aGljaCBuZWVkcyB0aGVtXG50cnkgb2sgPSByZXF1aXJlIG1vZHVsZURpciAnY29udmVydC1zb3VyY2UtbWFwJ1xuaWYgb2tcbiAgcnVuTWFpbigpXG5lbHNlXG4gIHBhY2thZ2VzID0gWydjb2ZmZWUtc2NyaXB0JywgJ2NvbnZlcnQtc291cmNlLW1hcCcsICdqYWRlJywgJ3N0eWx1cyddXG4gIGNvbnNvbGUubG9nICdbbm9kZV0gaW5zdGFsbGluZyBucG0gcGFja2FnZXM6JywgcGFja2FnZXMuam9pbiAnLCAnXG4gIG5wbUV4ZSA9IGlmIHByb2Nlc3MucGxhdGZvcm0gPT0gJ3dpbjMyJyB0aGVuICducG0uY21kJyBlbHNlICducG0nXG4gIGV4ZWNGaWxlIG5wbUV4ZSwgWydpbnN0YWxsJywgcGFja2FnZXMuLi5dLCB7ZW52OnByb2Nlc3MuZW52fSwgKGVyciwgbywgZSkgLT5cbiAgICBmYXRhbCBlcnIgIGlmIGVycj9cbiAgICBydW5NYWluKClcbiJdfQ==
