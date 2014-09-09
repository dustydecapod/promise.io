PromiseIO = require 'promise.io/server'


server = new PromiseIO {
  someFunc: (input) ->
    return 'I got: ' + input
}

server.listen 3000
