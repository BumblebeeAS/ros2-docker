
# ROS2 Humble
source /opt/ros/humble/setup.bash

# Custom ROS2 workspaces
if [ -f /workspaces/isaac_ros-dev/install/setup.bash ]; then
    source /workspaces/isaac_ros-dev/install/setup.bash
fi

export GZ_SIM_RESOURCE_PATH=$GZ_SIM_RESOURCE_PATH:$HOME/PX4-Autopilot/Tools/simulation/gz/models

# bb_robotx_dashboard runtime env. Baked into ~/.bashrc at image build time
# (Dockerfile.install_env appends this file), so every interactive shell —
# including tmux panes — picks them up. Rotate DASHBOARD_ADMIN_SECRET before
# exposing the dashboard beyond localhost; changes require an image rebuild.
export ROBOCOMMAND_HOST=localhost
export ROBOCOMMAND_PORT=9000
export ROBOCOMMAND_TEAM_ID=42
export DASHBOARD_LISTEN_HOST=0.0.0.0
export DASHBOARD_LISTEN_PORT=8080
export DASHBOARD_ADMIN_SECRET=bumblebee
