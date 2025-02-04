# Clean ROS workspace builds
alias clean-ws="rm -r build install log"

# FLIR SpinView visualization
alias xpinview="Xephyr -br -ac -noreset -screen 1920x1080 :1 & DISPLAY=:1 SpinView_QT"

# Append the camera serial number e.g. start-flir serial:="'17500915'"
alias start-flir="ros2 launch spinnaker_camera_driver driver_node.launch.py camera_type:=blackfly_s"
