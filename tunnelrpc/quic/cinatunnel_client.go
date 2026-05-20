package quic

import (
	"context"
	"fmt"
	"io"
	"net"
	"time"

	"zombiezen.com/go/capnproto2/rpc"

	"github.com/google/uuid"

	"github.com/cinagroup/cinatunnel/tunnelrpc"
	"github.com/cinagroup/cinatunnel/tunnelrpc/metrics"
	"github.com/cinagroup/cinatunnel/tunnelrpc/pogs"
)

// CinatunnelClient calls capnp rpc methods of SessionManager and ConfigurationManager.
type CinatunnelClient struct {
	client         pogs.CinatunnelServer_PogsClient
	transport      rpc.Transport
	requestTimeout time.Duration
}

func NewCinatunnelClient(ctx context.Context, stream io.ReadWriteCloser, requestTimeout time.Duration) (*CinatunnelClient, error) {
	n, err := stream.Write(rpcStreamProtocolSignature[:])
	if err != nil {
		return nil, err
	}
	if n != len(rpcStreamProtocolSignature) {
		return nil, fmt.Errorf("expect to write %d bytes for RPC stream protocol signature, wrote %d", len(rpcStreamProtocolSignature), n)
	}
	transport := tunnelrpc.SafeTransport(stream)
	conn := tunnelrpc.NewClientConn(transport)
	client := pogs.NewCinatunnelServer_PogsClient(conn.Bootstrap(ctx), conn)
	return &CinatunnelClient{
		client:         client,
		transport:      transport,
		requestTimeout: requestTimeout,
	}, nil
}

func (c *CinatunnelClient) RegisterUdpSession(ctx context.Context, sessionID uuid.UUID, dstIP net.IP, dstPort uint16, closeIdleAfterHint time.Duration, traceContext string) (*pogs.RegisterUdpSessionResponse, error) {
	ctx, cancel := context.WithTimeout(ctx, c.requestTimeout)
	defer cancel()
	defer metrics.CapnpMetrics.ClientOperations.WithLabelValues(metrics.Cinatunnel, metrics.OperationRegisterUdpSession).Inc()
	timer := metrics.NewClientOperationLatencyObserver(metrics.Cinatunnel, metrics.OperationRegisterUdpSession)
	defer timer.ObserveDuration()

	resp, err := c.client.RegisterUdpSession(ctx, sessionID, dstIP, dstPort, closeIdleAfterHint, traceContext)
	if err != nil {
		metrics.CapnpMetrics.ClientFailures.WithLabelValues(metrics.Cinatunnel, metrics.OperationRegisterUdpSession).Inc()
	}
	return resp, err
}

func (c *CinatunnelClient) UnregisterUdpSession(ctx context.Context, sessionID uuid.UUID, message string) error {
	ctx, cancel := context.WithTimeout(ctx, c.requestTimeout)
	defer cancel()
	defer metrics.CapnpMetrics.ClientOperations.WithLabelValues(metrics.Cinatunnel, metrics.OperationUnregisterUdpSession).Inc()
	timer := metrics.NewClientOperationLatencyObserver(metrics.Cinatunnel, metrics.OperationUnregisterUdpSession)
	defer timer.ObserveDuration()

	err := c.client.UnregisterUdpSession(ctx, sessionID, message)
	if err != nil {
		metrics.CapnpMetrics.ClientFailures.WithLabelValues(metrics.Cinatunnel, metrics.OperationUnregisterUdpSession).Inc()
	}
	return err
}

func (c *CinatunnelClient) UpdateConfiguration(ctx context.Context, version int32, config []byte) (*pogs.UpdateConfigurationResponse, error) {
	ctx, cancel := context.WithTimeout(ctx, c.requestTimeout)
	defer cancel()
	defer metrics.CapnpMetrics.ClientOperations.WithLabelValues(metrics.Cinatunnel, metrics.OperationUpdateConfiguration).Inc()
	timer := metrics.NewClientOperationLatencyObserver(metrics.Cinatunnel, metrics.OperationUpdateConfiguration)
	defer timer.ObserveDuration()

	resp, err := c.client.UpdateConfiguration(ctx, version, config)
	if err != nil {
		metrics.CapnpMetrics.ClientFailures.WithLabelValues(metrics.Cinatunnel, metrics.OperationUpdateConfiguration).Inc()
	}
	return resp, err
}

func (c *CinatunnelClient) Close() {
	_ = c.client.Close()
	_ = c.transport.Close()
}
