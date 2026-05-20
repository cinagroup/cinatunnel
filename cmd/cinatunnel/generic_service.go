//go:build !windows && !darwin && !linux

package main

import (
	"fmt"
	"os"

	cli "github.com/urfave/cli/v2"

	"github.com/cinagroup/cinatunnel/cmd/cinatunnel/cliutil"
)

func runApp(app *cli.App, graceShutdownC chan struct{}) {
	app.Commands = append(app.Commands, &cli.Command{
		Name:  "service",
		Usage: "Manages the cinatunnel system service (not supported on this operating system)",
		Subcommands: []*cli.Command{
			{
				Name:   "install",
				Usage:  "Install cinatunnel as a system service (not supported on this operating system)",
				Action: cliutil.ConfiguredAction(installGenericService),
			},
			{
				Name:   "uninstall",
				Usage:  "Uninstall the cinatunnel service (not supported on this operating system)",
				Action: cliutil.ConfiguredAction(uninstallGenericService),
			},
		},
	})
	app.Run(os.Args)
}

func installGenericService(c *cli.Context) error {
	return fmt.Errorf("service installation is not supported on this operating system")
}

func uninstallGenericService(c *cli.Context) error {
	return fmt.Errorf("service uninstallation is not supported on this operating system")
}
