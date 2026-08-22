
# ROS 2 Jazzy
source /opt/ros/jazzy/setup.bash

# DAVE simulation workspace
if [ -f /opt/dave_ws/install/setup.bash ]; then
    source /opt/dave_ws/install/setup.bash
fi

# Custom ROS2 workspaces
if [ -f /workspaces/isaac_ros-dev/install/setup.bash ]; then
    source /workspaces/isaac_ros-dev/install/setup.bash
fi

export BB_VEHICLE="auv4"
