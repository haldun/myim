$ ->
  status = 'offline'
  jid = 'haldun@optimus.local'
  password = 'haldun'

  # ui elements
  $roster = $('#roster')

  # server communications
  socket = new io.Socket "localhost", port: 3000
  socket.on 'connect', () ->
    socket.send JSON.stringify command: 'login', jid: jid, password: password
  socket.on 'message', (data) ->
    message = try JSON.parse data
    return unless message
    if message.type is 'status'
      if message.value is 'online'
        socket.send JSON.stringify command: 'roster'
      status = message.value
    else if message.type is 'roster'
      for item in message.items
        $('<li>').text(item).prependTo($roster).dblclick () ->
          message = prompt()
          socket.send JSON.stringify command: 'send', to: item, body: message
    else if message.type is 'message'
      $('<div>').text(message.body).prependTo('#message-list')
  socket.connect()
