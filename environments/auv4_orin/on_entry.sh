#!/bin/bash

# Run on entry instead of in Dockerfile since rosdep updates can still happen after the image is built
rosdep update

WORKSPACE_DIR=/workspaces/ros2_ws
if [ -d $WORKSPACE_DIR ]; then 
    cd $WORKSPACE_DIR ; 
    echo "rosdep updating..." ; 
    rosdep install --from-paths src -y --ignore-src ; 
fi

if [ -f ~/.tmuxp.yaml ]; then
    echo "Starting tmux session..."
    tmuxp load -d ~/.tmuxp.yaml
fi
