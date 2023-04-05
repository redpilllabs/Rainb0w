import urllib.parse

from utils.helper import bytes_to_hex, bytes_to_url_safe_base64, load_toml, save_toml

# MTProtoPy users are loaded directly from 'rainb0w_users.toml'


def mtprotopy_insert_params(mtproto_faketls_domain: str, mtprotopy_config_file: str):
    print("Configuring MTProtoPy...")
    mtprotopy_config = load_toml(mtprotopy_config_file)

    mtprotopy_config["server"]["domain"] = mtproto_faketls_domain
    mtprotopy_config["mtproto"]["mask_host"] = mtproto_faketls_domain
    mtprotopy_config["mtproto"]["sni"] = mtproto_faketls_domain
    save_toml(mtprotopy_config, mtprotopy_config_file)


def mtprotopy_gen_share_url(
    secret: str,
    direct_conn_domain: str,
    mtproto_faketls_domain: str,
    base64_encode=False,
):
    tg_prefix = (
        "tg://" + "proxy?server=" + direct_conn_domain + "&port=443" + "&secret="
    )
    https_prefix = (
        "https://t.me/"
        + "proxy?server="
        + direct_conn_domain
        + "&port=443"
        + "&secret="
    )
    tls_bytes = bytes.fromhex("ee" + secret) + mtproto_faketls_domain.encode()

    if base64_encode:
        base64_faketls = bytes_to_url_safe_base64(tls_bytes)
        return {
            "tg_faketls_url": tg_prefix + base64_faketls,
            "https_faketls_url": https_prefix + base64_faketls,
        }
    else:
        hex_faketls = urllib.parse.quote_plus(bytes_to_hex(tls_bytes))
        return {
            "tg_faketls_url": tg_prefix + hex_faketls,
            "https_faketls_url": https_prefix + hex_faketls,
        }
