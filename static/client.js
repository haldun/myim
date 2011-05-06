(function() {
  $(function() {
    var $roster, jid, password, socket, status;
    status = 'offline';
    jid = 'haldun@optimus.local';
    password = 'haldun';
    $roster = $('#roster');
    socket = new io.Socket("localhost", {
      port: 3000
    });
    socket.on('connect', function() {
      return socket.send(JSON.stringify({
        command: 'login',
        jid: jid,
        password: password
      }));
    });
    socket.on('message', function(data) {
      var item, message, _i, _len, _ref, _results;
      message = (function() {
        try {
          return JSON.parse(data);
        } catch (_e) {}
      })();
      if (!message) {
        return;
      }
      if (message.type === 'status') {
        if (message.value === 'online') {
          socket.send(JSON.stringify({
            command: 'roster'
          }));
        }
        return status = message.value;
      } else if (message.type === 'roster') {
        _ref = message.items;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          item = _ref[_i];
          _results.push($('<li>').text(item).prependTo($roster).dblclick(function() {
            message = prompt();
            return socket.send(JSON.stringify({
              command: 'send',
              to: item,
              body: message
            }));
          }));
        }
        return _results;
      } else if (message.type === 'message') {
        return $('<div>').text(message.body).prependTo('#message-list');
      }
    });
    return socket.connect();
  });
}).call(this);
