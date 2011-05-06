# Where the magic happens
connect = require 'connect'
xmpp = require 'node-xmpp'
io = require 'socket.io'
port = 3000

# Configure connect application
app = connect(
  connect.compiler(src: __dirname + '/client', dest: __dirname + '/static', enable: ['coffeescript']),
  connect.compiler(src: __dirname + '/common', dest: __dirname + '/static', enable: ['coffeescript']),
  connect.static(__dirname + '/static'),
  connect.errorHandler dumpExceptions: true, showStack: true
)

# Create websocket listener and attach it to our app.
socket = io.listen app

# Here, connection is the connection to the web client and client is xmpp client
socket.on 'connection', (connection) ->
  client = null
  connection.on 'message', (data) ->
    message = try JSON.parse data

    # If we cannot parse the message, pass. If we have not created an xmpp client
    # yet, and the message is not a login message, again pass this message.
    return unless message or (client is null and message.command is not 'login')
    if message.command is 'login'
      {jid, password} = message
      client = new xmpp.Client jid: jid, password: password
      client.on 'online', () ->
        # When connected to the xmpp server, send a presence
        client.send new xmpp.Element('presence', type: 'chat')
        console.log "xmpp client connected with jid: #{client.jid}"

        # Send a message back to the web client, so that client knows she's online
        connection.send JSON.stringify type: 'status', value: 'online'
      client.on 'stanza', (stanza) ->
        # We've received a message from xmpp, pass it to the client with
        # appropriate packaging.
        # TODO Error handling needed here
        if stanza.is 'message'
          body = stanza.getChildren 'body'
          if body[0]
            connection.send JSON.stringify type: 'message', body: body[0].getText()
        else if stanza.is 'iq'
          items = (item.attrs.jid for item in stanza.getChild('query').getChildren('item'))
          connection.send JSON.stringify type: 'roster', items: items
    else if message.command is 'send'
      {to, body} = message
      client.send new xmpp.Element('message', to: to, type: 'chat').c('body').t(body)
    else if message.command is 'roster'
      client.send new xmpp.Element('iq', type: 'get').c('query', xmlns: 'jabber:iq:roster')
    else
      console.log "Unrecognized command: #{message.command}"

# Start the rock rolling
app.listen port
