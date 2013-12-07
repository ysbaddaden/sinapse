# Sinapse

Ruby EventSource service for PUB/SUB delivery.

## Goal

Sending messages from the browser to the server is easy. Sending messages from
the server to a client should be as easy. The technology is there (eg: pub/sub,
event loops, event source). A full featured Ruby solution wasn't. Hence Sinapse.

Current state: alpha.

- Initial take at the architecture (Goliath + EventMachine + Redis).

## Author

- Julien Portalier

## License

Distributed under the MIT License.
See [LICENSE](LICENSE.m://github.com/ysbaddaden/sinapse/blob/master/LICENSE).

