# Environments

The `.ros_docker-config` file within each environment folder is the main configuration file.

## Selecting an Environment

`ros2-docker use <name>` saves the selected environment for the machine to a file that the other `ros2-docker` commands read from.

## Argument Descriptions

| Key                         | Description                                                                                                                                                                                                                | Example                                                                                            |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `CONFIG_IMAGE_KEY`          | REQUIRED. A list of image keys indicating which Dockerfiles are to be built. Inputted as a concatenation of keys separated by `.`. Each key must match the suffix of a Dockerfile's name. See [Build Order](#build-order). | `noble_pip.ccache.auv.install_env.ros2_python_pins`                                                |
| `CONFIG_DOCKER_SEARCH_DIRS` | REQUIRED. A list of directories where the script searches for the Dockerfiles indicated by `CONFIG_IMAGE_KEY`.                                                                                                             | `("dockerfiles/common" "dockerfiles/amd64" "dockerfiles/environments")`                            |
| `BUILT_IMAGE`               | REQUIRED. Name of the Docker image. This will be the name of the resultant image built. `ros2-docker start` or `up` will search the disk for the image name and an error will be thrown if the image is not found.         | `isaac-ros-auv-sim:latest`                                                                         |
| `MOUNT_DIRS`                | REQUIRED. List of directories to mount (changes inside the container will be reflected outside and vice versa).                                                                                                            | `("$HOME/workspaces/ros2_ws:/workspaces/ros2_ws" "$HOME/.cache/ccache:/home/admin/.cache/ccache")` |
| `WORKDIR`                   | REQUIRED. Working directory inside a container on start.                                                                                                                                                                   | `/workspaces/isaac_ros-dev`                                                                        |
| `DOCKER_CONTEXT_DIR`        | OPTIONAL, defaults to the repository root. See https://docs.docker.com/build/concepts/context/.                                                                                                                            | `.`                                                                                                |
| `DOCKER_BUILD_BASE_IMAGE`   | REQUIRED. Base image that the first layer builds from.                                                                                                                                                                     | `nvcr.io/nvidia/isaac/ros:isaac_ros_89df02...-amd64`                                               |

## Dependencies

As of 9 Jul 2025, `opencv-contrib-python<4.12` in `rosdep-pip.list` is required for `numpy<2`, which is required for Jetpack 6's `torch` and ROS packages.

## Build Order

For example, if `CONFIG_DOCKER_SEARCH_DIRS=("dockerfiles/common" "dockerfiles/environments")`, setting `CONFIG_IMAGE_KEY=noble_pip.ccache.auv.install_env.ros2_python_pins` builds these layers in order:

1. `dockerfiles/common/Dockerfile.noble_pip`
2. `dockerfiles/common/Dockerfile.ccache`
3. `dockerfiles/environments/Dockerfile.auv`
4. `dockerfiles/environments/Dockerfile.install_env`
5. `dockerfiles/common/Dockerfile.ros2_python_pins`

The first layer starts from `DOCKER_BUILD_BASE_IMAGE`. The final layer receives `BUILT_IMAGE`.

For Dockerfiles with no cross-dependencies, put Dockerfiles with long build times first. A change to one layer invalidates the cache for every layer after it, even when those later Dockerfiles are untouched. In the example above, a change in `Dockerfile.auv` would trigger a build for `auv`, `install_env`, and `ros2_python_pins`.
