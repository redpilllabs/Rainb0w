#!/usr/bin/env python3

import os
import shutil
import signal
import sys

from pick import pick

from base.config import (
    BLOCKY_CONFIG_FILE,
    CADDY_CONFIG_FILE,
    HYSTERIA_CONFIG_FILE,
    MTPROTOPY_CONFIG_FILE,
    RAINB0W_BACKUP_DIR,
    RAINB0W_CONFIG_FILE,
    RAINB0W_HOME_DIR,
    RAINB0W_USERS_FILE,
    XRAY_CONFIG_FILE,
)
from proxy.blocky import config_doh_dot
from proxy.caddy import caddy_insert_params
from proxy.hysteria import hysteria_gen_params, hysteria_insert_params
from proxy.mtproto import mtprotopy_insert_params
from proxy.xray import (
    xray_gen_proxy_params,
    xray_insert_cert_path,
    xray_insert_proxy_params,
)
from user.user_manager import add_user_to_proxies, create_new_user, prompt_username
from utils.domain_utils import (
    is_free_domain,
    prompt_cdn_domain,
    prompt_cloudflare_api_key,
    prompt_direct_conn_domain,
    prompt_dohdot_domain,
    prompt_main_domain,
    prompt_mtproto_domain,
)
from utils.helper import (
    gen_random_string,
    load_toml,
    print_txt_file,
    progress_indicator,
    prompt_clear_screen,
    remove_dir,
    save_toml,
)
from utils.wp_utils import wp_insert_params


def apply_config(username=None):
    rainb0w_config = load_toml(RAINB0W_CONFIG_FILE)
    rainb0w_users = load_toml(RAINB0W_USERS_FILE)

    if rainb0w_config["STATUS"]["XRAY"]:
        xray_insert_proxy_params(rainb0w_config["PROXY"], XRAY_CONFIG_FILE)
        xray_insert_cert_path(
            rainb0w_config["DOMAINS"]["DIRECT_CONN_DOMAIN"], XRAY_CONFIG_FILE
        )

    if rainb0w_config["STATUS"]["HYSTERIA"]:
        hysteria_config = next(
            (item for item in rainb0w_config["PROXY"] if item["type"] == "HYSTERIA")
        )
        hysteria_insert_params(
            hysteria_config["obfs"],
            rainb0w_config["DOMAINS"]["DIRECT_CONN_DOMAIN"],
            rainb0w_config["DOMAINS"]["MAIN_DOMAIN"],
            HYSTERIA_CONFIG_FILE,
        )

    if rainb0w_config["STATUS"]["MTPROTOPY"]:
        mtprotopy_insert_params(
            rainb0w_config["DOMAINS"]["MTPROTO_DOMAIN"],
            MTPROTOPY_CONFIG_FILE,
        )

    if rainb0w_config["STATUS"]["DOT_DOH"]:
        config_doh_dot(rainb0w_config["DOMAINS"]["DOT_DOH_DOMAIN"], BLOCKY_CONFIG_FILE)

    # NOTE: NaiveProxy does not need any configuration other than user addition
    #  which is handled by the 'add_user_to_proxies' function

    # WordPress
    wp_insert_params(
        rainb0w_config["DOMAINS"]["MAIN_DOMAIN"],
        "My WordPress Blog",
        gen_random_string(12),
        gen_random_string(12),
        f"{RAINB0W_HOME_DIR}/wordpress/wp.env",
        f"{RAINB0W_HOME_DIR}/wordpress/db.env",
    )

    # Configure Caddy
    caddy_insert_params(rainb0w_config, CADDY_CONFIG_FILE)

    # If this is a new Express/Custom STATUS, we need to create a default user
    # if it's a 'Restore' we will restore the existing users one by one
    if username:
        add_user_to_proxies(
            create_new_user(username),
            RAINB0W_CONFIG_FILE,
            RAINB0W_USERS_FILE,
            CADDY_CONFIG_FILE,
            XRAY_CONFIG_FILE,
            HYSTERIA_CONFIG_FILE,
        )
    else:
        # Add users from the rainb0w_users.toml into proxies
        for user in rainb0w_users["users"]:
            add_user_to_proxies(
                user,
                RAINB0W_CONFIG_FILE,
                RAINB0W_USERS_FILE,
                CADDY_CONFIG_FILE,
                XRAY_CONFIG_FILE,
                HYSTERIA_CONFIG_FILE,
            )

    exit(0)


