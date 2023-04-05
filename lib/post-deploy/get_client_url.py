#!/usr/bin/env python3

import sys

import toml
from rich import print

config_file_handle = open(sys.argv[1], "r")
users_file_handle = open(sys.argv[2], "r")

rainb0w_config = toml.load(config_file_handle)
rainb0w_users = toml.load(users_file_handle)
rainb0w_users = rainb0w_users["users"]
main_domain = rainb0w_config["DOMAINS"]["MAIN_DOMAIN"]

if rainb0w_users:
    for user in rainb0w_users:
        if user["name"] == sys.argv[3]:
            print(
                f"""\n
Get your proxy share links from the protected page below:

URL:       [bold blue]https://{main_domain}/{user['share_url_file']}[/bold blue]
Username: [bold green]{sys.argv[3]}[/bold green]
Password: [bold green]{user['share_url_password']}[/bold green]


[bold yellow]NOTE: DO NOT SHARE THESE INFORMATION OVER SMS,
USE EMAILS OR OTHER SECURE WAYS OF COMMUNICATION INSTEAD!""".lstrip()
            )

config_file_handle.close()
users_file_handle.close()
