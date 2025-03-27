- [Installation](#installation)
  - [Installation on SBC](#installation-on-sbc)
    - [Setup Docker](#setup-docker)
      - [Install Jetpack](#install-jetpack)
      - [Install Docker](#install-docker)
      - [Add Docker to User Group](#add-docker-to-user-group)
    - [Jetson Setup for VPI](#jetson-setup-for-vpi)
    - [Setup Isaac ROS](#setup-isaac-ros)
    - [Jetson Clocks (Optional)](#jetson-clocks-optional)
    - [Add Authorized SSH Keys (Optional)](#add-authorized-ssh-keys-optional)
  - [Installation on local computer](#installation-on-local-computer)
- [Setup Workspaces](#setup-workspaces)
- [Build Isaac ROS Docker Image](#build-isaac-ros-docker-image)
- [Start Docker Container](#start-docker-container)
  - [Development](#development)
  - [Production](#production)
- [Notes](#notes)
  - [TODO](#todo)
  - [Issues](#issues)
    - [1. Husarnet](#1-husarnet)
    - [2. Sourcing of ROS Workspaces on Entry](#2-sourcing-of-ros-workspaces-on-entry)
    - [3. Jetson Clocks](#3-jetson-clocks)
    - [4. ZED](#4-zed)
    - [5. Permission Issues with FLIR](#5-permission-issues-with-flir)

# Installation

_For ease of installation, save this directory as `~/workspaces/ros2-docker`._

## Installation on SBC

### Setup Docker

Source: https://nvidia-isaac-ros.github.io/getting_started/hardware_setup/compute/index.html

Commands from the above website are pasted below:

#### Install Jetpack

```bash
sudo apt install nvidia-jetpack
```

#### Install Docker

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

#### Add Docker to User Group

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Reboot the computer for the changes to take effect.

### Jetson Setup for VPI

Source: https://nvidia-isaac-ros.github.io/getting_started/hardware_setup/compute/jetson_vpi.html

```bash
sudo nvidia-ctk cdi generate --mode=csv --output=/etc/cdi/nvidia.yaml

# Add Jetson public APT repository
sudo apt-get update
sudo apt-get install software-properties-common
sudo apt-key adv --fetch-key https://repo.download.nvidia.com/jetson/jetson-ota-public.asc
sudo add-apt-repository 'deb https://repo.download.nvidia.com/jetson/common r36.4 main'
sudo apt-get update
sudo apt-get install -y pva-allow-2
```

### Setup Isaac ROS

Source: https://nvidia-isaac-ros.github.io/getting_started/dev_env_setup.html

Commands from the above website are pasted below:

```bash
sudo systemctl daemon-reload && sudo systemctl restart docker

sudo apt-get install git-lfs
git lfs install --skip-repo

mkdir -p ~/workspaces/isaac_ros-dev/src
echo "export ISAAC_ROS_WS=${HOME}/workspaces/isaac_ros-dev/" >> ~/.bashrc
source ~/.bashrc
```

### Jetson Clocks (Optional)

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

### Add Authorized SSH Keys (Optional)

To avoid keying in the password each time login in via SSH, add the client computer's public key (e.g. `id_rsa.pub`) into `~/.ssh/authorized_keys`. Note that `~/.ssh/authorized_keys` should be a **file** not a folder.

## Installation on local computer

This is for decoding images compressed on the Jetson.

Follow https://nvidia-isaac-ros.github.io/getting_started/hardware_setup/compute/index.html
and https://nvidia-isaac-ros.github.io/getting_started/dev_env_setup.html to set up
Isaac ROS docker dev environment.

# Setup Workspaces

1. Make the drone ROS workspace:

```bash
mkdir -p ~/workspaces/drone/src
```

2. Clone https://github.com/BumblebeeAS/software-uav-2 into `~/workspaces/drone/src`

3. Follow the setup guide at https://github.com/BumblebeeAS/software-uav-2

# Build Isaac ROS Docker Image

For SBC, use `isaac_ros_jp6.0`. For local computer, use `isaac_ros_x64`.

1. Clone `isaac_ros_common`.

```bash
cd ${ISAAC_ROS_WS}/src && \
   git clone -b release-3.2 https://github.com/NVIDIA-ISAAC-ROS/isaac_ros_common.git isaac_ros_common
```

Correct as of 28 Dec 2024. Replace `release-3.2` with the latest stable release.

2. Edit the Isaac ROS Common config file by setting `CONFIG_DOCKER_SEARCH_DIRS` as

For `isaac_ros_jp6.0`:

```
(<Path to this directory>/isaac_ros_jp6.0)
```

For `isaac_ros_x64`:

```
(<Path to this directory>/isaac_ros_x64)
```

By default, `<Path to this directory>` is `$HOME/workspaces/ros2-docker`.

Take note to enclose it with `()` and ensure that there are no spaces.

3. Create copies and symbolic links for the required config files and scripts.

By default, the path to this directory is `$HOME/workspaces/ros2-docker`. Replace it below with the path to this directory if yours is different.

E.g.:

```bash
export SOURCE_DIRECTORY=$HOME/workspaces/ros2-docker/
export ENVIRONMENT_NAME=auv4_orin
ln -sf $SOURCE_DIRECTORY/environments/$ENVIRONMENT_NAME/.isaac_ros_common-config   ~/.isaac_ros_common-config
ln -sf $SOURCE_DIRECTORY/run_dev.sh                 ${ISAAC_ROS_WS}/src/isaac_ros_common/scripts/run_dev.sh
unset SOURCE_DIRECTORY
unset ENVIRONMENT_NAME
```

4. Build the docker images.

```bash
cd ${ISAAC_ROS_WS}/src/isaac_ros_common
./scripts/run_dev.sh
```

# Start Docker Container

`run_dev.sh` is for development, while `run_main.sh` is for production. The difference is that `run_dev.sh` attempts a Docker image build each time, while `run_main.sh` looks up an existing Docker image.

## Development

```bash
cd ${ISAAC_ROS_WS}/src/isaac_ros_common
./scripts/run_dev.sh
```

## Production

`run_main.sh` is meant to run a built image, which can be built by `run_dev.sh`.

By default, file changes (except in the mounted workspaces) and installations in a running Docker container are not persistent. To save the current state of the container's filesystem to an image, do `docker container commit` (https://docs.docker.com/reference/cli/docker/container/commit/).

`run_main.sh` requires the environment variable `BUILT_DOCKER_CONTAINER_NAME`. It reads environment variables from `ENV_FILE`, which by default is `$HOME/workspaces/ros2-docker/environments/.env`. If the path of your file is different, change `ENV_FILE` in `run_main.sh`.

# Notes

## TODO

- (Good to have) combine Isaac ROS and Husarnet default Fast RTPS scripts to poll topics outside of container while publishing over the internet
- (Good to have) Consider https://github.com/husarnet/ros-docker/tree/main

## Issues

### 1. Husarnet

- For now, install and join the network outside Docker. Unable to join while building the Docker containers.
- For now, run `husarnet-dds singleshot` inside the running container. No effect when starting in Dockerfiles.

### 2. Sourcing of ROS Workspaces on Entry

- Only the first terminal instance running the Docker container source the ROS workspaces automatically. Subsequent instances do not.

### 3. Jetson Clocks

**UPDATE: After manually compiling the L4T 36.3 kernel and reflashing to enable USB modem connection (another unrelated issue), this issue seems to have been fixed.**

- Even after setting Jetson Clocks to run on startup [above](#jetson-clocks-optional), it may randomly fail to start up due to a bug with `nvpmodel` (https://forums.developer.nvidia.com/t/segfault-in-usr-sbin-nvpmodel/295010/16). Simply do:

```bash
sudo systemctl restart nvpmodel.service
sudo systemctl restart jetsonClocks.service
```

Where the second line can be replaced with `sudo jetson_clocks` if the service is not set up.

### 4. ZED

When starting camera stream for the ZED camera within the Docker container using the following command:

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedm
```

We might see the following errors:

- No camera detected.
- `MOTION SENSORS REQUIRED` error.

To fix these errors, do the following:

1. (If they are not already done,) install the ZED SDK ("yes" for all options) and build the `zed_wrapper` ROS package outside the Docker container.
2. Run the above command (using `zed_wrapper` to start the camera stream) outside the container and interrupt the process.

Thereafter, the camera stream can be started within the container without errors.

This fix seems to not persist between boots. If needed, repeat the process to fix the issue after boot.

### 5. Permission Issues with FLIR

Unable to obtain any FLIR camera feed or use FLIR spinnaker interface. Need to make sure the udev rules are correct (can be checked by `lsusb` to check the vendor id etc.). We noticed there were permission issues even after the udev rule fix, a temporary fix was to run `chmod 777 /dev/bus -R` to connect to camera.
