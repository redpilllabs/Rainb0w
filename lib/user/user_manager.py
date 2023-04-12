import os
from os import urandom
from random import randint
from uuid import uuid4

from proxy.caddy import (
    caddy_add_naiveproxy_user,
    caddy_add_share_page,
    caddy_remove_naiveproxy_user,
)
from proxy.hysteria import hysteria_add_user, hysteria_remove_user
from proxy.mtproto import mtprotopy_gen_share_url
from proxy.xray import xray_add_user, xray_remove_user
from rich import print
from utils.helper import (
    base64_encode,
    bytes_to_raw_str,
    gen_random_string,
    load_toml,
    save_toml,
)


def create_share_urls_file(
    user_info: dict,
    rainb0w_config_file: str,
):
    from base.config import CLIENTS_SHARE_URLS_DIR

    if not os.path.exists(CLIENTS_SHARE_URLS_DIR):
        os.makedirs(CLIENTS_SHARE_URLS_DIR)

    rainb0w_config = load_toml(rainb0w_config_file)
    domains = rainb0w_config["DOMAINS"]
    options = rainb0w_config["DEPLOYMENT"]
    proxies = rainb0w_config["PROXY"]
    with open(f"{CLIENTS_SHARE_URLS_DIR}/{user_info['share_url_file']}", "w") as file:
        file.write("\n\n" + "*" * 40)
        file.write("\n              Naive Proxy\n")
        file.write("*" * 40 + "\n\n")
        file.write(
            f"""
Server:     {domains['MAIN_DOMAIN']}
Port:       443
Username:   {user_info['name']}
Password:   {user_info['password']}
Protocol:   HTTPS
SNI:        {domains['MAIN_DOMAIN']}
                    """
        )

        if options["XRAY"]:
            file.write("\n\n" + "*" * 40)
            file.write("\n              Xray/v2ray\n")
            file.write("*" * 40 + "\n\n")
            # VLESS TCP
            file.write(
                f"vless://{user_info['uuid']}@{domains['DIRECT_CONN_DOMAIN']}:443?security=tls&encryption=none&headerType=none&type=tcp&flow=xtls-rprx-vision-udp443&fp=chrome&sni={domains['DIRECT_CONN_DOMAIN']}#VLESS+TCP\n\n"
            )

            # VLESS Websocket
            proxy_config = next(
                (item for item in proxies if item["type"] == "VLESS_WS")
            )
            file.write(
                f"vless://{user_info['uuid']}@{domains['CDN_COMPAT_DOMAIN']}:443?path={proxy_config['path']}&security=tls&encryption=none&alpn=http/1.1&host={proxy_config['host']}&type=ws&fp=chrome&sni={domains['CDN_COMPAT_DOMAIN']}#VLESS+Websocket\n\n"
            )

            # VLESS gRPC
            proxy_config = next(
                (item for item in proxies if item["type"] == "VLESS_GRPC")
            )
            file.write(
                f"vless://{user_info['uuid']}@{domains['CDN_COMPAT_DOMAIN']}:443?mode=gun&security=tls&encryption=none&alpn=h2,http/1.1&type=grpc&serviceName={proxy_config['svc_name']}&fp=chrome&sni={domains['CDN_COMPAT_DOMAIN']}#VLESS+gRPC\n\n"
            )

            # VMESS HTTP2
            proxy_config = next(
                (item for item in proxies if item["type"] == "VMESS_HTTP")
            )
            vmess_object = {
                "add": domains["MAIN_DOMAIN"],
                "aid": "0",
                "alpn": "h2,http/1.1",
                "fp": "edge",
                "host": domains["MAIN_DOMAIN"],
                "id": user_info["uuid"],
                "net": "h2",
                "path": proxy_config["path"],
                "port": "443",
                "ps": "VMESS+HTTP",
                "scy": "none",
                "sni": domains["MAIN_DOMAIN"],
                "tls": "tls",
                "type": "",
                "v": "2",
            }
            vmess_object = base64_encode(vmess_object)
            vmess_object = bytes_to_raw_str(vmess_object)
            file.write(f"vmess://{vmess_object}\n\n")

            # VMESS Websocket
            proxy_config = next(
                (item for item in proxies if item["type"] == "VMESS_WS")
            )
            vmess_object = {
                "add": domains["CDN_COMPAT_DOMAIN"],
                "aid": "0",
                "alpn": "http/1.1",
                "fp": "edge",
                "host": domains["CDN_COMPAT_DOMAIN"],
                "id": user_info["uuid"],
                "net": "ws",
                "path": proxy_config["path"],
                "port": "443",
                "ps": "VMESS+Websocket",
                "scy": "none",
                "sni": domains["CDN_COMPAT_DOMAIN"],
                "tls": "tls",
                "type": "",
                "v": "2",
            }
            vmess_object = base64_encode(vmess_object)
            vmess_object = bytes_to_raw_str(vmess_object)
            file.write(f"vmess://{vmess_object}\n\n")

            # VMESS gRPC
            proxy_config = next(
                (item for item in proxies if item["type"] == "VMESS_GRPC")
            )
            vmess_object = {
                "add": domains["CDN_COMPAT_DOMAIN"],
                "aid": "0",
                "alpn": "h2,http/1.1",
                "fp": "edge",
                "host": "",
                "id": user_info["uuid"],
                "net": "grpc",
                "path": proxy_config["svc_name"],
                "port": "443",
                "ps": "VMESS+gRPC",
                "scy": "none",
                "sni": domains["CDN_COMPAT_DOMAIN"],
                "tls": "tls",
                "type": "gun",
                "v": "2",
            }
            vmess_object = base64_encode(vmess_object)
            vmess_object = bytes_to_raw_str(vmess_object)
            file.write(f"vmess://{vmess_object}\n\n")

            # Trojan HTTP2
            proxy_config = next(
                (item for item in proxies if item["type"] == "TROJAN_HTTP")
            )
            file.write(
                f"trojan://{user_info['password']}@{domains['MAIN_DOMAIN']}:443?path={proxy_config['path']}&security=tls&alpn=h2,http/1.1&host={domains['MAIN_DOMAIN']}&fp=chrome&type=http&sni={domains['MAIN_DOMAIN']}#Trojan+HTTP2\n\n"
            )

            # Trojan TCP
            file.write(
                f"trojan://{user_info['password']}@{domains['DIRECT_CONN_DOMAIN']}:443?security=tls&headerType=none&fp=android&type=tcp&sni={domains['DIRECT_CONN_DOMAIN']}#Trojan+TCP\n\n"
            )

            # Trojan Websocket
            proxy_config = next(
                (item for item in proxies if item["type"] == "TROJAN_WS")
            )
            file.write(
                f"trojan://{user_info['password']}@{domains['CDN_COMPAT_DOMAIN']}:443?security=tls&alpn=http/1.1&host={proxy_config['host']}&fp=android&type=ws&sni={domains['CDN_COMPAT_DOMAIN']}#Trojan+Websocket\n\n"
            )

            # Trojan gRPC
            proxy_config = next(
                (item for item in proxies if item["type"] == "TROJAN_GRPC")
            )
            file.write(
                f"trojan://{user_info['password']}@{domains['CDN_COMPAT_DOMAIN']}:443?mode=gun&security=tls&alpn=h2,http/1.1&fp=android&type=grpc&serviceName={proxy_config['svc_name']}&sni={domains['CDN_COMPAT_DOMAIN']}#Trojan+gRPC\n\n"
            )

        if options["HYSTERIA"]:
            proxy_config = next(
                item for item in rainb0w_config["PROXY"] if item["type"] == "HYSTERIA"
            )
            file.write("\n\n" + "*" * 40)
            file.write("\n              Hysteria\n")
            file.write("*" * 40 + "\n\n")
            file.write(
                f"""
    For port-hopping connection, configure Matsuri as the following:
Server:         {rainb0w_config['DOMAINS']['DIRECT_CONN_DOMAIN']}:{proxy_config['port_range_start']}-{proxy_config['port_range_end']}
Port:           Empty
Protocol:       UDP
Obfuscation:    {proxy_config['obfs']}
Auth. Type:     STRING
Payload:        {user_info['password']}

        ===================

    For single-port connection, configure Matsuri as the following:
Server:         {rainb0w_config['DOMAINS']['DIRECT_CONN_DOMAIN']}
Port:           Any number between the range[{proxy_config['port_range_start']}-{proxy_config['port_range_end']}]
Protocol:       UDP
Obfuscation:    {proxy_config['obfs']}
Auth. Type:     STRING
Payload:        {user_info['password']}

NOTE: Remember to set the correct values for 'Upload' and 'Download' according to
your real connection speed! Hysteria adjusts the parameters according to these values
for optimal connection speeds.

    """.lstrip()
            )

        if options["MTPROTOPY"]:
            file.write("\n\n" + "*" * 40)
            file.write("\n              MTProto\n")
            file.write("*" * 40 + "\n\n")
            mtproto_urls = mtprotopy_gen_share_url(
                user_info["secret"],
                rainb0w_config["DOMAINS"]["DIRECT_CONN_DOMAIN"],
                rainb0w_config["DOMAINS"]["MTPROTO_DOMAIN"],
            )
            file.write(f"MTProto Share URL:     {mtproto_urls['tg_faketls_url']}\n")
            file.write(f"HTTPS Share URL:       {mtproto_urls['https_faketls_url']}")

        if options["DOT_DOH"]:
            file.write("\n\n" + "*" * 40)
            file.write("\n              DNS-over-HTTPS/TLS\n")
            file.write("*" * 40 + "\n\n")
            file.write(
                f"https://{rainb0w_config['DOMAINS']['DOT_DOH_DOMAIN']}/dns-query\n"
            )
            file.write(f"tls://{rainb0w_config['DOMAINS']['DOT_DOH_DOMAIN']}\n")
            file.write(
                """
NOTE: When using these as your DNS server, [.ir] and [.cn] ccTLDs
will not resolve, therefore if you're using a [.ir] domain for your server
you should not set these as the DNS resolver BEFORE your client app, such as
your device! But only set them inside the client application."""
            )


