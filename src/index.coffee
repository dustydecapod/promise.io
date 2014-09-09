Q = require 'q'
uuid = require 'uuid'

class PromiseSession
  constructor: (@io, @socket) ->
    @id = uuid.v4()
    @promises = {}
    @socket.emit 'exports', @io.constructExportsMessage()
    @socket.on 'exports', @parseExports
    @socket.on 'execute', @onExecute
    @socket.on 'return', @onReturn

  parseExports: (exports) =>
    @locals = {}
    for k in exports
      _ = (k) =>
        __ = (args...) =>
          _id = uuid.v4()
          @promises[_id] = Q.defer()
          @socket.emit 'execute', _id, k, args
          return @promises[_id].promise
        return __
      @locals[k] = _ k
    if @io.deferredReady?
      @io.deferredReady.resolve @locals

  onExecute: (executionId, name, args) =>
    try
      console.log executionId, name, args
      v = @io.exports[name].apply(@locals, args)
    catch e
      error = {
        name: e.name
        message: e.message
        stack: e.stack
        arguments: e.arguments
      }
      @returnValue executionId, error, null
      return
    if Q.isPromise v
      v.then((v) => @returnValue executionId, null, v)
        .catch((e) =>
          error = {
            name: e.name
            message: e.message
            stack: e.stack
            arguments: e.arguments
          }
          @returnValue executionId, error, null)
        .done()
    else
      @returnValue executionId, null, v

  returnValue: (executionId, err, value) =>
    @socket.emit 'return', executionId, err, value

  onReturn: (executionId, err, value) =>
    promise = @promises[executionId]
    if err?
      promise.reject err
    else
      promise.resolve value

class PromiseIO
  constructor: (exports) ->
    @exports = exports
    @clients = {}

  constructExportsMessage: ->
    return Object.keys @exports

  onConnect: (connection) =>
    if not connection?
      connection = @io
    session = new PromiseSession @, connection
    @clients[session.id] = session

module.exports = PromiseIO
