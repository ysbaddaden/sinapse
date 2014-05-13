# Sinapse

Ruby EventSource service for PUB/SUB delivery.

Sending messages from the server to a client should be as easy as sending
messages from the browser to the server. The technology is there (eg: pub/sub,
event loops, EventSource); a full featured Ruby solution wasn't. Hence Sinapse.

This is still a work in progress. The library API shouldn't change much, yet
it's allowed to change and break at any time.


## Features

Sinapse is currently in alpha state, but already provides a nice set of
features:

- Solid architecture: Goliath + EventMachine + Redis.
- EventSource (Server-Sent Events) server with support for CORS requests,
  authentication and a live updating list of channels.
- Ruby library to manipulate user channels, authentication and to publish
  messages.
- Keep EventSource connection alive by sending comments are regular intervals.

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
  - `SINAPSE_RETRY` — EventSource retry parameter (defaults to `5`)

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

