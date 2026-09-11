# Default is capabilities:=[clientPublish,parameters,parametersSubscribe,services,connectionGraph,assets]
alias foxglove-bridge="ros2 launch foxglove_bridge foxglove_bridge_launch.xml capabilities:=[clientPublish,services,connectionGraph,assets]"
alias start-px4-agent="export FASTRTPS_DEFAULT_PROFILES_FILE=/workspaces/isaac_ros-dev/src/bring-up/etc/uav/middleware_profiles/rtps_udp_profile.xml && \
    export RMW_FASTRTPS_USE_QOS_FROM_XML=1 && \
    MicroXRCEAgent udp4 -p 8888"
alias udp4-dds-config="export FASTRTPS_DEFAULT_PROFILES_FILE=/workspaces/isaac_ros-dev/src/bring-up/etc/uav/middleware_profiles/rtps_udp_profile.xml"
alias clean-ws="rm -r build install log"
alias start-mpserver="ros2 launch behavior_tree mission_planner.launch.py config:=example.yaml action_name:=my_engine groot2_port:=1667 ns:=aaa"
alias source-cam-ws="source /workspaces/isaac_ros-dev/install/setup.bash"
alias muxinator="tmuxinator start -p /workspaces/isaac_ros-dev/src/bring-up/etc/uav/config/tmuxinator/drone.yaml"
alias run-tree="sh /workspaces/drone/tree_selection.sh"
alias bag-cam="ros2 bag record -s mcap /uav2/wide_a/rect/image /uav2/narrow_a/rect/image"
