
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

export GZ_SIM_RESOURCE_PATH=$GZ_SIM_RESOURCE_PATH:$HOME/PX4-Autopilot/Tools/simulation/gz/models

# Dashboard connection and server defaults.
export ROBOCOMMAND_HOST=localhost
export ROBOCOMMAND_PORT=9000
export ROBOCOMMAND_TEAM_ID=42
export DASHBOARD_LISTEN_HOST=0.0.0.0
export DASHBOARD_LISTEN_PORT=8080
export DASHBOARD_ADMIN_SECRET=bumblebee
