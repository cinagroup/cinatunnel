#!/usr/bin/env python
import copy
import platform
from time import sleep

import pytest
from flaky import flaky

from conftest import CfdModes
from constants import protocols
from util import start_cinatunnel, wait_tunnel_ready, check_tunnel_not_connected


@flaky(max_runs=3, min_passes=1)
class TestReconnect:
    default_ha_conns = 1
    default_reconnect_secs = 15
    extra_config = {
        "stdin-control": True,
    }

    def _extra_config(self, protocol):
        return {
            "stdin-control": True,
            "protocol": protocol,
        }

    @pytest.mark.skipif(platform.system() == "Windows", reason=f"Currently buggy on Windows TUN-4584")
    @pytest.mark.parametrize("protocol", protocols())
    def test_named_reconnect(self, tmp_path, component_tests_config, protocol):
        config = component_tests_config(self._extra_config(protocol))
        with start_cinatunnel(tmp_path, config, cfd_pre_args=["tunnel", "--ha-connections", "1"], new_process=True, allow_input=True, capture_output=False) as cinatunnel:
            # Repeat the test multiple times because some issues only occur after multiple reconnects
            self.assert_reconnect(config, cinatunnel, 5)

    def send_reconnect(self, cinatunnel, secs):
        # Although it is recommended to use the Popen.communicate method, we cannot
        # use it because it blocks on reading stdout and stderr until EOF is reached
        cinatunnel.stdin.write(f"reconnect {secs}s\n".encode())
        cinatunnel.stdin.flush()

    def assert_reconnect(self, config, cinatunnel, repeat):
        wait_tunnel_ready(tunnel_url=config.get_url(),
                          require_min_connections=self.default_ha_conns)
        for _ in range(repeat):
            for _ in range(self.default_ha_conns):
                self.send_reconnect(cinatunnel, self.default_reconnect_secs)
            check_tunnel_not_connected()
            sleep(self.default_reconnect_secs * 2)
            wait_tunnel_ready(tunnel_url=config.get_url(),
                              require_min_connections=self.default_ha_conns)
