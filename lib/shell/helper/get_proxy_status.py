#!/usr/bin/env python3


import os
import sys

import toml

# Load the TOML file
config_file_handle = open(
    f"{os.path.expanduser('~')}/Rainb0w_Home/rainb0w_config.toml", "r"
)
rainb0w_config = toml.load(config_file_handle)

# sys.argv[1] is representing the proxy type, valid values [xray, hysteria, mtprotopy, dot_doh]

# how to make a string uppercase ?
if rainb0w_config["STATUS"][str(sys.argv[1]).upper()]:
    config_file_handle.close()
    exit(1)
else:
    config_file_handle.close()
    exit(0)
