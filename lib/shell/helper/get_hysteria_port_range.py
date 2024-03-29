#!/usr/bin/env python3

import os

import toml

# Load the TOML file
config_file_handle = open(
    f"{os.path.expanduser('~')}/Rainb0w_Home/rainb0w_config.toml", "r"
)
rainb0w_config = toml.load(config_file_handle)

hysteria_params = next(
    (item for item in rainb0w_config["PROXY"] if item["type"] == "HYSTERIA")
)

# Print the values
print("Range Start: " + str(hysteria_params["port_range_start"]))
print("Range End: " + str(hysteria_params["port_range_end"]))

config_file_handle.close()
