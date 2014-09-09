PromiseIO = require('./index')
SocketIO = require 'socket.io'

class Server extends PromiseIO
  listen: (port) ->
    @io  = new SocketIO port
    @io.on 'connect', @onConnect

module.exports = Server
