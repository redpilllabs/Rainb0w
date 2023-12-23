#!/usr/bin/env python3

import os

import toml

# Load the TOML file
config_file_handle = open(
    f"{os.path.expanduser('~')}/Rainb0w_Home/rainb0w_config.toml", "r"
)
rainb0w_config = toml.load(config_file_handle)

if rainb0w_config["CLOUDFLARE"]["IS_FREE_TLD"]:
    print("True")
else:
    print("False")

config_file_handle.close()
