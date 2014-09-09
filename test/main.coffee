PromiseIOServer = require '../src/server'
PromiseIOClient = require '../src/client'
Q = require 'q'

chai = require 'chai'
chai.use require('chai-as-promised')

should = chai.should()
expect = chai.expect

class TestError extends Error
  @constructor: (value) ->
    @message = 'I hate this value: "' + value

describe 'PromiseIO', ->
  server = new PromiseIOServer {
    'working': (value, v2) ->
      return "I got " + value
    'erroring': (value) ->
      throw new TestError value
    'promisedWorking': (value) ->
      deferred = Q.defer()
      deferred.resolve "I got " + value
      return deferred
    'promisedErrornig': (value) ->
      deferred = Q.defer()
      deferred.reject new TestError value
      return deferred
  }

  server.listen 3000

  it 'should execute functions properly', ->
    client = new PromiseIOClient {}
    client.connect 'http://localhost:3000'
    .then (remote) ->
      remote.working 'roflmao'
        .should.eventually.equal 'I got roflmao'
