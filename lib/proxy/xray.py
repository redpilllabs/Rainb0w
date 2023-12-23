from random import randint

from base.config import TLS_CERTS_DIR
from utils.domain_utils import get_cert_dir
from utils.helper import gen_random_string, load_json, save_json


def xray_add_user(user_info: dict, xray_config_file: str):
    config = load_json(xray_config_file)
    for inbound in config["inbounds"]:
        if inbound["protocol"] == "vless":
            if inbound["streamSettings"]["network"] == "tcp":
                new_client = {
                    "email": user_info["name"],
                    "id": user_info["uuid"],
                    "flow": "xtls-rprx-vision",
                    "level": 0,
                }
            else:
                new_client = {
                    "email": user_info["name"],
                    "id": user_info["uuid"],
                    "level": 0,
                }
            inbound["settings"]["clients"].append(new_client)
        elif inbound["protocol"] == "vmess":
            new_client = {
                "email": user_info["name"],
                "id": user_info["uuid"],
                "level": 0,
            }
            inbound["settings"]["clients"].append(new_client)
        elif inbound["protocol"] == "trojan":
            new_client = {"email": user_info["name"], "password": user_info["password"]}
            inbound["settings"]["clients"].append(new_client)
        else:
            pass

    save_json(config, xray_config_file)


def xray_remove_user(user_info: dict, xray_config_file: str):
    config = load_json(xray_config_file)
    for inbound in config["inbounds"]:
        if "clients" in inbound["settings"]:
            for client in inbound["settings"]["clients"]:
                if client["email"] == user_info["name"]:
                    inbound["settings"]["clients"].remove(client)

    save_json(config, xray_config_file)


def xray_insert_cert_path(direct_conn_subdomain: str, xray_config_file: str):
    config = load_json(xray_config_file)
    config["inbounds"][1]["streamSettings"]["tlsSettings"]["certificates"].append(
        {
            "ocspStapling": 3600,
            "certificateFile": f"{TLS_CERTS_DIR}/{get_cert_dir(direct_conn_subdomain)}/{get_cert_dir(direct_conn_subdomain)}.crt",
            "keyFile": f"{TLS_CERTS_DIR}/{get_cert_dir(direct_conn_subdomain)}/{get_cert_dir(direct_conn_subdomain)}.key",
        }
    )

    save_json(config, xray_config_file)


def xray_gen_proxy_params(main_domain: str, cdn_subdomain: str) -> list:
    proxy_params = []
    direct_http_proxies = ["VMESS_HTTP", "TROJAN_HTTP"]
    cdn_ws_proxies = ["VLESS_WS", "VMESS_WS", "TROJAN_WS"]
    cdn_grpc_proxies = ["VLESS_GRPC", "VMESS_GRPC", "TROJAN_GRPC"]

    for proxy in direct_http_proxies:
        proxy_params.append(
            {
                "type": proxy,
                "host": main_domain,
                "path": f"/{gen_random_string(randint(5, 10))}",
            }
        )

    for proxy in cdn_ws_proxies:
        proxy_params.append(
            {
                "type": proxy,
                "host": cdn_subdomain,
                "path": f"/{gen_random_string(randint(5, 10))}",
            }
        )

    for proxy in cdn_grpc_proxies:
        proxy_params.append(
            {
                "type": proxy,
                "svc_name": gen_random_string(randint(5, 10)),
            }
        )

    return proxy_params


def xray_insert_proxy_params(proxy_params: list, xray_config_file: str):
    print("Configuring Xray...")
    xray_config = load_json(xray_config_file)

    for inbound in xray_config["inbounds"]:
        if inbound["tag"] == "VLESS_WS":
            proxy_config = next(
                (item for item in proxy_params if item["type"] == "VLESS_WS")
            )
            inbound["streamSettings"]["wsSettings"]["path"] = proxy_config["path"]
            inbound["streamSettings"]["wsSettings"]["headers"]["Host"] = proxy_config[
                "host"
            ]
        elif inbound["tag"] == "VMESS_WS":
            proxy_config = next(
                (item for item in proxy_params if item["type"] == "VMESS_WS")
            )
            inbound["streamSettings"]["wsSettings"]["path"] = proxy_config["path"]
            inbound["streamSettings"]["wsSettings"]["headers"]["Host"] = proxy_config[
                "host"
            ]
        elif inbound["tag"] == "TROJAN_WS":
            proxy_config = next(
                (item for item in proxy_params if item["type"] == "TROJAN_WS")
            )
            inbound["streamSettings"]["wsSettings"]["path"] = proxy_config["path"]
            inbound["streamSettings"]["wsSettings"]["headers"]["Host"] = proxy_config[
                "host"
            ]
        elif inbound["tag"] == "VLESS_GRPC":
            proxy_config = next(
                (item for item in proxy_params if item["type"] == "VLESS_GRPC")
            )
            inbound["streamSettings"]["grpcSettings"]["serviceName"] = proxy_config[
                "svc_name"
            ]
        elif inbound["tag"] == "VMESS_GRPC":
            proxy_config = next(
                (item for item in proxy_params if item["type"] == "VMESS_GRPC")
            )
            inbound["streamSettings"]["grpcSettings"]["serviceName"] = proxy_config[
                "svc_name"
            ]
        elif inbound["tag"] == "TROJAN_GRPC":
            proxy_config = next(
                (item for item in proxy_params if item["type"] == "TROJAN_GRPC")
            )
            inbound["streamSettings"]["grpcSettings"]["serviceName"] = proxy_config[
                "svc_name"
            ]
        elif inbound["tag"] == "VMESS_HTTP":
            proxy_config = next(
                (item for item in proxy_params if item["type"] == "VMESS_HTTP")
            )
            inbound["streamSettings"]["httpSettings"]["host"] = [proxy_config["host"]]
            inbound["streamSettings"]["httpSettings"]["path"] = proxy_config["path"]
        elif inbound["tag"] == "TROJAN_HTTP":
            proxy_config = next(
                (item for item in proxy_params if item["type"] == "TROJAN_HTTP")
            )
            inbound["streamSettings"]["httpSettings"]["host"] = [proxy_config["host"]]
            inbound["streamSettings"]["httpSettings"]["path"] = proxy_config["path"]
        else:
            pass

    save_json(xray_config, xray_config_file)
