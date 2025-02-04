# Source all ROS workspaces
if [ -d /workspaces/isaac_ros-dev/install ]; then 
    source /workspaces/isaac_ros-dev/install/setup.bash
fi

if [ -d /workspaces/drone/install ]; then 
    source /workspaces/drone/install/setup.bash
fi
export ROS_DOMAIN_ID=38
