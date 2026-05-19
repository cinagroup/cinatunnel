package pogs

import (
	capnp "zombiezen.com/go/capnproto2"
	"zombiezen.com/go/capnproto2/rpc"

	"github.com/cinagroup/cinatunnel/tunnelrpc/proto"
)

type CinadServer interface {
	SessionManager
	ConfigurationManager
}

type CinadServer_PogsImpl struct {
	SessionManager_PogsImpl
	ConfigurationManager_PogsImpl
}

func CinadServer_ServerToClient(s SessionManager, c ConfigurationManager) proto.CinadServer {
	return proto.CinadServer_ServerToClient(CinadServer_PogsImpl{
		SessionManager_PogsImpl:       SessionManager_PogsImpl{s},
		ConfigurationManager_PogsImpl: ConfigurationManager_PogsImpl{c},
	})
}

type CinadServer_PogsClient struct {
	SessionManager_PogsClient
	ConfigurationManager_PogsClient
	Client capnp.Client
	Conn   *rpc.Conn
}

func NewCinadServer_PogsClient(client capnp.Client, conn *rpc.Conn) CinadServer_PogsClient {
	sessionManagerClient := SessionManager_PogsClient{
		Client: client,
		Conn:   conn,
	}
	configManagerClient := ConfigurationManager_PogsClient{
		Client: client,
		Conn:   conn,
	}
	return CinadServer_PogsClient{
		SessionManager_PogsClient:       sessionManagerClient,
		ConfigurationManager_PogsClient: configManagerClient,
		Client:                          client,
		Conn:                            conn,
	}
}

func (c CinadServer_PogsClient) Close() error {
	c.Client.Close()
	return c.Conn.Close()
}
