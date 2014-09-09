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
  before =>
    @server = new PromiseIOServer {
      'working': (value, v2) ->
        return "I got " + value
      'erroring': (value) ->
        throw new TestError value
      'promisedWorking': (value) ->
        deferred = Q.defer()
        deferred.resolve "I got " + value
        return deferred.promise
      'promisedErroring': (value) ->
        deferred = Q.defer()
        deferred.reject new TestError value
        return deferred.promise
      'callTheClient': (value) ->
        return @clientCall value
    }

    @server.listen 3000

    @client = new PromiseIOClient {
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
