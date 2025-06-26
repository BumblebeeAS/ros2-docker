
# ROS2 Humble
source /opt/ros/humble/setup.bash

# Fast DDS Discovery Server
# Source https://docs.ros.org/en/humble/Tutorials/Advanced/Discovery-Server/Discovery-Server.html
SOFTWARE_AUV_4_PATH=/workspaces/isaac_ros-dev/src/software-auv-4
export FASTRTPS_DEFAULT_PROFILES_FILE=$SOFTWARE_AUV_4_PATH/etc/fastdds_supeclient.xml
