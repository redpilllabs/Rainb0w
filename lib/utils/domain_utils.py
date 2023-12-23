import re


def is_domain(domain: str) -> bool:
    regex = r"^[a-zA-Z0-9][a-zA-Z0-9\-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$"
    if re.search(regex, domain):
        return True
    else:
        return False


def is_subdomain(input: str) -> bool:
    pattern = r"(.*)\.(.*)\.(.*)"
    return True if re.match(pattern, input) else False


def is_free_domain(domain: str) -> bool:
    # Regex for domain names ending in .gq, .cf, .ml, .tk, or .ga
    regex = r"[\w-]+\.(gq|cf|ml|tk|ga)$"
    return True if re.search(regex, domain) else False


def extract_domain(domain: str) -> str:
    if is_subdomain(domain):
        return domain[domain.index(".") + 1 :]
    else:
        return domain


def get_cert_dir(domain: str) -> str:
    """
    Wildcard (SANS) domain certificates are only supported for non-free TLDs
    This function checks the input domain and returns the appropriate path

    Args:
        domain (str): Input domain

    Returns:
        str: Dir name that gets appended to the certificates path
    """
    if is_subdomain(domain):
        if is_free_domain(domain):
            return domain
        else:
            main_domain = extract_domain(domain)
            return f"wildcard_.{main_domain}"
    else:
        return domain


def prompt_main_domain() -> str:
    print(
        """Your decoy domain will be used for the following:
    - HTTP (VMESS, Trojan)
    - NaiveProxy
    - Decoy (Fake) Website"""
    )
    main_domain = input("\nEnter your decoy domain (e.g example.com): ")
    while not (is_domain(main_domain) or is_subdomain(main_domain)):
        print("\nInvalid domain name! Please enter in this format: example.com or sub.example.com")
        main_domain = input("Enter your decoy domain: ")

    return main_domain


def prompt_direct_conn_domain():
    print(
        """Your DIRECT subdomain will be used for the following:
    - TCP (VLESS, Trojan)
    - UDP (Hysteria)
    """
    )
    direct_domain = input(
        "\nEnter a subdomain for DIRECT connections (e.g sub.example.com): "
    )
    while not is_subdomain(direct_domain):
        print("\nInvalid subdomain name! Please enter in this format: sub.example.com")
        direct_domain = input(
            "Enter a subdomain for DIRECT connections (e.g sub.example.com): "
        )

    return direct_domain


def prompt_cdn_domain() -> str:
    print(
        """Your CDN compatible subdomain will be used for the following:
    - Websocket (VLESS, VMESS, Trojan)
    - gRPC (VLESS, VMESS, Trojan)
    """
    )
    cdn_domain = input("\nEnter subdomain for CDN connections (e.g sub.example.com): ")
    while not is_subdomain(cdn_domain):
        print("\nInvalid subdomain name! Please enter in this format: sub.example.com")
        cdn_domain = input(
            "Enter subdomain for CDN connections (e.g sub.example.com): "
        )

    return cdn_domain


def prompt_dohdot_domain():
    print(
        "You need an individual subdomain for your personal DNS-over-HTTPS/TLS server"
    )
    dohdot_domain = input(
        "\nEnter a subdomain for DoH/DoT server (e.g sub.example.com): "
    )
    while not is_subdomain(dohdot_domain):
        print("\nInvalid subdomain name! Please enter in this format: sub.example.com")
        dohdot_domain = input(
            "Enter a subdomain for DoH/DoT server (e.g sub.example.com): "
        )

    return dohdot_domain


def prompt_mtproto_domain(main_domain: str) -> str:
    if is_free_domain(main_domain):
        print(
            """You are using a free domain tld [.ga .gq .cf .ml .tk] which does not
support wildcard TLS certs, so you need to create an individual subdomain for your
MTProto proxy!"""
        )
        mtproto_domain = input(
            "\nEnter a subdomain for the MTProto proxy (e.g sub.example.com): "
        )
        while not is_subdomain(mtproto_domain):
            print(
                "\nInvalid subdomain name! Please enter in this format: sub.example.com"
            )
            mtproto_domain = input(
                "Enter a subdomain the MTProto proxy (e.g sub.example.com): "
            )
    else:
        print(
            """You need a FAKE subdomain for your MTProto proxy! It can be a fake subdomain
of your own domain or a fake domain that is related to your IP space!
        """
        )
        mtproto_domain = input(
            "\nEnter a fake subdomain for the MTProto proxy (e.g sub.example.com): "
        )
        while not is_subdomain(mtproto_domain):
            print(
                "\nInvalid subdomain name! Please enter in this format: sub.example.com"
            )
            mtproto_domain = input(
                "Enter a fake subdomain the MTProto proxy (e.g sub.example.com): "
            )

    return mtproto_domain


def prompt_cloudflare_api_key():
    print(
        """You Cloudflare API key will be used by Caddy to obtain TLS certs by
verifying DNS-01 challenges. The API key must have the permission to edit DNS Zones."""
    )
    cf_api_key = input("\nEnter your Cloudflare API key: ")
    while not cf_api_key:
        print("\nInvalid API key!")
        cf_api_key = input("Enter your Cloudflare API key: ")

    return cf_api_key
