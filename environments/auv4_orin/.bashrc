
# For sourcing of paths for Spinnaker SDK
# Source: /etc/profile outside the container
if [ -d /etc/profile.d ]; then
  for i in /etc/profile.d/*.sh; do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi

# ROS2 Humble
source /opt/ros/humble/setup.bash

# # Fast DDS Discovery Server
# # Source https://docs.ros.org/en/humble/Tutorials/Advanced/Discovery-Server/Discovery-Server.html
# # Does not work when there are too many nodes, not sure why
# BRING_UP_PATH=/workspaces/isaac_ros-dev/src/bring-up
# export FASTRTPS_DEFAULT_PROFILES_FILE=$BRING_UP_PATH/etc/fastdds_supeclient.xml

# Prevents ROS nodes on other devices in the subnet not in the same ROS domain from talking to each other
# Must be the same as SBC
export ROS_DOMAIN_ID=2

# Fast DDS Unicast
# Prevents discovery through routers
BRING_UP_PATH=/workspaces/isaac_ros-dev/src/bring-up
export FASTRTPS_DEFAULT_PROFILES_FILE=$BRING_UP_PATH/etc/auv4_orin/fastdds_unicast.xml
