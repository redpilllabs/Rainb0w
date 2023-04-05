#!/usr/bin/env python3

import sys

import toml

# Load the TOML file
config_file_handle = open(sys.argv[1], "r")
rainb0w_config = toml.load(config_file_handle)

if rainb0w_config["CLOUDFLARE"]["IS_FREE_TLD"]:
    print("True")
else:
    print("False")

config_file_handle.close()
