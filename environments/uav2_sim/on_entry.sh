#!/bin/bash

# Runs when the Docker container is launched.
# These commands cannot be in a Dockerfile because they require mounted directories.
# This script requires the `uav2_description` package to be built and the `bb_worlds` 
# package to be present.

set -e

PX4_AUTOPILOT_DIR=$HOME/PX4-Autopilot
UAV2_SIM_DIR=/workspaces/isaac_ros-dev
PX4_AUTOPILOT_GZ_DIR=${PX4_AUTOPILOT_DIR}/Tools/simulation/gz
PX4_AUTOPILOT_MODEL_DIR=${PX4_AUTOPILOT_GZ_DIR}/models/uav2
PX4_AUTOPILOT_AIRFRAMES_DIR=${PX4_AUTOPILOT_DIR}/ROMFS/px4fmu_common/init.d-posix/airframes/
UAV2_DESC_URDF_DIR=${UAV2_SIM_DIR}/install/uav2_description/share/uav2_description/urdf
ETC_DIR=${UAV2_SIM_DIR}/src/bring-up/etc/uav2_sim
WORLDS_DIR=${UAV2_SIM_DIR}/src/bb_worlds/worlds

mkdir -p ${PX4_AUTOPILOT_MODEL_DIR}
gz sdf -p ${UAV2_DESC_URDF_DIR}/uav2.urdf > ${PX4_AUTOPILOT_MODEL_DIR}/model.sdf
ln -sf $(realpath ${ETC_DIR}/model.config) ${PX4_AUTOPILOT_MODEL_DIR}
ln -sf $(realpath ${ETC_DIR}/5000_gz_uav2) ${PX4_AUTOPILOT_AIRFRAMES_DIR}
ln -sf $(realpath ${WORLDS_DIR}/robotx_2024_aruco.sdf) ${PX4_AUTOPILOT_GZ_DIR}/worlds

if ! grep -q '5000_gz_uav2' "${PX4_AUTOPILOT_AIRFRAMES_DIR}/CMakeLists.txt"; then
    sed -i '/4021_gz_x500_flow/a \ \t5000_gz_uav2' \
        "${PX4_AUTOPILOT_AIRFRAMES_DIR}/CMakeLists.txt"
fi
