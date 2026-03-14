# Issues

## Husarnet

- For now, install and join the network outside Docker. Unable to join while building the Docker containers.
- For now, run `husarnet-dds singleshot` inside the running container. No effect when starting in Dockerfiles.

## Jetson Clocks

**UPDATE: After manually compiling the L4T 36.3 kernel and reflashing to enable USB modem connection (another unrelated issue), this issue seems to have been fixed.**

- Even after setting Jetson Clocks to run on startup in [README.md](README.md#jetson-clocks-optional), it may randomly fail to start up due to a bug with `nvpmodel` (https://forums.developer.nvidia.com/t/segfault-in-usr-sbin-nvpmodel/295010/16). Simply do:

```bash
sudo systemctl restart nvpmodel.service
sudo systemctl restart jetsonClocks.service
```

Where the second line can be replaced with `sudo jetson_clocks` if the service is not set up.

## ZED

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

## Permission Issues with FLIR

Unable to obtain any FLIR camera feed or use FLIR spinnaker interface. Need to make sure the udev rules are correct (can be checked by `lsusb` to check the vendor id etc.). We noticed there were permission issues even after the udev rule fix, a temporary fix was to run `chmod 777 /dev/bus -R` to connect to camera.

## Permission Issues (General)

Directories / files created by Dockerfiles and helper scripts run in root as well as directories mounted that are not present previously will have `root` as the owner (e.g., `~/.cache/ccache` if it was not present before mounting). Simply do `sudo chmod <user> -R <directory>`.

(If changing ownership fixes [Permission Issues with FLIR](#permission-issues-with-flir), remove it.)

## Docker Max Depth Exceeded

As of 31 May 2025, having too many image layers will result in a `docker: Error response from daemon: max depth exceeded` error. The maximum number of image layers seems to be 208 (run `docker history <image_name> | wc -l` to check).

## OCI runtime error

If you see the following error even after running [Jetson Setup for VPI](README.md#jetson-setup-for-vpi):

```bash
docker: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: could not apply required modification to OCI specification: error modifying OCI spec: failed to inject CDI devices: failed to inject devices: failed to stat CDI host device "/dev/fb0": no such file or directory: unknown
```

Just re-run the commands in [Jetson Setup for VPI](README.md#jetson-setup-for-vpi) and try again.
