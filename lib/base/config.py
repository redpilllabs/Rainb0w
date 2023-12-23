import os

# Path
TLS_CERTS_DIR = (
    "/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory"
)
RAINB0W_BACKUP_DIR = f"{os.path.expanduser('~')}/Rainb0w_Backup"
RAINB0W_HOME_DIR = f"{os.path.expanduser('~')}/Rainb0w_Home"
RAINB0W_CONFIG_FILE = f"{RAINB0W_HOME_DIR}/rainb0w_config.toml"
RAINB0W_USERS_FILE = f"{RAINB0W_HOME_DIR}/rainb0w_users.toml"
CLIENTS_SHARE_URLS_DIR = f"{RAINB0W_HOME_DIR}/caddy/clients"
CADDY_CONFIG_FILE = f"{RAINB0W_HOME_DIR}/caddy/etc/caddy.json"
XRAY_CONFIG_FILE = f"{RAINB0W_HOME_DIR}/xray/etc/xray.json"
HYSTERIA_CONFIG_FILE = f"{RAINB0W_HOME_DIR}/hysteria/etc/hysteria.yml"
MTPROTOPY_CONFIG_FILE = f"{RAINB0W_HOME_DIR}/mtprotopy/etc/config.toml"
BLOCKY_CONFIG_FILE = f"{RAINB0W_HOME_DIR}/blocky/etc/config.yml"
