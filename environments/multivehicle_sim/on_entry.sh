#!/bin/bash

# Runs when the Docker container is launched.
# These commands cannot be in a Dockerfile because they require mounted directories.
# This script requires the `uav2_description` package to be built in /workspaces/uav_ws.

set -e

# For protobuf permissions for dave sim plugins (inherited from auv_sim)
sudo chown $(whoami) -R /usr/local/include/google/protobuf

PX4_AUTOPILOT_DIR=$HOME/PX4-Autopilot
PX4_SITL_DIR=$HOME/px4_sitl
UAV_WS_DIR=/workspaces/uav_ws
BRINGUP_DIR=/workspaces/isaac_ros-dev/src/bring-up
PX4_AUTOPILOT_GZ_DIR=${PX4_AUTOPILOT_DIR}/Tools/simulation/gz
PX4_MODEL_DIR=${PX4_AUTOPILOT_GZ_DIR}/models/uav2
PX4_AIRFRAMES_DIR=${PX4_SITL_DIR}/romfs/etc/init.d-posix/airframes
UAV2_DESC_URDF_DIR=${UAV_WS_DIR}/install/uav2_description/share/uav2_description/urdf
ETC_DIR=${BRINGUP_DIR}/etc/multivehicle_sim

mkdir -p ${PX4_MODEL_DIR}
gz sdf -p ${UAV2_DESC_URDF_DIR}/uav2.urdf > ${PX4_MODEL_DIR}/model.sdf
ln -sf $(realpath ${ETC_DIR}/model.config) ${PX4_MODEL_DIR}
ln -sf $(realpath ${ETC_DIR}/5000_gz_uav2) ${PX4_AIRFRAMES_DIR}
