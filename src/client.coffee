PromiseIO = require('./index')
SocketIO = require 'socket.io-client'
Q = require 'q'

class Client extends PromiseIO
  connect: (url) ->
    @deferredReady = Q.defer()
    @io  = new SocketIO url
    @io.on 'connect', @onConnect
    return @deferredReady.promise

module.exports = Client
