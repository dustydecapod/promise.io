PromiseIO = require 'promise.io'
Q = require 'q'

client = new PromiseIO

client.connect 'http://localhost:3000'
  .then (remote) ->
    remote.someFunc 'my variable!'
    .progress (v) ->
      console.log v
