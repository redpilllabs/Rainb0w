from utils.helper import is_string_in_file


def is_porn_blocked():
    return True if is_string_in_file("/etc/iptables/rules.v4", "Block Porn") else False
