#!/bin/bash

# Build ROS dependency
echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc
source /opt/ros/${ROS_DISTRO}/setup.bash

# Restart udev daemon
sudo service udev restart

scripts_dir=/usr/local/bin/scripts
usrname=admin
grpname=flirimaging

# Add bash aliases
if [ -f $scripts_dir/drone.bash_aliases ]; then
    cat $scripts_dir/drone.bash_aliases >> ~/.bash_aliases
fi

# Add bashrc
if [ -f $scripts_dir/drone.bashrc ]; then
    cat $scripts_dir/drone.bashrc >> ~/.bashrc
fi

# Install workspace dependencies
shopt -s expand_aliases
source ~/.bash_aliases
source /etc/profile.d/setup_spinnaker_gentl_64.sh 64
source /etc/profile.d/setup_spinnaker_paths.sh
sudo usermod -a -G root $usrname
# https://unix.stackexchange.com/questions/153539/which-is-more-widely-used-chmod-777-or-chmod-arwx
sudo chmod 777 /dev/bus/ -R
rosdep-all

$@
