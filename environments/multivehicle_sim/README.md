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
| `multivehicle_sim` | Environment-specific setup (`on_entry.sh`, `.bash_aliases`) |

## on_entry.sh

Runs at container startup as the `admin` user. Sets up the PX4 Gazebo model and airframe for `uav2_description`:

1. Converts `uav2.urdf` → `model.sdf` via `gz sdf -p`
2. Places the SDF and `model.config` in `~/PX4-Autopilot/Tools/simulation/gz/models/uav2/`
3. Symlinks `5000_gz_uav2` into `~/px4_sitl/romfs/etc/init.d-posix/airframes/`

**Must be re-run after rebuilding `uav2_description`** (since the URDF → SDF conversion is done at runtime, not at image build time).

## Aliases (`.bash_aliases`)

| Alias | Command |
|---|---|
| `px4-sitl` | Launches standalone PX4 SITL (`PX4_SYS_AUTOSTART=5000`, `PX4_GZ_STANDALONE=1`) |
| `uxrce-agent` | Starts Micro XRCE-DDS Agent on UDP port 8888 |
| `foxglove-bridge` | Starts Foxglove bridge on port 8765 |

## Mounted Directories

| Host | Container |
|---|---|
| `~/workspaces/isaac_ros-dev` | `/workspaces/isaac_ros-dev` |
| `~/.cache/ccache` | `/home/admin/.cache/ccache` |
| `~/.cache/torch` | `/home/admin/.cache/torch` |
| `~/.cache/matplotlib` | `/home/admin/.cache/matplotlib` |
