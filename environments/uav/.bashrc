# Source all ROS workspaces
if [ -d /workspaces/isaac_ros-dev/install ]; then 
    source /workspaces/isaac_ros-dev/install/setup.bash
fi

export ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-38}
export RMW_IMPLEMENTATION=${RMW_IMPLEMENTATION:-rmw_fastrtps_cpp}
export FASTDDS_DEFAULT_PROFILES_FILE=${FASTDDS_DEFAULT_PROFILES_FILE:-/workspaces/isaac_ros-dev/src/bring-up/etc/uav/fastdds_local.xml}
