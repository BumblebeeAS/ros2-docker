
# ROS2 Humble
source /opt/ros/humble/setup.bash

# Custom ROS2 workspaces
if [ -f /workspaces/isaac_ros-dev/install/setup.bash ]; then
    source /workspaces/isaac_ros-dev/install/setup.bash
fi

export GZ_SIM_RESOURCE_PATH=$GZ_SIM_RESOURCE_PATH:$HOME/PX4-Autopilot/Tools/simulation/gz/models
