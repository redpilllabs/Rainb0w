#!/bin/bash
source $PWD/lib/shell/base/colors.sh
source $PWD/lib/shell/docker/docker_utils.sh

# We always have caddy and blocky so no need to check beforehand
fn_restart_docker_container "blocky"
fn_restart_docker_container "caddy"

python3 $PWD/lib/shell/helper/get_proxy_status.py "xray"
PYTHON_EXIT_CODE=$?
if [ $PYTHON_EXIT_CODE -ne 0 ]; then
    fn_restart_docker_container "xray"
fi

python3 $PWD/lib/shell/helper/get_proxy_status.py "hysteria"
PYTHON_EXIT_CODE=$?
if [ $PYTHON_EXIT_CODE -ne 0 ]; then
    fn_restart_docker_container "hysteria"
fi

python3 $PWD/lib/shell/helper/get_proxy_status.py "mtproto"
PYTHON_EXIT_CODE=$?
if [ $PYTHON_EXIT_CODE -ne 0 ]; then
    fn_restart_docker_container "mtprotopy"
fi

echo -e "${B_GREEN}<< Finished applying changes! >>${RESET}"
