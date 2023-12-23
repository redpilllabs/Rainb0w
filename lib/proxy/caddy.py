from utils.domain_utils import extract_domain, is_domain, is_subdomain
from utils.helper import (
    bytes_to_raw_str,
    gen_bcrypt_password,
    get_public_ip,
    load_json,
    save_json,
)


def caddy_insert_params(rainb0w_config: dict, caddy_config_file: str):
    print("Configuring Caddy...")
    caddy_config = load_json(caddy_config_file)

    # Configure TLS reverse proxy
    caddy_config["apps"]["layer4"]["servers"]["tls_proxy"]["routes"][0]["match"][0][
        "tls"
    ]["sni"] = [rainb0w_config["DOMAINS"]["DIRECT_CONN_DOMAIN"]]
    caddy_config["apps"]["layer4"]["servers"]["tls_proxy"]["routes"][1]["match"][0][
        "tls"
    ]["sni"] = [rainb0w_config["DOMAINS"]["CDN_COMPAT_DOMAIN"]]
    caddy_config["apps"]["layer4"]["servers"]["tls_proxy"]["routes"][2]["match"][0][
        "tls"
    ]["sni"] = [rainb0w_config["DOMAINS"]["DOT_DOH_DOMAIN"]]
    caddy_config["apps"]["layer4"]["servers"]["tls_proxy"]["routes"][3]["match"][0][
        "tls"
    ]["sni"] = [rainb0w_config["DOMAINS"]["MTPROTO_DOMAIN"]]
    caddy_config["apps"]["layer4"]["servers"]["tls_proxy"]["routes"][4]["match"][0][
        "tls"
    ]["sni"] = ["", f"{get_public_ip()}"]

    # Configure HTTPS web server and reverse proxy
    caddy_config["apps"]["http"]["servers"]["web-secure"]["routes"][0]["match"][0][
        "host"
    ] = [rainb0w_config["DOMAINS"]["MAIN_DOMAIN"]]
    caddy_config["apps"]["http"]["servers"]["fallback"]["routes"][0]["match"][0][
        "host"
    ] = [rainb0w_config["DOMAINS"]["CDN_COMPAT_DOMAIN"]]

    # Add domains and SNIs for TLS automation
    if rainb0w_config["CLOUDFLARE"]["IS_FREE_TLD"]:
        for _, domain in rainb0w_config["DOMAINS"].items():
            if domain:
                caddy_config["apps"]["http"]["servers"]["web-secure"][
                    "tls_connection_policies"
                ][0]["match"]["sni"].append(domain)
                caddy_config["apps"]["tls"]["certificates"]["automate"].append(domain)
                caddy_config["apps"]["tls"]["automation"]["policies"][0][
                    "subjects"
                ].append(domain)
    else:
        if is_domain(rainb0w_config["DOMAINS"]["MAIN_DOMAIN"]):
            caddy_config["apps"]["http"]["servers"]["web-secure"][
                "tls_connection_policies"
            ][0]["match"]["sni"] = [
                rainb0w_config["DOMAINS"]["MAIN_DOMAIN"],
                f"*.{rainb0w_config['DOMAINS']['MAIN_DOMAIN']}",
            ]
            caddy_config["apps"]["tls"]["certificates"]["automate"] = [
                rainb0w_config["DOMAINS"]["MAIN_DOMAIN"],
                f"*.{rainb0w_config['DOMAINS']['MAIN_DOMAIN']}",
            ]
            caddy_config["apps"]["tls"]["automation"]["policies"][0]["subjects"] = [
                rainb0w_config["DOMAINS"]["MAIN_DOMAIN"],
                f"*.{rainb0w_config['DOMAINS']['MAIN_DOMAIN']}",
            ]
        elif is_subdomain(rainb0w_config["DOMAINS"]["MAIN_DOMAIN"]):
            main_domain = extract_domain(rainb0w_config["DOMAINS"]["MAIN_DOMAIN"])
            caddy_config["apps"]["http"]["servers"]["web-secure"][
                "tls_connection_policies"
            ][0]["match"]["sni"] = [f"*.{main_domain}"]
            caddy_config["apps"]["tls"]["certificates"]["automate"] = [
                f"*.{main_domain}"
            ]
            caddy_config["apps"]["tls"]["automation"]["policies"][0]["subjects"] = [
                f"*.{main_domain}"
            ]

    # Check if we have a paid domain name and
    # the Cloudflare API key and setup accordingly
    if rainb0w_config["CLOUDFLARE"]["IS_FREE_TLD"]:
        caddy_config["apps"]["tls"]["automation"]["policies"][0]["issuers"] = [
            {"module": "acme"}
        ]
    else:
        caddy_config["apps"]["tls"]["automation"]["policies"][0]["issuers"] = [
            {
                "challenges": {
                    "dns": {
                        "provider": {
                            "api_token": rainb0w_config["CLOUDFLARE"]["API_KEY"],
                            "name": "cloudflare",
                        }
                    }
                },
                "module": "acme",
            }
        ]

    # Trojan HTTP2
    proxy_config = next(
        (item for item in rainb0w_config["PROXY"] if item["type"] == "TROJAN_HTTP")
    )
    caddy_config["apps"]["http"]["servers"]["web-secure"]["routes"][0]["handle"][0][
        "routes"
    ][0]["match"][0]["path"] = [proxy_config["path"]]

    # VMESS HTTP2
    proxy_config = next(
        (item for item in rainb0w_config["PROXY"] if item["type"] == "VMESS_HTTP")
    )
    caddy_config["apps"]["http"]["servers"]["web-secure"]["routes"][0]["handle"][0][
        "routes"
    ][1]["match"][0]["path"] = [proxy_config["path"]]

    # VLESS WS
    proxy_config = next(
        (item for item in rainb0w_config["PROXY"] if item["type"] == "VLESS_WS")
    )
    caddy_config["apps"]["http"]["servers"]["fallback"]["routes"][0]["handle"][0][
        "routes"
    ][0]["match"][0]["path"] = [proxy_config["path"]]

    # VMESS WS
    proxy_config = next(
        (item for item in rainb0w_config["PROXY"] if item["type"] == "VMESS_WS")
    )
    caddy_config["apps"]["http"]["servers"]["fallback"]["routes"][0]["handle"][0][
        "routes"
    ][1]["match"][0]["path"] = [proxy_config["path"]]

    # Trojan WS
    proxy_config = next(
        (item for item in rainb0w_config["PROXY"] if item["type"] == "TROJAN_WS")
    )
    caddy_config["apps"]["http"]["servers"]["fallback"]["routes"][0]["handle"][0][
        "routes"
    ][2]["match"][0]["path"] = [proxy_config["path"]]

    # VLESS gRPC
    proxy_config = next(
        (item for item in rainb0w_config["PROXY"] if item["type"] == "VLESS_GRPC")
    )
    caddy_config["apps"]["http"]["servers"]["fallback"]["routes"][0]["handle"][0][
        "routes"
    ][3]["match"][0]["path"] = [f"/{proxy_config['svc_name']}/*"]

    # VMESS gRPC
    proxy_config = next(
        (item for item in rainb0w_config["PROXY"] if item["type"] == "VMESS_GRPC")
    )
    caddy_config["apps"]["http"]["servers"]["fallback"]["routes"][0]["handle"][0][
        "routes"
    ][4]["match"][0]["path"] = [f"/{proxy_config['svc_name']}/*"]

    # Trojan gRPC
    proxy_config = next(
        (item for item in rainb0w_config["PROXY"] if item["type"] == "TROJAN_GRPC")
    )
    caddy_config["apps"]["http"]["servers"]["fallback"]["routes"][0]["handle"][0][
        "routes"
    ][5]["match"][0]["path"] = [f"/{proxy_config['svc_name']}/*"]

    save_json(caddy_config, caddy_config_file)


