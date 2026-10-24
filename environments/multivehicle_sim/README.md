# multivehicle_sim environment

ROS 2 Jazzy / Gazebo Harmonic on amd64, with standalone PX4 SITL and the pinned DAVE underlay.

Follow the [multivehicle setup guide](https://github.com/BumblebeeAS/bring-up/blob/multivehicle_sim/etc/multivehicle_sim/README.md) to import and build the workspaces.

```bash
ros2-docker use multivehicle_sim
ros2-docker build
ros2-docker start
```

After building or rebuilding `uav_description`, restart the container to update the PX4 model.

## Dashboard settings

Defaults are configured in [.bashrc](.bashrc). Override them in the shell before launching the dashboard.

| Variable | Default |
|---|---|
| `ROBOCOMMAND_HOST` | `localhost` |
| `ROBOCOMMAND_PORT` | `9000` |
| `ROBOCOMMAND_TEAM_ID` | `42` |
| `DASHBOARD_LISTEN_HOST` | `0.0.0.0` |
| `DASHBOARD_LISTEN_PORT` | `8080` |
| `DASHBOARD_ADMIN_SECRET` | `bumblebee` |

Open <http://localhost:8080>. Change the admin secret before exposing the dashboard beyond localhost.

## Workspace mounts

The host's `~/workspaces` is mounted at `/workspaces`, containing `isaac_ros-dev`, `uav_ws`, `auv_ws`, and `asv_ws`. The container starts in `/workspaces/isaac_ros-dev`.

Host caches for ccache, Torch and Matplotlib are also mounted. See [.ros_docker-config](.ros_docker-config).
