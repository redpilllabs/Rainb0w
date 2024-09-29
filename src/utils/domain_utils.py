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
        main_domain = extract_domain(domain)
        return f"wildcard_.{main_domain}"
    else:
        return domain


def prompt_main_domain() -> str:
    print("This will be used to setup a dummy WordPress blog to offer to active probers.")
    main_domain = input("\nEnter your decoy domain (e.g example.com): ")
    while not (is_domain(main_domain) or is_subdomain(main_domain) or is_free_domain(main_domain)):
        print("\nInvalid domain name! Please enter in this format: example.com or sub.example.com")
        if is_free_domain(main_domain):
            print("\nFree domains (.gq, .cf, .ml, .tk, or .ga) are not supported by the Cloudflare DNS plugin.")
        main_domain = input("Enter your decoy domain: ")

    return main_domain


def prompt_direct_conn_domain():
    print(
        """Your DIRECT subdomain will be used for the following:
    - Hysteria (UDP)
    """
    )
    direct_domain = input(
        "\nEnter a subdomain for DIRECT connections (e.g sub.example.com): "
    )
    while not is_subdomain(direct_domain) or is_free_domain(direct_domain):
        print("\nInvalid subdomain name! Please enter in this format: sub.example.com")
        if is_free_domain(direct_domain):
            print(
                "\nFree domains (.gq, .cf, .ml, .tk, or .ga) are not supported by the Cloudflare DNS plugin."
            )
        direct_domain = input(
            "Enter a subdomain for DIRECT connections (e.g sub.example.com): "
        )

    return direct_domain


def prompt_cdn_domain() -> str:
    print(
        """Your CDN subdomain will be used for the following:
    - VLESS Websocket
    - VLESS HTTPUpgrade
    - VLESS gRPC
    """
    )
    cdn_domain = input("\nEnter subdomain for CDN connections (e.g sub.example.com): ")
    while not is_subdomain(cdn_domain) or is_free_domain(cdn_domain):
        print("\nInvalid subdomain name! Please enter in this format: sub.example.com")
        if is_free_domain(cdn_domain):
            print(
                "\nFree domains (.gq, .cf, .ml, .tk, or .ga) are not supported by the Cloudflare DNS plugin."
            )
        cdn_domain = input(
            "Enter subdomain for CDN connections (e.g sub.example.com): "
        )

    return cdn_domain



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
