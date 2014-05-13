# Sinapse

Ruby EventSource service for PUB/SUB delivery.

Sending messages from the server to a client should be as easy as sending
messages from the browser to the server. The technology is there (eg: pub/sub,
event loops, EventSource); a full featured Ruby solution wasn't. Hence Sinapse.

## Usage

This is still a work in progress. The library API shouldn't change much, yet
it's allowed to change and break at any time.

Please see the [example](https://github.com/ysbaddaden/sinapse/tree/master/example)
for up to date working code. To try it start the Sinapse server with `bin/sinapse`
then the example rack application. Open http://localhost:3000 in different
browsers, and start a chat!

## Features

Current state: alpha.

- Solid architecture: Goliath + EventMachine + Redis.
- EventSource (Server-Sent Events) server with support for CORS requests,
  authentication and a live updating list of channels.
- Library to manipulate user channels, authentication and to publish messages.
- Keep EventSource connection alive by sending comments are regular intervals.

Roadmap:

- Retain messages with some expiry to avoid missing messages because of
  network connection problems.
- Support [Yaffle EventSource polyfill](https://github.com/Yaffle/EventSource)
  (for Internet Explorer support)
- Support for Web Sockets alongside EventSource (for native IE10+ support)

## Author

- Julien Portalier

## License

Distributed under the MIT License.
See [LICENSE](LICENSE.m://github.com/ysbaddaden/sinapse/blob/master/LICENSE).

