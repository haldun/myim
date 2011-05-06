connect = require 'connect'
xmpp = require 'node-xmpp'
io = require 'socket.io'
port = 3000
app = connect(
  connect.compiler(src: __dirname + '/client', dest: __dirname + '/static', enable: ['coffeescript']),
  connect.compiler(src: __dirname + '/common', dest: __dirname + '/static', enable: ['coffeescript']),
  connect.static(__dirname + '/static'),
  connect.errorHandler dumpExceptions: true, showStack: true
)
socket = io.listen app
# Here, connection => connection to the web client
#       client     => xmpp client
socket.on 'connection', (connection) ->
  client = null

  connection.on 'message', (data) ->
    console.log data
    message = try JSON.parse data
    return unless message or (client is null and message.command is not 'login')

    if message.command is 'login'
      {jid, password} = message
      client = new xmpp.Client jid: jid, password: password
      client.on 'online', () ->
        client.send new xmpp.Element('presence', type: 'chat')
        console.log "xmpp client connected with jid: #{client.jid}"
        connection.send JSON.stringify type: 'status', value: 'online'
      client.on 'stanza', (stanza) ->
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

app.listen port
