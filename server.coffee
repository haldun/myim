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

class Client
  constructor: (@app) ->
    @xmpp = null
    @socket = io.listen @app
    @socket.on 'connection', (@connection) =>
      connection.on 'message', @handleData

  handleData: (data) =>
    message = try JSON.parse data
    return unless message or (@xmpp is null and message.command is not 'login')
    @handleMessage message

  handleMessage: (message) =>
    {command} = message
    switch command
      when 'login' then @handleLogin message
      when 'send' then @handleSendMessage message
      when 'roster' then @handleRoster message
      else console.log "Unrecognized command: #{command}"

  handleLogin: ({jid, password} = message) ->
    @xmpp = new xmpp.Client jid: jid, password: password
    @xmpp.on 'online', () =>
      # When connected to the xmpp server, send a presence
      @xmpp.send new xmpp.Element('presence', type: 'chat')
      console.log "xmpp client connected with jid: #{@xmpp.jid}"
      # Send a message back to the web client, so that client knows she's online
      @connection.send JSON.stringify type: 'status', value: 'online'
    @xmpp.on 'stanza', (stanza) =>
      # We've received a message from xmpp, pass it to the client with
      # appropriate packaging.
      # TODO Error handling needed here
      if stanza.is 'message'
        body = stanza.getChildren 'body'
        if body[0]
          @connection.send JSON.stringify type: 'message', body: body[0].getText()
      else if stanza.is 'iq'
        items = (item.attrs.jid for item in stanza.getChild('query').getChildren('item'))
        @connection.send JSON.stringify type: 'roster', items: items

  handleSendMessage: ({to, body} = message) ->
    @xmpp.send new xmpp.Element('message', to: to, type: 'chat').c('body').t(body)

  handleRoster: () ->
    @xmpp.send new xmpp.Element('iq', type: 'get').c('query', xmlns: 'jabber:iq:roster')

client = new Client app
app.listen port
