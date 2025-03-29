#!/bin/bash

if [ -f ~/.tmuxp.yaml ]; then
    echo "Starting tmux session..."
    tmuxp load -d ~/.tmuxp.yaml
fi
