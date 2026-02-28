# Clean ROS workspace builds
alias clean-ws="rm -r build install log"

alias foxglove-bridge="ros2 launch foxglove_bridge foxglove_bridge_launch.xml port:=8765"

# Start Micro XRCE-DDS Agent (bridges PX4 uORB topics to ROS2)
alias uxrce-agent="MicroXRCEAgent udp4 -p 8888"

# Run PX4 SITL standalone — attaches to an already-running Gazebo instance.
# PX4_SYS_AUTOSTART=4001 is the x500 quadrotor airframe.
alias px4-sitl="PATH=$HOME/px4_sitl/bin:$PATH PX4_GZ_MODEL_PATH=$HOME/PX4-Autopilot/Tools/simulation/gz/models PX4_GZ_STANDALONE=1 PX4_SYS_AUTOSTART=5000 PX4_PARAM_UXRCE_DDS_SYNCT=0 $HOME/px4_sitl/bin/px4 -w $HOME/px4_sitl/romfs"
