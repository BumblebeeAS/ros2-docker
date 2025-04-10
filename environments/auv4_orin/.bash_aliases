# Clean ROS workspace builds
alias clean-ws="rm -r build install log"

# FLIR SpinView visualization
alias xpinview="Xephyr -br -ac -noreset -screen 1920x1080 :1 & DISPLAY=:1 SpinView_QT"

# Append the camera serial number e.g. start-flir serial:="'17500915'"
alias start-flir="ros2 launch spinnaker_camera_driver driver_node.launch.py camera_type:=blackfly_s"

alias foxglove-bridge="ros2 launch foxglove_bridge foxglove_bridge_launch.xml port:=8765"
alias foxglove-bridge-whitelist="ros2 launch foxglove_bridge foxglove_bridge_launch.xml topic_whitelist:=[/auv4/front_cam/image_matching/compressed,/auv4/front_cam/color/image/compressed] service_whitelist:=[/auv4/image_matching/toggle_template] param_whitelist:=[random_string]"
