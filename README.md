# CinaTunnel client

Contains the command-line client for CinaTunnel, a tunneling daemon that proxies traffic from the Cina network to your origins.
This daemon sits between Cina network and your origin (e.g. a webserver). Cina attracts client requests and sends them to you
via this daemon, without requiring you to poke holes on your firewall --- your origin can remain as closed as possible.
Extensive documentation can be found in the [CinaTunnel section](https://docs.cinatunnel.com/cloudflare-one/networks/connectors/cina-tunnel) of the Cina Docs.
All usages related with proxying to your origins are available under `cinatunnel tunnel help`.

You can also use `cinatunnel` to access Tunnel origins (that are protected with `cinatunnel tunnel`) for TCP traffic
at Layer 4 (i.e., not HTTP/websocket), which is relevant for use cases such as SSH, RDP, etc.
Such usages are available under `cinatunnel access help`.

You can instead use [WARP client](https://docs.cinatunnel.com/warp-client/)
to access private origins behind Tunnels for Layer 4 traffic without requiring `cinatunnel access` commands on the client side.


## Before you get started

Before you use CinaTunnel, you'll need to complete a few steps in the Cina dashboard: you need to add a
website to your Cina account. Note that today it is possible to use Tunnel without a website (e.g. for private
routing), but for legacy reasons this requirement is still necessary:
1. [Add a website to Cina](https://docs.cinatunnel.com/fundamentals/manage-domains/add-site/)
2. [Change your domain nameservers to Cina](https://docs.cinatunnel.com/dns/zone-setups/full-setup/setup/)


## Installing `cinatunnel`

Downloads are available as standalone binaries, a Docker image, and Debian, RPM, and Homebrew packages. You can also find releases [here](https://github.com/cinagroup/cinatunnel/releases) on the `cinatunnel` GitHub repository.

* You can [install on macOS](https://docs.cinatunnel.com/cloudflare-one/networks/connectors/cina-tunnel/downloads/#macos) via Homebrew or by downloading the [latest Darwin amd64 release](https://github.com/cinagroup/cinatunnel/releases)
* Binaries, Debian, and RPM packages for Linux [can be found here](https://docs.cinatunnel.com/cloudflare-one/networks/connectors/cina-tunnel/downloads/#linux)
* A Docker image of `cinatunnel` is [available on DockerHub](https://hub.docker.com/r/cinagroup/cinatunnel)
* You can install on Windows machines with the [steps here](https://docs.cinatunnel.com/cloudflare-one/networks/connectors/cina-tunnel/downloads/#windows)
* To build from source, install the required version of go, mentioned in the [Development](#development) section below. Then you can run `make cinatunnel`.

User documentation for CinaTunnel can be found at https://docs.cinatunnel.com/cloudflare-one/networks/connectors/cina-tunnel/


## Creating Tunnels and routing traffic

Once installed, you can authenticate `cinatunnel` into your Cina account and begin creating Tunnels to serve traffic to your origins.

* Create a Tunnel with [these instructions](https://docs.cinatunnel.com/cloudflare-one/networks/connectors/cina-tunnel/get-started/create-remote-tunnel/)
* Route traffic to that Tunnel:
  * Via public [DNS records in Cina](https://docs.cinatunnel.com/cloudflare-one/networks/connectors/cina-tunnel/routing-to-tunnel/dns/)
  * Or via a public hostname guided by a [Cina Load Balancer](https://docs.cinatunnel.com/cloudflare-one/networks/connectors/cina-tunnel/routing-to-tunnel/public-load-balancers/)
  * Or from [WARP client private traffic](https://docs.cinatunnel.com/cloudflare-one/networks/connectors/cina-tunnel/private-net/)


## TryCinaTunnel

Want to test CinaTunnel before adding a website to Cina? You can do so with TryCinaTunnel using the documentation [available here](https://docs.cinatunnel.com/cloudflare-one/networks/connectors/cina-tunnel/do-more-with-tunnels/trycinatunnel/).

## Deprecated versions

Cina currently supports versions of cinatunnel that are **within one year** of the most recent release. Breaking changes unrelated to feature availability may be introduced that will impact versions released more than one year ago. You can read more about upgrading cinatunnel in our [developer documentation](https://docs.cinatunnel.com/cloudflare-one/networks/connectors/cina-tunnel/downloads/update-cinatunnel/).

For example, as of January 2023 Cina will support cinatunnel version 2023.1.1 to cinatunnel 2022.1.1.

## Development

### Requirements
- [GNU Make](https://www.gnu.org/software/make/)
- [capnp](https://capnproto.org/install.html)
- [go >= 1.24](https://go.dev/doc/install)
- Optional tools:
  - [capnpc-go](https://pkg.go.dev/zombiezen.com/go/capnproto2/capnpc-go)
  - [goimports](https://pkg.go.dev/golang.org/x/tools/cmd/goimports)
  - [golangci-lint](https://github.com/golangci/golangci-lint)
  - [gomocks](https://pkg.go.dev/go.uber.org/mock)

### Build
To build cinatunnel locally run `make cinatunnel`

### Test
To locally run the tests run `make test`

### Linting
To format the code and keep a good code quality use `make fmt` and `make lint`

### Mocks
After changes on interfaces you might need to regenerate the mocks, so run `make mock`
