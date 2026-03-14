# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" |
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update

# Install Docker
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

TARGET_USER="${SUDO_USER:-$USER}"

# Add user to docker group
sudo usermod -aG docker "$TARGET_USER"
# Apply docker group membership on next login shell.
# newgrp does not work in scripts, so we just print a reminder for the user to log out/in or run newgrp manually.
echo "Docker group updated for $TARGET_USER. Log out/in (or run: newgrp docker) after this script finishes."

# Update drivers for GPU
sudo ubuntu-drivers install

# Install nvidia-container-toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg &&
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list |
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' |
                sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update

export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.17.8-1
sudo apt-get install -y \
        nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
        nvidia-container-toolkit-base=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
        libnvidia-container-tools=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
        libnvidia-container1=${NVIDIA_CONTAINER_TOOLKIT_VERSION}

# Configure nvidia-container-toolkit for Docker
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Restart Docker
sudo systemctl daemon-reload && sudo systemctl restart docker

# Install Git LFS
sudo apt-get install git-lfs
git lfs install --skip-repo

# Create workspace
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
TARGET_BASHRC="$TARGET_HOME/.bashrc"
EXPORT_LINE='export ISAAC_ROS_WS=$HOME/workspaces/isaac_ros-dev/'

mkdir -p "$TARGET_HOME/workspaces/isaac_ros-dev/src"
touch "$TARGET_BASHRC"

if ! grep -qxF "$EXPORT_LINE" "$TARGET_BASHRC"; then
        echo "$EXPORT_LINE" >>"$TARGET_BASHRC"
        echo "Added ISAAC_ROS_WS to $TARGET_BASHRC"
else
        echo "ISAAC_ROS_WS already present in $TARGET_BASHRC"
fi

# Export for the script runtime; open a new shell or source .bashrc manually for interactive use.
export ISAAC_ROS_WS="$TARGET_HOME/workspaces/isaac_ros-dev/"
echo "Run: source $TARGET_BASHRC"
