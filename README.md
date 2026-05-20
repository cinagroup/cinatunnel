# Cinatunnel

Cina's command-line tool and networking daemon written in Go.

Contains the command-line client for CinaTunnel, a tunneling daemon that proxies traffic from the Cina network to your origins.
This daemon sits between the Cina network and your origin (e.g. a webserver). Cina attracts client requests and sends them to you
via this daemon, without requiring you to poke holes on your firewall — your origin can remain as closed as possible.

You can also use `cinatunnel` to access Tunnel origins (that are protected with `cinatunnel tunnel`) for TCP traffic
at Layer 4 (i.e., not HTTP/websocket), which is relevant for use cases such as SSH, RDP, etc.

## Installation

Downloads are available as standalone binaries, a Docker image, and Debian, RPM, and Homebrew packages.
You can find releases [here](https://github.com/cinagroup/cinatunnel/releases).

- **macOS:** via Homebrew or by downloading the latest Darwin amd64 release
- **Linux:** Binaries, Debian, and RPM packages available on the [releases page](https://github.com/cinagroup/cinatunnel/releases)
- **Docker:** `docker pull cinagroup/cinatunnel`
- **Windows:** Download the latest release binary

## Building from Source

### Requirements

- [GNU Make](https://www.gnu.org/software/make/)
- [capnp](https://capnproto.org/install.html)
- [go >= 1.24](https://go.dev/doc/install)
- Optional tools:
  - [capnpc-go](https://pkg.go.dev/zombiezen.com/go/capnproto2/capnpc-go)
  - [goimports](https://pkg.go.dev/golang.org/x/tools/cmd/goimports)
  - [golangci-lint](https://github.com/golangci/golangci-lint)
  - [gomocks](https://pkg.go.dev/go.uber.org/mock)

### Build Commands

```bash
# Build cinatunnel
make cinatunnel

# Run tests
make test

# Format code
make fmt && make lint

# Regenerate mocks after interface changes
make mock
```

## Usage

```bash
# Create a tunnel
cinatunnel tunnel create

# Run a tunnel
cinatunnel tunnel run
```

## Version Support

Cina supports versions of cinatunnel that are within one year of the most recent release.

## License

Apache License Version 2.0
