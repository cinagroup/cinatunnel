package quic

import (
	"context"
	"fmt"
	"io"
	"time"

	"github.com/cinagroup/cinatunnel/tunnelrpc"
	"github.com/cinagroup/cinatunnel/tunnelrpc/pogs"
)

// HandleRequestFunc wraps the proxied request from the upstream and also provides methods on the stream to
// handle the response back.
type HandleRequestFunc = func(ctx context.Context, stream *RequestServerStream) error

// CinadServer provides a handler interface for a client to provide methods to handle the different types of
// requests that can be communicated by the stream.
type CinadServer struct {
	handleRequest   HandleRequestFunc
	sessionManager  pogs.SessionManager
	configManager   pogs.ConfigurationManager
	responseTimeout time.Duration
}

func NewCinadServer(handleRequest HandleRequestFunc, sessionManager pogs.SessionManager, configManager pogs.ConfigurationManager, responseTimeout time.Duration) *CinadServer {
	return &CinadServer{
		handleRequest:   handleRequest,
		sessionManager:  sessionManager,
		configManager:   configManager,
		responseTimeout: responseTimeout,
	}
}

// Serve executes the defined handlers in ServerStream on the provided stream if it is a proper RPC stream with the
// correct preamble protocol signature.
func (s *CinadServer) Serve(ctx context.Context, stream io.ReadWriteCloser) error {
	signature, err := determineProtocol(stream)
	if err != nil {
		return err
	}
	switch signature {
	case dataStreamProtocolSignature:
		return s.handleRequest(ctx, &RequestServerStream{stream})
	case rpcStreamProtocolSignature:
		return s.handleRPC(ctx, stream)
	default:
		return fmt.Errorf("unknown protocol %v", signature)
	}
}

func (s *CinadServer) handleRPC(ctx context.Context, stream io.ReadWriteCloser) error {
	ctx, cancel := context.WithTimeout(ctx, s.responseTimeout)
	defer cancel()
	transport := tunnelrpc.SafeTransport(stream)
	defer transport.Close()

	main := pogs.CinadServer_ServerToClient(s.sessionManager, s.configManager)
	rpcConn := tunnelrpc.NewServerConn(transport, main.Client)
	defer rpcConn.Close()

	// We ignore the errors here because if cinatunnel fails to handle a request, we will just move on.
	select {
	case <-rpcConn.Done():
	case <-ctx.Done():
	}
	return nil
}
