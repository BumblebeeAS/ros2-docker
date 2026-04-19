# multivehicle_sim environment

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
| `multivehicle_sim` | Environment-specific setup (`on_entry.sh`, `.bash_aliases`, `.bashrc`) + `bb_robotx_dashboard` pip deps (`fastapi`, `uvicorn[standard]`, `pydantic-settings`) installed in `Dockerfile.multivehicle_sim` |

## on_entry.sh

Runs at container startup as the `admin` user. Sets up the PX4 Gazebo model and airframe for `uav2_description`:

1. Converts `uav2.urdf` → `model.sdf` via `gz sdf -p`
2. Places the SDF and `model.config` in `~/PX4-Autopilot/Tools/simulation/gz/models/uav2/`
3. Symlinks `5000_gz_uav2` into `~/px4_sitl/romfs/etc/init.d-posix/airframes/`

**Must be re-run after rebuilding `uav2_description`** (since the URDF → SDF conversion is done at runtime, not at image build time).

If `/workspaces/common_ws/src/bb_robotx_dashboard` is checked out, the script
also bootstraps the dashboard's protobuf bindings (idempotent, each step
wrapped in `|| true`):

4. `git clone MonkeScripts/robocommand → third_party/robocommand` (upstream `.proto` sources)
5. `scripts/fetch_protoc.sh` (downloads protoc 33 into `third_party/protoc/`; needs `unzip`)
6. `scripts/compile_protos.sh` (writes `bb_robotx_dashboard/proto/*_pb2.py`)

## Environment (`.bashrc`)

`Dockerfile.install_env` appends this file into `/home/admin/.bashrc` and `/root/.bashrc` at image build time, so every interactive shell — including tmux panes spawned by tmuxp — picks up these exports.

| Variable | Value | Purpose |
|---|---|---|
| `GZ_SIM_RESOURCE_PATH` | `…:~/PX4-Autopilot/Tools/simulation/gz/models` | Allows Gazebo to resolve `model://uav2_description/meshes/…` URIs from the UAV model SDF. `uav2_description` is in `uav_ws`, which is not sourced globally. |
| `ROBOCOMMAND_HOST` | `localhost` | Host of the RoboCommand TCP server that `bb_robotx_dashboard` connects to. Override per-pane to target a real vehicle. |
| `ROBOCOMMAND_PORT` | `9000` | RoboCommand TCP port. |
| `ROBOCOMMAND_TEAM_ID` | `42` | Team identifier sent on the RoboCommand handshake. |
| `DASHBOARD_LISTEN_HOST` | `0.0.0.0` | Bind address for the FastAPI web backend. |
| `DASHBOARD_LISTEN_PORT` | `8080` | Browser hits this. |
| `DASHBOARD_ADMIN_SECRET` | `bumblebee` | Bearer secret for `/api/led` and `/api/incident`. Rotate before exposing beyond localhost; changes require an image rebuild. |

The `DASHBOARD_*` / `ROBOCOMMAND_*` block lives here (rather than in `on_entry.sh`) because `on_entry.sh` is sourced once into the initial shell, and anything started by a pre-existing tmux server would miss the exports. Baking them into `~/.bashrc` means every shell gets them unconditionally, regardless of tmux state.

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
## Implementation details

## Key Differences from `uav2_sim`

| | `uav2_sim` | `multivehicle_sim` |
|---|---|---|
| PX4 launch | `make px4_sitl gz_uav2` (full PX4-Autopilot) | `px4-sitl` alias (standalone binary) |
| Gazebo launch | PX4 starts Gazebo | `gz sim` runs separately |
| Micro XRCE-DDS Agent | Built into Docker layer | Docker layer (`micro_xrce_dds_agent`) |
| Airframe registration | `PX4-Autopilot/ROMFS/…/airframes/` + CMakeLists edit | `~/px4_sitl/romfs/etc/init.d-posix/airframes/` (no recompile) |
| Workspace mount | `~/workspaces/isaac_ros-dev` | `~/workspaces` (all vehicle workspaces) |

## Potential problems

### Unclean .bashrc
Because of PX4, I had to add the directory path to GZ_SIM_RESOURCE_PATH in .bashrc as follows: 
```bash
GZ_SIM_RESOURCE_PATH=…:~/PX4-Autopilot/Tools/simulation/gz/models
```
There are definitely better ways out there. 

### PX4 SITL 
The px4_sitl layer is built up on several patches on the exisiting PX4-Autopilot 1.16.0 release. 
One is from: https://github.com/Dronecode/roscon-25-workshop/blob/main/docker/scripts/build_px4.sh
Other is from: https://github.com/PX4/PX4-Autopilot/issues/25859#issuecomment-3976481685

Things might changes over time. 

Also there are some dependency management fixes we did with protobuf to make it compatible to dave and also the PX4 build. Take care.
