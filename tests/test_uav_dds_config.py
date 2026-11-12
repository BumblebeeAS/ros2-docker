"""Source the UAV config with real Bash; no Docker or ROS installation required."""
import os
from pathlib import Path
import subprocess
import unittest

CONFIG = Path(__file__).resolve().parents[1] / "environments/uav/.ros_docker-config"
NEW = "FASTDDS_DEFAULT_PROFILES_FILE"
OLD = "FASTRTPS_DEFAULT_PROFILES_FILE"
DEFAULT = "/etc/ros/dds/fastdds_local.xml"


class UAVDDSConfigTest(unittest.TestCase):
    def test_profile_selection_is_identical_for_fastdds_2_and_3(self):
        for overrides, expected in (
                ({}, DEFAULT),
                ({NEW: "/tmp/new.xml"}, "/tmp/new.xml"),
                ({OLD: "/tmp/old.xml"}, "/tmp/old.xml"),
                ({NEW: "/tmp/new.xml", OLD: "/tmp/old.xml"}, "/tmp/new.xml"),
                ({NEW: "", OLD: "/tmp/old.xml"}, "/tmp/old.xml"),
                ({NEW: "", OLD: ""}, DEFAULT)):
            with self.subTest(overrides=overrides):
                environment = {key: value for key, value in os.environ.items()
                               if key not in (NEW, OLD, "RMW_IMPLEMENTATION")}
                environment.update(overrides)
                environment["ROS_DOMAIN_ID"] = "99"
                result = subprocess.run(
                    ["bash", "-euc",
                     'ISAAC_ROS_DOCKER_ARGS=(); source "$1"; '
                     'printf "%s\\n" "$CONFIG_ROS_DOMAIN_ID" "${ISAAC_ROS_DOCKER_ARGS[@]}"',
                     "bash", str(CONFIG)],
                    env=environment, capture_output=True, text=True, check=True)
                domain, *arguments = result.stdout.splitlines()
                self.assertEqual(domain, "38")
                self.assertIn(f"{NEW}={expected}", arguments)
                self.assertIn(f"{OLD}={expected}", arguments)
                self.assertIn("RMW_IMPLEMENTATION=rmw_fastrtps_cpp", arguments)


if __name__ == "__main__":
    unittest.main()
