# ROS 2 Docker <!-- omit from toc -->

A set of scripts to ease development with layered ROS 2 Docker containers, including [Isaac ROS](https://nvidia-isaac-ros.github.io/).

- [Available Environments](#available-environments)
- [Sample Hardware and OS Requirements](#sample-hardware-and-os-requirements)
- [Installation](#installation)
  - [Installation on Jetson](#installation-on-jetson)
  - [Installation on x86\_64](#installation-on-x86_64)
- [Build a ROS 2 Docker Image](#build-a-ros-2-docker-image)
- [Production](#production)
- [ROS Dependencies](#ros-dependencies)
- [Notes](#notes)
  - [TODO](#todo)
  - [Issues](#issues)

## Available Environments

All environments use a common runtime setup (`dockerfiles/environments/Dockerfile.install_env`):

- Base tooling: `tmux`, `tmuxp`, `colcon-clean`, `foxglove-bridge`, `speedtest-cli`
- Per-environment shell setup: `.bashrc`, `.bash_aliases`, `on_entry.sh`
- Per-environment ROS dependencies: `rosdep-apt.list`, `rosdep-pip.list`
- Environment-defined workspace and cache mounts

The Isaac ROS environments come with a GPU-accelerated vision stack utilizing TensorRT optimized for edge inference on Jetsons.

Environment-specific differences come from the `CONFIG_IMAGE_KEY` chain in each `.ros_docker-config`.

We deploy on three types of vehicles:

- Autonomous Surface Vehicle (ASVs)
- Autonomous Underwater Vehicles (AUVs)
- Unmanned Aerial Vehicles (UAVs)

| Environment | Primary use                                                                             | Unique features                                                        |
| ----------- | --------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| `asv`       | ASV software stack on Jetson                                                            | Spinnaker support for cameras, `eigen-quadprog`, `pcl`, `rtcm`, `nmea` |
| `auv`       | AUV software stack on Jetson                                                            |                                                                        |
| `auv_sim`   | AUV simulation with [DAVE Sim](https://field-robotics-lab.github.io/dave.doc/) + Gazebo |                                                                        |
| `uav2`      | UAV software stack on Jetson                                                            | PX4 DDS bridge support via Micro XRCE-DDS Agent, Argus camera support  |
| `uav2_sim`  | UAV simulation with PX4 + Gazebo                                                        | PX4 Autopilot SITL + Gazebo, MAVSDK tooling                            |
| `bluerov_ws` | BlueROV simulation demos from [BumblebeeAS/examples](https://github.com/BumblebeeAS/examples) | Standard ROS Jazzy image, ArduSub/Gazebo base, CUDA perception stack  |

Tip: start from the nearest environment and tune `rosdep-apt.list`, `rosdep-pip.list`, and `CONFIG_IMAGE_KEY` for your project.

## Sample Hardware and OS Requirements

We tested this repository on these configurations:

| Scenario                       | Sample hardware                                          | Sample OS / platform           | Environments          |
| ------------------------------ | -------------------------------------------------------- | ------------------------------ | --------------------- |
| Jetson development (`aarch64`) | Jetson Orin NX, AGX Orin or AGX Thor, 40 GB+ free disk   | JetPack 7 (Ubuntu 24.04 based) | `asv`, `auv`, `uav2`  |
| Workstation (`x86_64`)         | 8+ CPU cores, 16-32 GB RAM, NVIDIA GPU, 50 GB+ free disk | Ubuntu 24.04 LTS               | `auv_sim`, `uav2_sim` |

We tested on NVIDIA's Isaac ROS 4.6 images from the [NGC tag catalog](https://catalog.ngc.nvidia.com/orgs/nvidia/isaac/containers/ros/-/tags):

- `nvcr.io/nvidia/isaac/ros:isaac_ros_de03e5dcb6796908b25f26e17c263ea5-amd64`
- `nvcr.io/nvidia/isaac/ros:isaac_ros_de03e5dcb6796908b25f26e17c263ea5-arm64-jetpack`

These are the latest versions as of 14 Aug 2026. Feel free to update accordingly.

## Installation

_For ease of installation, save this directory as `~/workspaces/ros2-docker`._

### Installation on Jetson

<details>
<summary><strong>Installation on Jetson</strong></summary>
</br>

Source: [https://nvidia-isaac-ros.github.io/getting_started/compute/index.html](https://nvidia-isaac-ros.github.io/getting_started/compute/index.html)

Commands from the above website are pasted below:

#### Install Jetpack <!-- omit from toc -->

```bash
sudo apt install nvidia-jetpack
```

#### Install Docker <!-- omit from toc -->

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

#### Add Docker to User Group <!-- omit from toc -->

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Reboot the computer for the changes to take effect.

#### Setup Isaac ROS <!-- omit from toc -->

Source: [https://nvidia-isaac-ros.github.io/getting_started/index.html](https://nvidia-isaac-ros.github.io/getting_started/index.html)

Commands from the above website are pasted below:

```bash
sudo systemctl daemon-reload && sudo systemctl restart docker

mkdir -p ~/workspaces/isaac_ros-dev/src
echo "export ISAAC_ROS_WS=${HOME}/workspaces/isaac_ros-dev/" >> ~/.bashrc
source ~/.bashrc
```

#### Jetson Clocks (Optional) <!-- omit from toc -->

Running `sudo jetson_clocks` maximises Jetson performance. We can make `jetson_clocks` run on start up.

Create the file `/etc/systemd/system/jetsonClocks.service` and add the following lines:

```
[Unit]
Description=Maximize Jetson Performance
After=nvpmodel.service
Requires=nvpmodel.service

[Service]
ExecStart=/usr/bin/jetson_clocks

[Install]
WantedBy=multi-user.target
```

Then run the following commands

```bash
sudo chmod 644 /etc/systemd/system/jetsonClocks.service
sudo systemctl daemon-reload
sudo systemctl enable jetsonClocks.service
```

Reboot the computer to let the changes take effect.

#### Add Authorized SSH Keys (Optional) <!-- omit from toc -->

To avoid keying in the password each time login in via SSH, add the client computer's public key (e.g. `id_rsa.pub`) into `~/.ssh/authorized_keys`. Note that `~/.ssh/authorized_keys` should be a **file** not a folder.

</details>

### Installation on x86_64

<details>
<summary><strong>Installation on x86_64</strong></summary>
</br>

Follow [https://nvidia-isaac-ros.github.io/getting_started/compute/index.html](https://nvidia-isaac-ros.github.io/getting_started/compute/index.html)
and [https://nvidia-isaac-ros.github.io/concepts/dev_env/index.html](https://nvidia-isaac-ros.github.io/concepts/dev_env/index.html) to set up
Isaac ROS docker dev environment.

Alternatively, use `scripts/install_dev_env_x86.sh`, and then run

```bash
newgrp docker
```

outside of the script.

</details>

## Build a ROS 2 Docker Image

1. Choose or create an environment in the `environments` folder.

2. Install the `ros2-docker` executable.

```bash
./setup.sh
```

3. Select an environment. For example, for the `auv4_orin` environment:

```bash
ros2-docker use auv4_orin
```

4. Build the docker images.

```bash
ros2-docker build
```

5. Start the container and open a shell.

```bash
ros2-docker start
```

## Production

By default, file changes (except in the mounted workspaces) and installations in a running Docker container are not persistent. To save the current state of the container's filesystem to an image, do `docker container commit` (https://docs.docker.com/reference/cli/docker/container/commit/).

Then, you can set the `BUILD_IMAGE_FLAG=0` in `.ros_docker-config` (in the environment directory) and set `BUILT_IMAGE` to the image tag. This runs the built image instead of building a new image each time when starting the container.

**NOTE**: `BUILD_IMAGE_FLAG=1` does not behave well when launching multiple instances of the container at the same time (e.g., using `tmuxp`). Recommended workflow is to build the container separately, set `BUILD_IMAGE_FLAG=0` and then launch the `tmuxp` session(s).

## ROS Dependencies

Run the following command in your ROS workspace to generate a list of `apt` packages required.

```bash
rosdep install --from-paths src --ignore-src --reinstall --simulate | grep "apt-get install" | sed 's/.*apt-get install //g'
```

Similaly, run the following for a list of `pip` packages.

```bash
rosdep install --from-paths src --ignore-src --reinstall --simulate | grep "pip3 install -U -I" | sed 's/.*pip3 install -U -I //g'
```

Save this as a file in your environment directory and install it in the corresponding Dockerfile. See [environments/auv4_orin/rosdep.list](environments/auv4_orin/rosdep.list) and [dockerfiles/common/Dockerfile.auv4_orin](dockerfiles/common/Dockerfile.auv4_orin) for an example.

## Notes

### TODO

- (Good to have) combine Isaac ROS and Husarnet default Fast RTPS scripts to poll topics outside of container while publishing over the internet
- (Good to have) Consider https://github.com/husarnet/ros-docker/tree/main

### Issues

See [ISSUES.md](ISSUES.md).