def configure():
    rainb0w_config = load_toml(RAINB0W_CONFIG_FILE)

    if "PROXY" not in rainb0w_config:
        rainb0w_config["PROXY"] = []

    # Display notice
    print_txt_file(f"{os.getcwd()}/notice.txt")
    prompt_clear_screen()

    title = "Select the proxies you'd like to deploy [Press 'Space' to mark]:"
    options = ["Xray/v2ray", "MTProto", "Hysteria", "NaiveProxy", "DNS-over-HTTPS/TLS"]

    selected = pick(options, title, multiselect=True, min_selection_count=1)
    selected = [item[0] for item in selected]  # type: ignore

    # We need 3 steps regardless of proxy choice,
    #  one for the main domain, one for the CF key and one for username prompt
    total_steps = 2
    curr_step = 1
    # Add steps as many needed for the selection
    total_steps += len(selected)
    # Xray proxy requires two steps (direct domain and cdn domain input)
    if "Xray/v2ray" in selected:
        total_steps += 1

    progress_indicator(curr_step, total_steps, "Main Domain")
    rainb0w_config["DOMAINS"]["MAIN_DOMAIN"] = prompt_main_domain()
    curr_step += 1

    if "NaiveProxy" in selected:
        rainb0w_config["STATUS"]["NAIVE"] = True

    if "Xray/v2ray" in selected:
        progress_indicator(curr_step, total_steps, "Direct Subdomain")
        rainb0w_config["DOMAINS"]["DIRECT_CONN_DOMAIN"] = prompt_direct_conn_domain()
        curr_step += 1
        progress_indicator(curr_step, total_steps, "CDN Subdomain")
        rainb0w_config["DOMAINS"]["CDN_COMPAT_DOMAIN"] = prompt_cdn_domain()
        curr_step += 1

        # Xray configuration
        rainb0w_config["STATUS"]["XRAY"] = True
        rainb0w_config["PROXY"] = xray_gen_proxy_params(
            rainb0w_config["DOMAINS"]["MAIN_DOMAIN"],
            rainb0w_config["DOMAINS"]["CDN_COMPAT_DOMAIN"],
        )
    else:
        remove_dir(f"{RAINB0W_HOME_DIR}/xray")

    if "Hysteria" in selected:
        if rainb0w_config["DOMAINS"]["DIRECT_CONN_DOMAIN"] == "":
            progress_indicator(curr_step, total_steps, "Direct Subdomain")
            rainb0w_config["DOMAINS"][
                "DIRECT_CONN_DOMAIN"
            ] = prompt_direct_conn_domain()
            curr_step += 1

        # Hysteria configuration
        rainb0w_config["STATUS"]["HYSTERIA"] = True
        hysteria_params = hysteria_gen_params()
        if rainb0w_config["PROXY"]:
            rainb0w_config["PROXY"].append(hysteria_params)
        else:
            rainb0w_config["PROXY"] = hysteria_params
    else:
        remove_dir(f"{RAINB0W_HOME_DIR}/hysteria")

    if "DNS-over-HTTPS/TLS" in selected:
        progress_indicator(curr_step, total_steps, "DoH/DoT Subdomain")
        rainb0w_config["DOMAINS"]["DOT_DOH_DOMAIN"] = prompt_dohdot_domain()
        curr_step += 1
        rainb0w_config["STATUS"]["DOT_DOH"] = True
        # Even if DoT/DoH is not selected, we still deploy blocky
        # since it is required for some functionalities such as
        # ad, porn, and ccTLDs (.ir) blocking

    if "MTProto" in selected:
        progress_indicator(curr_step, total_steps, "MTProto Subdomain/SNI")
        rainb0w_config["DOMAINS"]["MTPROTO_DOMAIN"] = prompt_mtproto_domain(
            rainb0w_config["DOMAINS"]["MAIN_DOMAIN"]
        )
        curr_step += 1
        rainb0w_config["STATUS"]["MTPROTOPY"] = True
    else:
        remove_dir(f"{RAINB0W_HOME_DIR}/mtprotopy")

    if is_free_domain(rainb0w_config["DOMAINS"]["MAIN_DOMAIN"]):
        rainb0w_config["CLOUDFLARE"]["IS_FREE_TLD"] = True
        curr_step += 1
    else:
        progress_indicator(curr_step, total_steps, "Cloudflare API Key")
        rainb0w_config["CLOUDFLARE"]["API_KEY"] = prompt_cloudflare_api_key()
        rainb0w_config["CLOUDFLARE"]["IS_FREE_TLD"] = False
        curr_step += 1

    # Save the configuration to file because we're going to pass it around next
    save_toml(rainb0w_config, RAINB0W_CONFIG_FILE)

    # Finally prompt for a username
    progress_indicator(curr_step, total_steps, "User Management")
    username = prompt_username()

    apply_config(username=username)


def restore_config():
    if os.path.exists(RAINB0W_BACKUP_DIR):
        shutil.copyfile(
            f"{RAINB0W_BACKUP_DIR}/{os.path.basename(RAINB0W_CONFIG_FILE)}",
            RAINB0W_CONFIG_FILE,
        )
        shutil.copyfile(
            f"{RAINB0W_BACKUP_DIR}/{os.path.basename(RAINB0W_USERS_FILE)}",
            RAINB0W_USERS_FILE,
        )
        print("Restoring your configuration and users...")
        apply_config()
    else:
        print(f"ERROR: No data found at: {RAINB0W_BACKUP_DIR}")
        print(
            f"Please copy your backup files to \
                    '{RAINB0W_BACKUP_DIR}' and run the installer again!"
        )
        exit(1)


def main():
    if len(sys.argv) > 1:
        if sys.argv[1] == "Install":
            configure()
        elif sys.argv[1] == "Restore":
            restore_config()
        else:
            print("Unknown installation type passed! Exiting!")
            exit(1)
    else:
        print("Not enough args passed! Exiting!")
        exit(1)


def signal_handler(sig, frame):
    print("\nOkay! Exiting!")
    sys.exit(1)


if __name__ == "__main__":
    # Enable bailing out!
    signal.signal(signal.SIGINT, signal_handler)
    main()
