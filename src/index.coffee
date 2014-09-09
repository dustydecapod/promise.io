Q = require 'q'

uuid = ->
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) ->
    r = Math.random()*16|0
    v = if c == 'x' then r else (r&0x3|0x8)
    return v.toString(16)
  )

class PromiseSession
  constructor: (@io, @socket) ->
    @id = uuid()
    @promises = {}
    @socket.emit 'exports', @io.constructExportsMessage()
    @socket.on 'exports', @parseExports
    @socket.on 'execute', @onExecute
    @socket.on 'return', @onReturn
    @socket.on 'notify', @onNotify

  parseExports: (exports) =>
    @locals = {}
    for k in exports
      _ = (k) =>
        __ = (args...) =>
          _id = uuid()
          @promises[_id] = Q.defer()
          @socket.emit 'execute', _id, k, args
          return @promises[_id].promise
        return __
      @locals[k] = _ k
    if @io.deferredReady?
      @io.deferredReady.resolve @locals

  onExecute: (executionId, name, args) =>
    ctx = (session, executionId) ->
      return {
        notify: (value) =>
          session.notify executionId, value
        remote: session.locals
      }
    try
      v = @io.exports[name].apply(ctx(@, executionId), args)
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
      v.then (v) => @returnValue executionId, null, v
        .catch (e) =>
          error = {
            name: e.name
            message: e.message
            stack: e.stack
            arguments: e.arguments
          }
          @returnValue executionId, error, null
        .progress (v) => @notify executionId, v
        .done()
    else
      @returnValue executionId, null, v

  notify: (executionId, value) ->
    @socket.emit 'notify', executionId, value

  onNotify: (executionId, value) =>
    promise = @promises[executionId]
    promise.notify value

  returnValue: (executionId, err, value) =>
    if value == @socket
      value = null
    if err?
      error = new Error
      error.message = err.message
      error.name = err.name
      error.arguments = err.arguments
      error.stack = err.stack
    @socket.emit 'return', executionId, error, value

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
    if @exports?
      return Object.keys @exports
    return []

  onConnect: (connection) =>
    if not connection?
      connection = @io
    session = new PromiseSession @, connection
    @clients[session.id] = session

module.exports = PromiseIO
