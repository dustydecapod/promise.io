PromiseIO = require 'promise.io'
Q = require 'q'

server = new PromiseIO {
  someFunc: (input) ->
    @notify 1
}

server.listen 3000