def caddy_add_share_page(
    user_info: dict,
    caddy_config_file: str,
):
    caddy_config = load_json(caddy_config_file)
    hashed_password = gen_bcrypt_password(user_info["share_url_password"])
    hashed_password = bytes_to_raw_str(hashed_password)
    auth_object = {
        "match": [{"path": [f"/{user_info['share_url_file']}"]}],
        "handle": [
            {
                "handler": "authentication",
                "providers": {
                    "http_basic": {
                        "accounts": [
                            {
                                "password": hashed_password,
                                "username": user_info["name"],
                            }
                        ],
                        "hash": {"algorithm": "bcrypt"},
                        "hash_cache": {},
                    }
                },
            },
            {"handler": "file_server", "root": "/var/www/clients"},
        ],
    }

    caddy_config["apps"]["http"]["servers"]["web-secure"]["routes"][0]["handle"][0][
        "routes"
    ].insert(-1, auth_object)

    save_json(caddy_config, caddy_config_file)


def caddy_remove_share_page(username: str, caddy_config_file: str):
    caddy_config = load_json(caddy_config_file)
    pages = caddy_config["apps"]["http"]["servers"]["web-secure"]["routes"][0][
        "handle"
    ][0]["routes"]
    page_entry = next(
        (
            item
            for item in pages
            if item["handle"][0]["providers"]["http_basic"]["accounts"][0]["username"]
            == username
        )
    )
    if page_entry:
        caddy_config["apps"]["http"]["servers"]["web-secure"]["routes"][0]["handle"][0][
            "routes"
        ].remove(page_entry)
        save_json(caddy_config, caddy_config_file)
