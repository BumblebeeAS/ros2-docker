# multivehicle_sim Environment

Docker environment for running multi-vehicle Gazebo simulations with standalone PX4 SITL.

See [bring-up/etc/multivehicle_sim/README.md](https://github.com/BumblebeeAS/bring-up) for the full simulation quickstart and usage guide.

## Image Key

```
ros2_humble.ultralytics_cuda.trt.ccache.eigen_quadprog.dave_sim.auv_sim.px4_sitl.micro_xrce_dds_agent.multivehicle_sim.install_env
```

Notable layers:

| Layer | Purpose |
|---|---|
| `px4_sitl` | Builds PX4 v1.16 SITL and extracts a minimal standalone runtime to `~/px4_sitl/` |
| `micro_xrce_dds_agent` | Builds and installs Micro XRCE-DDS Agent v2.4.3 |
| `dave_sim` | Dave underwater simulation plugins |
| `auv_sim` | AUV simulation dependencies |
| `multivehicle_sim` | Environment-specific setup (`on_entry.sh`, `.bash_aliases`, `.bashrc`) |

## on_entry.sh

Runs at container startup as the `admin` user. Sets up the PX4 Gazebo model and airframe for `uav2_description`:

1. Converts `uav2.urdf` → `model.sdf` via `gz sdf -p`
2. Places the SDF and `model.config` in `~/PX4-Autopilot/Tools/simulation/gz/models/uav2/`
3. Symlinks `5000_gz_uav2` into `~/px4_sitl/romfs/etc/init.d-posix/airframes/`

**Must be re-run after rebuilding `uav2_description`** (since the URDF → SDF conversion is done at runtime, not at image build time).

## Environment (`.bashrc`)

| Variable | Value | Purpose |
|---|---|---|
| `GZ_SIM_RESOURCE_PATH` | `…:~/PX4-Autopilot/Tools/simulation/gz/models:/workspaces/uav_ws/install/uav2_description/share` | Allows Gazebo to resolve `model://uav2_description/meshes/…` URIs from the UAV model SDF |

`uav2_description` is in `uav_ws`, which is not sourced globally. Without this entry, Gazebo (started by `sim_entrypoint`, not PX4) cannot find UAV mesh files when running the multivehicle sim.

## Aliases (`.bash_aliases`)

| Alias | Command |
|---|---|
| `px4-sitl` | Launches standalone PX4 SITL (`PX4_SYS_AUTOSTART=5000`, `PX4_GZ_STANDALONE=1`) |
| `uxrce-agent` | Starts Micro XRCE-DDS Agent on UDP port 8888 |
| `foxglove-bridge` | Starts Foxglove bridge on port 8765 |

## Mounted Directories

| Host | Container |
|---|---|
| `~/workspaces` | `/workspaces` |
| `~/.cache/ccache` | `/home/admin/.cache/ccache` |
| `~/.cache/torch` | `/home/admin/.cache/torch` |
| `~/.cache/matplotlib` | `/home/admin/.cache/matplotlib` |

The entire `~/workspaces/` directory is mounted so all colcon workspaces are accessible inside the container. The container working directory defaults to `/workspaces/isaac_ros-dev`.

Expected workspace layout on the host:

```
~/workspaces/
├── isaac_ros-dev/    # bring-up configs and repos files
├── common_ws/        # shared: dave, simulator, bb_worlds, bb_msgs, frames, vision, etc.
├── uav_ws/           # UAV-specific packages
├── auv_ws/           # AUV-specific packages
└── asv_ws/           # ASV-specific packages
```
