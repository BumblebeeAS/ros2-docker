# Source all ROS workspaces
source /etc/profile.d/setup_spinnaker_gentl_64.sh 64
source /etc/profile.d/setup_spinnaker_paths.sh
sudo chmod 777 /dev/bus/ -R

if [ -d /workspaces/zed/install ]; then 
    source /workspaces/zed/install/local_setup.bash
fi

if [ -d /workspaces/isaac_ros-dev/install ]; then 
    source /workspaces/isaac_ros-dev/install/setup.bash
fi

if [ -d /workspaces/drone/install ]; then 
    source /workspaces/drone/install/setup.bash
fi
