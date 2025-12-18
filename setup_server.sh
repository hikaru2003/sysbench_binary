#!/bin/bash

# Create commands to execute at startup
# 1. Disable Turbo Boost (for Intel P-state driver)
# 2. apt update
# 3. Install packages

INSTALL_PACKAGES="build-essential git htop"
GIT_REPO_URL="https://github.com/hikaru2003/sysbench_binary.git"

# set -e
# Debug mode
set -x

# Redirect output to startup.log and stderr
exec > >(tee -a startup.log) 2>&1
echo "=== Startup script started ==="

# Disable Turbo Boost
echo "Disabling Turbo Boost..."
if [ -e /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
    echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo
    echo "Turbo Boost disabled."
else
    echo "Intel pstate not found, skipping Turbo Boost disable."
fi

# Install Libraries
echo "Installing packages..."
DEBIAN_FRONTEND=noninteractive apt update
DEBIAN_FRONTEND=noninteractive apt install -y ${INSTALL_PACKAGES}

# Clone experiment repository
echo "Cloning experiment repository..."
USER_HOME=/users/Morisaki
cd $USER_HOME
git clone ${GIT_REPO_URL}

# Change ownership of the repository to the user
USER_NAME=Morisaki
chown -R $USER_NAME:$USER_NAME $(basename ${GIT_REPO_URL} .git)

echo "=== Startup script completed ==="
