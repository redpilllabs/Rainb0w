#!/bin/bash

# Platform
DISTRO=$(awk -F= '/^NAME/{print $2}' /etc/os-release)

# Path
DOCKER_SRC_DIR=$HOME/Docker
