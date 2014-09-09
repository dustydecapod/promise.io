PromiseIO = require './promise.io-client'
Q = require 'q'

client = new PromiseIO

client.connect 'http://localhost:3000'
  .then (remote) ->
    remote.someFunc 'my variable!'
      .then (returnVal) -> console.log returnVal
      .catch (err) -> console.log err

