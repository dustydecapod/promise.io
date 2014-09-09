Fancy RPC library using socket.io and promises!

[![Circle CI](https://circleci.com/gh/krillr/promise.io.png?style=badge)](https://circleci.com/gh/krillr/promise.io)

Why Promises?
======
Promises let you do really cool things, like not have to live in callback hell all your life. You can also set timeouts on your RPC calls! And in a future version, you'll be able to use the standard .notify() promise functions to get progress notifications from the remote, in the same way you would with local promises.

Design Decisions
======

CoffeeScript
------
Promise.IO is written in CoffeeScript, and as such its API is geared towards usage in CoffeeScript. Where possible, helper utilities are provided to make it easier for pure JavaScript usage -- but keep in mind that pure JavaScript is treated as a second-class citizen in Sonrai. 

Promises
------
Promise.IO makes gratuitous use of Promises, because let's face it -- callbacks suck. In particular, the lightweight and efficient Q library is used. All async calls will return promises. Please code accordingly!

CoffeeScript Server Example
======
```CoffeeScript
server = new PromiseIO {
  someFunc: (input) ->
    return 'I got: ' + input
}

server.listen 3000
```

CoffeeScript Client Example
======
```CoffeeScript
client = new PromiseIO

client.connect 'http://localhost:3000'
  .then (remote) ->    remote.someFunc 'my variable!'
      .then (returnVal) -> console.log returnVal
      .catch (err) -> console.log err
```
