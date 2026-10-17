# Default is capabilities:=[clientPublish,parameters,parametersSubscribe,services,connectionGraph,assets]
alias foxglove-bridge="ros2 launch foxglove_bridge foxglove_bridge_launch.xml capabilities:=[clientPublish,services,assets] message_backlog_size:=8"
alias clean-ws="rm -r build install log"
alias bag-cam="ros2 bag record -s mcap --topics /uav/wide_a/rect/image /uav/narrow_a/rect/image"
