#!/bin/bash
set -e

cd $HOME 
sudo chown -R admin:admin $HOME/PX4-Autopilot

UAV2_SIM_DIR=$HOME/colcon_ws
PX4_AUTOPILOT_DIR=$HOME/PX4-Autopilot

PX4_AUTOPILOT_GZ_DIR=${PX4_AUTOPILOT_DIR}/Tools/simulation/gz
PX4_AUTOPILOT_MODEL_DIR=${PX4_AUTOPILOT_GZ_DIR}/models/uav2
PX4_AUTOPILOT_AIRFRAMES_DIR=${PX4_AUTOPILOT_DIR}/ROMFS/px4fmu_common/init.d-posix/airframes/
DEST_MODELS_DIR=${PX4_AUTOPILOT_DIR}/Tools/simulation/gz/models

DESCRIPTION_PKG_PATH=${UAV2_SIM_DIR}/install/uav2_description/share/uav2_description
UAV2_DESC_URDF_DIR=${DESCRIPTION_PKG_PATH}/urdf
ETC_DIR=${UAV2_SIM_DIR}/src/bring-up/etc/uav2_sim
SOURCE_MODELS_DIR=${UAV2_SIM_DIR}/src/bb_worlds/models/robotx24/
WORLD_FILE=${UAV2_SIM_DIR}/src/bb_worlds/worlds/robotx_2024_aruco.sdf

export GZ_SIM_RESOURCE_PATH=$SOURCE_MODELS_DIR:${UAV2_SIM_DIR}/install/uav2_description/share


mkdir -p ${PX4_AUTOPILOT_MODEL_DIR}
mkdir -p ${DEST_MODELS_DIR}

if [ -f "${UAV2_DESC_URDF_DIR}/uav2.urdf" ]; then
    gz sdf -p ${UAV2_DESC_URDF_DIR}/uav2.urdf > ${PX4_AUTOPILOT_MODEL_DIR}/model.sdf
    echo "Generated model.sdf"
else
    echo "WARNING: uav2.urdf not found. Skipping SDF generation."
fi  

ln -sf $(realpath ${ETC_DIR}/model.config) ${PX4_AUTOPILOT_MODEL_DIR}
ln -sf $(realpath ${ETC_DIR}/5000_gz_uav2) ${PX4_AUTOPILOT_AIRFRAMES_DIR}

if [ -d "$SOURCE_MODELS_DIR" ]; then
    ln -sf ${SOURCE_MODELS_DIR}/ ${DEST_MODELS_DIR}/
    echo "Linked custom world models."
fi 

if [ -d "$DESCRIPTION_PKG_PATH" ]; then
    ln -sf $DESCRIPTION_PKG_PATH ${DEST_MODELS_DIR}/
    echo "Linked uav2_description."
fi

if [ -f "$WORLD_FILE" ]; then
    ln -sf $(realpath $WORLD_FILE) ${PX4_AUTOPILOT_GZ_DIR}/worlds
    echo "Linked World file."
fi 

echo "PX4 Setup Complete."
