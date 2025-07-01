
# ROS2 Humble
source /opt/ros/humble/setup.bash

# # Fast DDS Discovery Server
# # Source https://docs.ros.org/en/humble/Tutorials/Advanced/Discovery-Server/Discovery-Server.html
# # Does not work when there are too many nodes, not sure why
# SOFTWARE_AUV_4_PATH=/workspaces/isaac_ros-dev/src/software-auv-4
# export FASTRTPS_DEFAULT_PROFILES_FILE=$SOFTWARE_AUV_4_PATH/etc/fastdds_supeclient.xml

# Prevents ROS nodes on other devices in the subnet not in the same ROS domain from talking to each other
# Must be the same as SBC
export ROS_DOMAIN_ID=2

# Fast DDS Unicast
# Prevents discovery through routers
SOFTWARE_AUV_4_PATH=/workspaces/isaac_ros-dev/src/software-auv-4
export FASTRTPS_DEFAULT_PROFILES_FILE=$SOFTWARE_AUV_4_PATH/etc/orin/fastdds_unicast.xml
