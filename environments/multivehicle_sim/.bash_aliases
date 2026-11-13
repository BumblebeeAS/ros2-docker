# Clean ROS workspace builds
alias clean-ws="rm -r build install log"

alias foxglove-bridge="ros2 launch foxglove_bridge foxglove_bridge_launch.xml port:=8765"

# Start Micro XRCE-DDS Agent (bridges PX4 uORB topics to ROS2)
alias uxrce-agent="MicroXRCEAgent udp4 -p 8888"

# Run PX4 SITL standalone — attaches to an already-running Gazebo instance.
alias px4-sitl="/workspaces/isaac_ros-dev/src/bring-up/etc/multivehicle_sim/launch-px4.sh"
