from random import randint

from base.config import TLS_CERTS_DIR
from utils.domain_utils import get_cert_dir
from utils.helper import gen_random_string, load_json, save_json


def hysteria_gen_params() -> dict:
    # Open a random range of 1k ports for port hopping
    port_range_start = randint(10000, 64000)
    port_range_end = port_range_start + 1024
    hysteria_params = {
        "type": "HYSTERIA",
        "dst_port": 4443,  # This port will be available internally only
        "port_range_start": port_range_start,
        "port_range_end": port_range_end,
        "obfs": gen_random_string(randint(8, 12)),
    }
    return hysteria_params


def hysteria_insert_params(
    obfs: str, direct_conn_domain: str, hysteria_config_file: str
):
    print("Configuring Hysteria...")
    hysteria_config = load_json(hysteria_config_file)
    hysteria_config["listen"] = ":4443"
    hysteria_config["obfs"] = obfs
    hysteria_config[
        "cert"
    ] = f"{TLS_CERTS_DIR}/{get_cert_dir(direct_conn_domain)}/{get_cert_dir(direct_conn_domain)}.crt"
    hysteria_config[
        "key"
    ] = f"{TLS_CERTS_DIR}/{get_cert_dir(direct_conn_domain)}/{get_cert_dir(direct_conn_domain)}.key"

    save_json(hysteria_config, hysteria_config_file)


def hysteria_add_user(user_info: dict, hysteria_config_file: str):
    hysteria_config = load_json(hysteria_config_file)
    hysteria_config["auth"]["config"].append(user_info["password"])

    save_json(hysteria_config, hysteria_config_file)


def hysteria_remove_user(user_info: dict, hysteria_config_file: str):
    hysteria_config = load_json(hysteria_config_file)
    for item in hysteria_config["auth"]["config"]:
        if item == user_info["password"]:
            hysteria_config["auth"]["config"].remove(item)

    save_json(hysteria_config, hysteria_config_file)
