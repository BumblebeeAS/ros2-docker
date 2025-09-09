#!/bin/bash

# Script to set up environment paths for Isaac ROS Docker
# Usage: ./setup_env_paths.sh <environment_name>

set -e

# Check if environment name is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <environment_name>"
    echo "Available environments:"
    ls -1 "$(dirname "$0")/../environments" | grep -v README.md
    exit 1
fi

ENVIRONMENT_NAME="$1"
SOURCE_DIRECTORY="$(cd "$(dirname "$0")/.." && pwd)"

# Check if environment exists
if [ ! -d "$SOURCE_DIRECTORY/environments/$ENVIRONMENT_NAME" ]; then
    echo "Error: Environment '$ENVIRONMENT_NAME' does not exist."
    echo "Available environments:"
    ls -1 "$SOURCE_DIRECTORY/environments" | grep -v README.md
    exit 1
fi

# Check if ISAAC_ROS_WS is set
if [ -z "$ISAAC_ROS_WS" ]; then
    echo "Error: ISAAC_ROS_WS environment variable is not set."
    echo "Please set it to your Isaac ROS workspace directory."
    echo "Example: export ISAAC_ROS_WS=\${HOME}/workspaces/isaac_ros-dev/"
    exit 1
fi

# Check if isaac_ros_common exists
if [ ! -d "$ISAAC_ROS_WS/src/isaac_ros_common" ]; then
    echo "Error: isaac_ros_common not found at $ISAAC_ROS_WS/src/isaac_ros_common"
    echo "Please clone isaac_ros_common first!"
    exit 1
fi

echo $ENVIRONMENT_NAME $SOURCE_DIRECTORY

echo "Setting up environment: $ENVIRONMENT_NAME"
echo "Source directory: $SOURCE_DIRECTORY"
echo "Isaac ROS workspace: $ISAAC_ROS_WS"

# Create symbolic links
echo "Creating symbolic links for .isaac_ros_common-config and run_dev.sh..."
ln -sf "$SOURCE_DIRECTORY/environments/$ENVIRONMENT_NAME/.isaac_ros_common-config" ~/.isaac_ros_common-config
ln -sf "$SOURCE_DIRECTORY/run_dev.sh" "${ISAAC_ROS_WS}/src/isaac_ros_common/scripts/run_dev.sh"

echo "Setup completed successfully!"