def get_users(rainb0w_users_file: str) -> list:
    rainb0w_users = load_toml(rainb0w_users_file)
    if "users" in rainb0w_users:
        return rainb0w_users["users"]
    else:
        rainb0w_users["users"] = []
        return rainb0w_users["users"]


def save_users(users: list, users_toml_file: str):
    """
    This is just a wrapper function to be consistent with 'get_users'
    """
    save_toml({"users": users}, users_toml_file)


def create_new_user(username: str):
    print(f"Adding '{username}' as a new user...")
    password = gen_random_string(randint(8, 12))
    uuid = str(uuid4())
    secret = urandom(16).hex()

    share_url_file = f"{gen_random_string(randint(5, 10))}.txt"
    share_url_password = gen_random_string(5)
    user_info = {
        "name": username,
        "password": password,
        "uuid": uuid,
        "secret": secret,
        "share_url_file": share_url_file,
        "share_url_password": share_url_password,
    }
    return user_info


def add_user_to_proxies(
    user_info: dict,
    rainb0w_config_file: str,
    rainb0w_users_file: str,
    caddy_config_file: str,
    xray_config_file: str,
    hysteria_config_file: str,
):
    rainb0w_config = load_toml(rainb0w_config_file)

    # Create a file to include all the share urls for the installed proxies
    create_share_urls_file(user_info, rainb0w_config_file)

    # Add a basic auth entry for the specified file as the path [domain/filename.txt]
    caddy_add_share_page(
        user_info,
        caddy_config_file,
    )

    # Add user to NaiveProxy
    caddy_add_naiveproxy_user(user_info, caddy_config_file)

    if rainb0w_config["DEPLOYMENT"]["XRAY"]:
        xray_add_user(user_info, xray_config_file)

    if rainb0w_config["DEPLOYMENT"]["HYSTERIA"]:
        hysteria_add_user(user_info, hysteria_config_file)

    rainb0w_users = get_users(rainb0w_users_file)
    rainb0w_users.append(user_info)
    save_users(rainb0w_users, rainb0w_users_file)


