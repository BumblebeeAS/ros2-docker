# UAV camera calibration

The UAV image includes color calibration for the two IMX219 cameras. Adjust
`environments/uav/camera_color.yaml` as needed, and recheck it after changing
the cameras, lenses, or lighting.

Use the stock host ISP profile and leave the old downloaded override disabled.
The ROS workspace needs the matching `vision_pipeline` camera launch.

## Apply changes

After editing the calibration, rebuild and recreate the container:

```bash
ros2-docker use uav
ros2-docker down
ros2-docker build
ros2-docker up
```

To try a change without rebuilding, run from this repository root:

```bash
docker cp environments/uav/camera_color.yaml uav:/etc/ros/uav/camera_color.yaml
```

Then restart the camera launch. Set `UAV_CAMERA_COLOR_CONFIG` to use a different
calibration file.
