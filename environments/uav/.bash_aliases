# Default is capabilities:=[clientPublish,parameters,parametersSubscribe,services,connectionGraph,assets]
alias foxglove-bridge="ros2 launch foxglove_bridge foxglove_bridge_launch.xml capabilities:=[clientPublish,services,connectionGraph,assets]"
alias clean-ws="rm -r build install log"
alias start-mpserver="ros2 launch behavior_tree mission_planner.launch.py config:=example.yaml action_name:=my_engine groot2_port:=1667 ns:=aaa"
alias source-cam-ws="source /workspaces/isaac_ros-dev/install/setup.bash"
alias run-tree="sh /workspaces/drone/tree_selection.sh"
alias bag-cam="ros2 bag record -s mcap /uav/wide_a/rect/image /uav/narrow_a/rect/image"
