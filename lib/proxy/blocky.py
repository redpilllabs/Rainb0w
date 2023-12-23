from base.config import TLS_CERTS_DIR
from rich import print
from utils.domain_utils import get_cert_dir
from utils.helper import load_yaml, save_yaml


def config_doh_dot(doh_dot_domain: str, blocky_config_file: str):
    print("Configuring Blocky...")
    blocky_conf = load_yaml(blocky_config_file)

    blocky_conf["ports"]["https"] = 4343
    blocky_conf["ports"]["tls"] = 853
    blocky_conf["minTlsServeVersion"] = 1.3
    blocky_conf[
        "certFile"
    ] = f"{TLS_CERTS_DIR}/{get_cert_dir(doh_dot_domain)}/{get_cert_dir(doh_dot_domain)}.crt"
    blocky_conf[
        "keyFile"
    ] = f"{TLS_CERTS_DIR}/{get_cert_dir(doh_dot_domain)}/{get_cert_dir(doh_dot_domain)}.key"

    save_yaml(blocky_conf, blocky_config_file)


def enable_porn_dns_blocking(blocky_conf_file):
    print("[bold green]>> Block Porn by DNS")
    blocky_conf = load_yaml(blocky_conf_file)
    blocky_conf["upstream"]["default"] = ["94.140.14.15", "2a10:50c0::bad1:ff"]
    if "porn" not in blocky_conf["blocking"]["clientGroupsBlock"]["default"]:
        blocky_conf["blocking"]["clientGroupsBlock"]["default"].append("porn")

    save_yaml(blocky_conf, blocky_conf_file)


def disable_porn_dns_blocking(blocky_conf_file):
    print("[bold green]>> Unblock Porn by DNS")
    blocky_conf = load_yaml(blocky_conf_file)
    blocky_conf["upstream"]["default"] = ["94.140.14.14", "2a10:50c0::ad1:ff"]
    if "porn" in blocky_conf["blocking"]["clientGroupsBlock"]["default"]:
        blocky_conf["blocking"]["clientGroupsBlock"]["default"].remove("porn")

    save_yaml(blocky_conf, blocky_conf_file)
