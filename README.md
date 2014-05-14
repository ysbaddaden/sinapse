# Sinapse

EventSource service for pushing messages written in Ruby.

Pushing messages to the browser or any other kind or client should be as easy as
posting from a browser. The technology is there with the PUB/SUB solution
offered by Redis and the simple server push protocol allowed by EventSource
(Server-Sent Events) over regular HTTP.

Sinapse is a push service running in an event-loop (thanks to Goliath and
EventMachine) and takes care of pushing all your events, and to deliver them to
whoever is allowed to receive them.


## How it works

A user connects to the Sinapse server using a token. That token will be
associated to a list of channels that the user is authorized to listen to. That
list of channels can be updated at any time and will be applied live to existing
connection, so users will only ever receive what they are allowed to receive.

This is different from [Faye](http://faye.jcoglan.com) for example, which is
a PUB/SUB solution to have clients subscribe and publish to whatever channels
they want. Sinapse is a push service to notify clients about changes that
happened on the backend, and the list of authorized channels is thus kept on
the server.


## Features

Sinapse is still a work in progress, and the API subject to changes, but it
already features:

- A solid architecture (Goliath + EventMachine + Redis).
- EventSource (Server-Sent Events) server with support for CORS requests,
  authentication and a live updating list of channels.
- Keep EventSource connection alive by sending comments are regular intervals.
- Ruby library to manipulate user channels, authentication and to publish
  messages.

TODO:

- Support [Yaffle EventSource polyfill](https://github.com/Yaffle/EventSource)
  (for Internet Explorer support)
- Support for Web Sockets alongside EventSource (for native IE10+ support)
- Retain messages with some expiry to avoid missing messages because of
  network connection problems.


## Requirements

Sinapse is compatible and actively tested with Ruby 1.9.3+ and Rubinius 2.2+. It
requires a Redis 2.2+ server instance. Sinapse should be compatible with Ubuntu
12.04 LTS out of the box. It may be compatible with older versions of Ruby,
Rubinius or Redis but this isn't supported.

Sinapse comes with a Ruby library, but it can be used from other languages,
because all the communication to the Sinapse server happens through Redis. The
protocol hasn't been formalized yet and you will have to check the ruby
implementation and test suite to understand it.


## Usage

Declare sinapse in your Gemfile and run `bundle`:

```ruby
gem "sinapse", github: "ysbaddaden/sinapse"
```

You may now start the server with `bundle exec sinapse` or generate a binstub
with `bundle binstubs sinapse` then start the server with `bin/sinapse`.

Once started the server will be available on http://0.0.0.0:9000/ by default.
It can be configured to run on a UNIX socket or a specific host and port. Run
`sinapse --help` or read the Goliath documentation for more information.

### Configuration

The Sinapse server may be configured using environment variables:

  - `SINAPSE_CORS_ORIGIN` — restrict origins for CORS browser requests (defaults to `*`).
  - `SINAPSE_KEEP_ALIVE` — send a comment every n seconds to keep the connection alive (defaults to `15`).
  - `SINAPSE_RETRY` — EventSource retry parameter (defaults to `5`).
  - `SINAPSE_CHANNEL_EVENT` — set the channel name as the event type to sent messages.

Sinapse (both the client and the server) will connect to the Redis instance
defined in the `REDIS_URL` environment variable and fallback to the default
`redis://localhost:6379:0`.

### Authenticate

Include `Sinapse` into the subjects that will authenticate to the Sinapse
server. The example below uses ActiveRecord but Sinapse should work with any
Ruby class, as long as it responds to `#to_param`.

```ruby
class User < ActiveRecord::Base
  include Sinapse
end
```

Once your subjects are defined, you must generate tokens for the subjects, then
declare a list of channels they are authorized to access. You are responsible
for generating and replacing the token when your application requires it. For
example you may create the token when creating the user:

```ruby
class User < ActiveRecord::Base
  include Sinapse
end

# create the token and initialize channels
user = User.create(attributes)
token = user.sinapse.auth.generate

# destroy the token and the user channels
sinapse.auth.clear
```

You may now connect to `http://localhost:9000/?access_token=<token>` but it
will return a `401 Unauthorized` because the connected subject doesn't have any
channel to listen to.

A 401 Unauthorized HTTP status will be returned whenever an `access_token` is
invalid or the list of channels is empty. The connection may also be closed
immediately whenever the list of channels gets emptied.

### Channels

You may now add and remove the channels that a user may be notified of at any
time. Usually a channel will be a class instance. Include `Sinapse::Publishable`
into the classes that may publish events, add them to the authorized channels of
a user, then publish your messages through the class:

```ruby
class Room < ActiveRecord::Base
  include Sinapse::Publishable
end

# add the channel to a user's channel list
room = Room.find(params[:id])
user.sinapse.add_channel(room)

# publish a message (the user will receive it)
room.publish(room.to_json)

# remove the channel
user.sinapse.remove_channel(room)

# publish another message (the user won't receive it)
room.publish(room.to_json)
```


## Example

Please see the [example](https://github.com/ysbaddaden/sinapse/tree/master/example)
for up to date working code. To try it start the Sinapse server with `bin/sinapse`
then the example rack application. Open http://localhost:3000 in different
browsers, and start a chat!


## Author

- Julien Portalier


## License

Distributed under the MIT License.
See [LICENSE](LICENSE.m://github.com/ysbaddaden/sinapse/blob/master/LICENSE).

