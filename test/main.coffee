PromiseIO = require '../src/promise.io'
Q = require 'q'

chai = require 'chai'
chai.use require('chai-as-promised')

should = chai.should()
expect = chai.expect

class TestError extends Error
  @constructor: (value) ->
    @message = 'I hate this value: "' + value

describe 'PromiseIO', ->
  before =>
    @server = new PromiseIO {
      working: (value, v2) ->
        return "I got " + value
      erroring: (value) ->
        throw new TestError value
      promisedWorking: (value) ->
        deferred = Q.defer()
        deferred.resolve "I got " + value
        return deferred.promise
      promisedErroring: (value) ->
        deferred = Q.defer()
        deferred.reject new TestError value
        return deferred.promise
      callTheClient: (value) ->
        return @remote.clientCall value
      notifyingCall: ->
        @notify 0
        @notify 1
        @notify 2
        return
      promisedNotifyingCall: ->
        deferred = Q.defer()
        i = 0
        _ = =>
          i += 1
          deferred.notify i
          if i <= 3
            setTimeout(_, 100)
        setTimeout(_, 100)
        return deferred.promise
    }

    @server.listen 3000

    @client = new PromiseIO {
      clientCall: (value) ->
        return "And I got: " + value
    }
    @client.connect 'http://localhost:3000'
      .then (@remote) =>

  it 'should execute functions properly', =>
    @remote.working 'roflmao'
      .should.eventually.equal 'I got roflmao'

  it 'should reject the promise when an error arises', =>
    return @remote.erroring 'roflmao'
      .should.be.rejected

  it 'should execute functions properly when the function returns a promise', =>
    @remote.promisedWorking 'roflmao'
      .should.eventually.equal 'I got roflmao'

  it 'should reject the promise when an error arises and the function returns a promise', =>
    return @remote.promisedErroring 'roflmao'
      .should.be.rejected

  it 'should allow the server to call client methods from within server methods', =>
    @remote.callTheClient 'toejam'
      .should.eventually.equal "And I got: toejam"

  it 'should pass notifications from calls forward', (done) =>
    @remote.notifyingCall().progress (v) ->
      if v == 2
        done()

  it 'should pass notifications from calls forward', (done) =>
      @remote.promisedNotifyingCall().progress (v) =>
        if v == 2
          done()

  it 'should allow exports to be updated on the fly', (done) =>
    @server.exports.newFunc = (input) ->
      return "Hey! I'm new here! " + input
    @server.sendExports().then =>
      @remote.newFunc 'fancyInput'
        .should.eventually.equal "Hey! I'm new here! fancyInput"
        .should.notify done
