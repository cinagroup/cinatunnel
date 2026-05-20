//go:build linux

package ingress

import (
	"testing"

	"github.com/cinagroup/cinatunnel/packet"
)

func getFunnel(t *testing.T, proxy *icmpProxy, tuple flow3Tuple) (packet.Funnel, bool) {
	return proxy.srcFunnelTracker.Get(tuple)
}
