from random import randint

from base.config import TLS_CERTS_DIR
from utils.domain_utils import get_cert_dir
from utils.helper import gen_random_string, load_json, load_yaml, save_json, save_yaml


def hysteria_gen_params() -> dict:
    # Open a random range of 1k ports for port hopping
    port_range_start = randint(10000, 64000)
    port_range_end = port_range_start + 1024
    hysteria_params = {
        "type": "HYSTERIA",
        "dst_port": 8443,
        "port_range_start": port_range_start,
        "port_range_end": port_range_end,
        "obfs": gen_random_string(randint(8, 12)),
    }
    return hysteria_params


def hysteria_insert_params(
    obfs: str, direct_conn_domain: str, main_domain: str, hysteria_config_file: str
):
    print("Configuring Hysteria...")
    hysteria_config = load_yaml(hysteria_config_file)

    hysteria_config['obfs'] = {'type': 'salamander', 'salamander': {'password': obfs}}
    hysteria_config["tls"][
        "cert"
    ] = f"{TLS_CERTS_DIR}/{get_cert_dir(direct_conn_domain)}/{get_cert_dir(direct_conn_domain)}.crt"
    hysteria_config["tls"][
        "key"
    ] = f"{TLS_CERTS_DIR}/{get_cert_dir(direct_conn_domain)}/{get_cert_dir(direct_conn_domain)}.key"

    hysteria_config["masquerade"]["proxy"]["url"] = f"https://{main_domain}"

    save_yaml(hysteria_config, hysteria_config_file)


def hysteria_add_user(user_info: dict, hysteria_config_file: str):
    hysteria_config = load_yaml(hysteria_config_file)
    if hysteria_config['auth']['userpass']:
        hysteria_config['auth']['userpass'][user_info["name"]] = user_info["password"]
    else:
        hysteria_config['auth']['userpass'] = {user_info["name"]: user_info["password"]}

    save_yaml(hysteria_config, hysteria_config_file)


def hysteria_remove_user(user_info: dict, hysteria_config_file: str):
    hysteria_config = load_yaml(hysteria_config_file)
    user_found = hysteria_config["auth"]['userpass'].get(user_info["name"])
    if user_found:
        del hysteria_config["auth"]['userpass'][user_info["name"]]

    save_yaml(hysteria_config, hysteria_config_file)