def remove_user(
    username: str,
    rainb0w_config_file: str,
    rainb0w_users_file: str,
    caddy_config_file: str,
    xray_config_file: str,
    hysteria_config_file: str,
):
    rainb0w_config = load_toml(rainb0w_config_file)
    rainb0w_users = get_users(rainb0w_users_file)
    if rainb0w_users:
        for user in rainb0w_users:
            if user["name"] == username:
                print(f"Removing the user '{username}'...")
                if rainb0w_config["DEPLOYMENT"]["XRAY"]:
                    xray_remove_user(user, xray_config_file)
                if rainb0w_config["DEPLOYMENT"]["HYSTERIA"]:
                    hysteria_remove_user(user, hysteria_config_file)
                caddy_remove_naiveproxy_user(user, caddy_config_file)
                rainb0w_users.remove(user)

        save_users(rainb0w_users, rainb0w_users_file)


def print_client_info(username: str, rainb0w_config_file: str, rainb0w_users_file: str):
    rainb0w_config = load_toml(rainb0w_config_file)
    rainb0w_users = get_users(rainb0w_users_file)
    main_domain = rainb0w_config["DOMAINS"]["MAIN_DOMAIN"]
    if rainb0w_users:
        for user in rainb0w_users:
            if user["name"] == username:
                print(
                    f"""\nYou can get share urls for '{username}' at the following URL:

                URL:        [bold blue]https://{main_domain}/{user['share_url_file']}[/bold blue]
                Username:   [bold green]{username}[/bold green]
                Password:   [bold green]{user['share_url_password']}[/bold green]

                [bold yellow]NOTE: DO NOT SHARE THESE INFORMATION OVER SMS,
                USE EMAILS OR OTHER SECURE WAYS OF COMMUNICATION INSTEAD![/bold yellow]""".lstrip()
                )


def prompt_username():
    username = input("\nEnter a username for your first user: ")
    while not username:
        print("\nInvalid username!")
        username = input("Enter a username for your first user: ")

    return username
