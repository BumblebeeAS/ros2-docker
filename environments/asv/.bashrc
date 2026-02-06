
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

# Prevents ROS nodes on other devices in the subnet not in the same ROS domain from talking to each other
export ROS_DOMAIN_ID=2

# Controls
export BB_VEHICLE="auv4"
