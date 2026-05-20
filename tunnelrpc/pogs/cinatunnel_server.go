package pogs

import (
	capnp "zombiezen.com/go/capnproto2"
	"zombiezen.com/go/capnproto2/rpc"

	"github.com/cinagroup/cinatunnel/tunnelrpc/proto"
)

type CinatunnelServer interface {
	SessionManager
	ConfigurationManager
}

type CinatunnelServer_PogsImpl struct {
	SessionManager_PogsImpl
	ConfigurationManager_PogsImpl
}

func CinatunnelServer_ServerToClient(s SessionManager, c ConfigurationManager) proto.CinatunnelServer {
	return proto.CinatunnelServer_ServerToClient(CinatunnelServer_PogsImpl{
		SessionManager_PogsImpl:       SessionManager_PogsImpl{s},
		ConfigurationManager_PogsImpl: ConfigurationManager_PogsImpl{c},
	})
}

type CinatunnelServer_PogsClient struct {
	SessionManager_PogsClient
	ConfigurationManager_PogsClient
	Client capnp.Client
	Conn   *rpc.Conn
}

func NewCinatunnelServer_PogsClient(client capnp.Client, conn *rpc.Conn) CinatunnelServer_PogsClient {
	sessionManagerClient := SessionManager_PogsClient{
		Client: client,
		Conn:   conn,
	}
	configManagerClient := ConfigurationManager_PogsClient{
		Client: client,
		Conn:   conn,
	}
	return CinatunnelServer_PogsClient{
		SessionManager_PogsClient:       sessionManagerClient,
		ConfigurationManager_PogsClient: configManagerClient,
		Client:                          client,
		Conn:                            conn,
	}
}

func (c CinatunnelServer_PogsClient) Close() error {
	c.Client.Close()
	return c.Conn.Close()
}
