#!/bin/bash

echo "==============================================="
echo "Isaac ROS Installation Script for x86 Systems"
echo "==============================================="
echo ""

echo "Step 1: Installing Docker..."
echo "----------------------------"
echo "Adding Docker's official GPG key for package verification..."
sudo apt-get update
sudo apt-get install ca-certificates curl

echo "Creating directory for Docker keyring..."
sudo install -m 0755 -d /etc/apt/keyrings

echo "Downloading and installing Docker's GPG key..."
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "Adding Docker repository to package sources..."
echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" |
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

echo "Updating package list with Docker repository..."
sudo apt-get update

echo "Installing Docker Engine and related components..."
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Docker installation completed!"
echo ""

echo "Step 2: Setting up GPU drivers..."
echo "--------------------------------"
echo "Installing and updating NVIDIA GPU drivers..."
sudo ubuntu-drivers install

echo "GPU drivers installation completed!"
echo ""

echo "Step 3: Installing NVIDIA Container Toolkit..."
echo "----------------------------------------------"
echo "Adding NVIDIA Container Toolkit repository..."
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg &&
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list |
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' |
                sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

echo "Updating package list with NVIDIA Container Toolkit repository..."
sudo apt-get update

echo "Installing NVIDIA Container Toolkit (version 1.17.8-1)..."
export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.17.8-1
sudo apt-get install -y \
        nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
        nvidia-container-toolkit-base=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
        libnvidia-container-tools=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
        libnvidia-container1=${NVIDIA_CONTAINER_TOOLKIT_VERSION}

echo "NVIDIA Container Toolkit installation completed!"
echo ""

echo "Step 4: Configuring Docker for GPU support..."
echo "--------------------------------------------"
echo "Configuring NVIDIA Container Toolkit runtime for Docker..."
sudo nvidia-ctk runtime configure --runtime=docker

echo "Restarting Docker service to apply configuration changes..."
sudo systemctl restart docker

echo ""
echo "==============================================="
echo "Isaac ROS setup completed successfully!"
echo "==============================================="
echo ""
