#!/bin/bash

if [ -d /workspaces/isaac_ros-dev ]; then 
    cd /workspaces/isaac_ros-dev ; 
    echo "rosdep updating for isaac_ros-dev....." ; 
    rosdep install --from-paths src -y --ignore-src ; 
fi

if [ -d /workspaces/drone ]; then 
    cd /workspaces/drone ; 
    echo "rosdep updating for drone....." ; 
    # rosdep install --from-paths src -y --ignore-src ; 
    rosdep install --from-paths src --ignore-src --skip-keys intercomm_msgs -y ;
fi

$@
