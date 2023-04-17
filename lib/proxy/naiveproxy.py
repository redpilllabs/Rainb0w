from utils.helper import load_json, save_json


def naiveproxy_add_user(user_info: dict, caddy_config_file: str):
    caddy_config = load_json(caddy_config_file)
    user_object = {
        "auth_pass_deprecated": user_info["password"],
        "auth_user_deprecated": user_info["name"],
        "handler": "forward_proxy",
        "hide_ip": True,
        "hide_via": True,
        "probe_resistance": {},
    }
    caddy_config["apps"]["http"]["servers"]["web-secure"]["routes"][0]["handle"][0][
        "routes"
    ][-1]["handle"].insert(0, user_object)

    save_json(caddy_config, caddy_config_file)


def naiveproxy_remove_user(user_info: dict, caddy_config_file: str):
    caddy_config = load_json(caddy_config_file)
    naive_users = caddy_config["apps"]["http"]["servers"]["web-secure"]["routes"][0][
        "handle"
    ][0]["routes"][-1]["handle"]
    naive_users = [item for item in naive_users if "auth_user_deprecated" in item]
    user_object = next(
        (
            item
            for item in naive_users
            if item["auth_user_deprecated"] == user_info["name"]
        )
    )
    if user_object:
        naive_users = caddy_config["apps"]["http"]["servers"]["web-secure"]["routes"][
            0
        ]["handle"][0]["routes"][-1]["handle"].remove(user_object)
        save_json(caddy_config, caddy_config_file)
