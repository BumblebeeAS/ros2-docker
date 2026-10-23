# UAV camera calibration

The UAV image installs the measured IMX219 color calibration from
`environments/uav/camera_color.yaml` at `/etc/ros/uav/camera_color.yaml` and sets
`UAV_CAMERA_COLOR_CONFIG` to that path. The camera launch in `vision_pipeline`
reads this file. The calibration survives container recreation without manual
package installation or file copying.

`dockerfiles/arm64/Dockerfile.gscam` installs the required GStreamer filters:
`gstreamer1.0-plugins-bad`, `gstreamer1.0-gl`, and `frei0r-plugins`.
`dockerfiles/environments/Dockerfile.uav_camera_color` copies the calibration as
the final image layer, so calibration edits retain the expensive dependency
build caches. It also selects
asynchronous Fast DDS publication to avoid camera component-loading timeouts.

The ROS workspace still provides the camera launch and generic shader helper;
keep its corresponding `vision_pipeline` changes when moving to another host.

## Calibration settings

The 2026-10-23 neutral-paper calibration uses the stock L4T R39.2.1 IMX219 NITO
profile with automatic white balance and sensor mode 4 (1280 x 720 capture).
The host's incompatible legacy `camera_overrides.isp` must remain disabled.
The image does not modify the host ISP configuration.

- `color_balance_rgb`: per-camera RGB multipliers for the overall magenta cast.
- `color_shading`: wide-camera spatial log(R/G) and log(B/G) surfaces, applied
  after global color balance and before rectification. Coefficient order is
  `1, x, y, x*x, x*y, y*y, (x*x+y*y)**2`, with coordinates from -1 to 1 starting
  at the top-left. A headless EGL shader preserves neutral-surface luminance.

Remove a camera's `color_shading` entry to disable its spatial correction.
Remove its `color_balance_rgb` entry to disable global color balance. Recheck
calibration after changing the lens, sensor mode, module, IR-cut filter, or
lighting; this is not a full color-chart ISP calibration.

## Apply changes

Edit `environments/uav/camera_color.yaml`, then rebuild and recreate the UAV
container during a suitable maintenance window:

```bash
ros2-docker use uav
ros2-docker down
ros2-docker build
ros2-docker up
```

For a temporary update to the existing container, from this repository root:

```bash
docker cp environments/uav/camera_color.yaml uav:/etc/ros/uav/camera_color.yaml
```

Then restart only the camera launch. It reads calibration at startup; Argus
does not need a restart. To use another installed file, set
`UAV_CAMERA_COLOR_CONFIG` before launching the cameras.
