switch day
  when "Mon" then go work
  when "Tue" then go relax
  when "Thu" then go iceFishing
  when "Fri"
    if day is bingoDay
      go bingo
      go dancing
  when "Sun" then go church
  else go work

# message =
#   command: 'naber'
# {command, data} = message
# console.log command
# console.log data
#
# # xmpp = require 'node-xmpp'
# # client = new xmpp.Client jid: 'haldun@optimus.local', password: 'haldun'
# # client.on 'online', () ->
# #   client.send new xmpp.Element('presence', type: 'chat')
# #   client.send new xmpp.Element('iq', type: 'get').c('query', xmlns: 'jabber:iq:roster')
# # client.on 'stanza', (stanza) ->
# #   if stanza.is 'iq'
# #     for item in stanza.getChild('query').getChildren('item')
# #       console.log item.attrs