#!/bin/bash

function fn_caddy_add_vless_tcp() {
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${SNI_DICT[VLESS_TCP_SUBDOMAIN]}\"
                                ]
                            }
                        }
                    ],
                    \"handle\": [
                        {
                            \"handler\": \"proxy\",
                            \"upstreams\": [
                                {
                                    \"dial\": [
                                        \"xray:3443\"
                                    ]
                                }
                            ]
                        }
                    ]
                }"
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes += [${caddy_entry}]" $1)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${SNI_DICT[VLESS_TCP_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${SNI_DICT[VLESS_TCP_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${SNI_DICT[VLESS_TCP_SUBDOMAIN]}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_caddy_add_vless_grpc() {
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${SNI_DICT[VLESS_GRPC_SUBDOMAIN]}\"
                                ]
                            }
                        }
                    ],
                    \"handle\": [
                        {
                            \"handler\": \"proxy\",
                            \"upstreams\": [
                                {
                                    \"dial\": [
                                        \"unix//dev/shm/Xray-VLESS-gRPC.socket\"
                                    ]
                                }
                            ]
                        }
                    ]
                }"
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes += [${caddy_entry}]" $1)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${SNI_DICT[VLESS_GRPC_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${SNI_DICT[VLESS_GRPC_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${SNI_DICT[VLESS_GRPC_SUBDOMAIN]}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_caddy_add_vless_ws() {
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${SNI_DICT[VLESS_WS_SUBDOMAIN]}\"
                                ]
                            }
                        }
                    ],
                    \"handle\": [
                        {
                            \"handler\": \"proxy\",
                            \"upstreams\": [
                                {
                                    \"dial\": [
                                        \"unix//dev/shm/Xray-VLESS-WSS.socket\"
                                    ]
                                }
                            ]
                        }
                    ]
                }"
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes += [${caddy_entry}]" $1)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${SNI_DICT[VLESS_WS_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${SNI_DICT[VLESS_WS_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${SNI_DICT[VLESS_WS_SUBDOMAIN]}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_caddy_add_trojan_h2() {
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${SNI_DICT[TROJAN_H2_SUBDOMAIN]}\"
                                ]
                            }
                        }
                    ],
                    \"handle\": [
                        {
                            \"handler\": \"proxy\",
                            \"upstreams\": [
                                {
                                    \"dial\": [
                                        \"xray:3444\"
                                    ]
                                }
                            ]
                        }
                    ]
                }"
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes += [${caddy_entry}]" $1)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${SNI_DICT[TROJAN_H2_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${SNI_DICT[TROJAN_H2_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${SNI_DICT[TROJAN_H2_SUBDOMAIN]}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_caddy_add_trojan_grpc() {
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${SNI_DICT[TROJAN_GRPC_SUBDOMAIN]}\"
                                ]
                            }
                        }
                    ],
                    \"handle\": [
                        {
                            \"handler\": \"proxy\",
                            \"upstreams\": [
                                {
                                    \"dial\": [
                                        \"unix//dev/shm/Xray-Trojan-gRPC.socket\"
                                    ]
                                }
                            ]
                        }
                    ]
                }"
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes += [${caddy_entry}]" $1)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${SNI_DICT[TROJAN_GRPC_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${SNI_DICT[TROJAN_GRPC_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${SNI_DICT[TROJAN_GRPC_SUBDOMAIN]}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_caddy_add_trojan_ws() {
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${SNI_DICT[TROJAN_WS_SUBDOMAIN]}\"
                                ]
                            }
                        }
                    ],
                    \"handle\": [
                        {
                            \"handler\": \"proxy\",
                            \"upstreams\": [
                                {
                                    \"dial\": [
                                        \"xray:3445\"
                                    ]
                                }
                            ]
                        }
                    ]
                }"
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes += [${caddy_entry}]" $1)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${SNI_DICT[TROJAN_WS_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${SNI_DICT[TROJAN_WS_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${SNI_DICT[TROJAN_WS_SUBDOMAIN]}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_caddy_add_vmess_ws() {
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${SNI_DICT[VMESS_WS_SUBDOMAIN]}\"
                                ]
                            }
                        }
                    ],
                    \"handle\": [
                        {
                            \"handler\": \"proxy\",
                            \"upstreams\": [
                                {
                                    \"dial\": [
                                        \"xray:3446\"
                                    ]
                                }
                            ]
                        }
                    ]
                }"
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes += [${caddy_entry}]" $1)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${SNI_DICT[VMESS_WS_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${SNI_DICT[VMESS_WS_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${SNI_DICT[VMESS_WS_SUBDOMAIN]}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_caddy_add_mtproto() {
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${SNI_DICT[MTPROTO_SUBDOMAIN]}\"
                                ]
                            }
                        }
                    ],
                    \"handle\": [
                        {
                            \"handler\": \"proxy\",
                            \"upstreams\": [
                                {
                                    \"dial\": [
                                        \"mtproto:5443\"
                                    ]
                                }
                            ]
                        }
                    ]
                }"
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes += [${caddy_entry}]" $1)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${SNI_DICT[MTPROTO_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${SNI_DICT[MTPROTO_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${SNI_DICT[MTPROTO_SUBDOMAIN]}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_caddy_add_doh_dot() {
    caddy_doh_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${SNI_DICT[DNS_SUBDOMAIN]}\"
                                ]
                            }
                        }
                    ],
                    \"handle\": [
                        {
                            \"handler\": \"proxy\",
                            \"upstreams\": [
                                {
                                    \"dial\": [
                                        \"blocky:443\"
                                    ]
                                }
                            ]
                        }
                    ]
                }"

    caddy_dot_entry="{
                            \"match\": [
                                {
                                    \"tls\": {
                                        \"sni\": [
                                            \"${SNI_DICT[DNS_SUBDOMAIN]}\"
                                        ]
                                    }
                                }
                            ],
                            \"handle\": [
                                {
                                    \"handler\": \"proxy\",
                                    \"upstreams\": [
                                        {
                                            \"dial\": [
                                                \"blocky:853\"
                                            ]
                                        }
                                    ]
                                }
                            ]
                        }"

    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes += [${caddy_doh_entry}]" $1)
    tmp_caddy=$(jq ".apps.layer4.servers.dot.routes += [${caddy_dot_entry}]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${SNI_DICT[DNS_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${SNI_DICT[DNS_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${SNI_DICT[DNS_SUBDOMAIN]}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_caddy_add_hysteria() {
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${SNI_DICT[HYSTERIA_SUBDOMAIN]}\"]" $1)
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${SNI_DICT[HYSTERIA_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${SNI_DICT[HYSTERIA_SUBDOMAIN]}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_caddy_add_fallback_camouflage() {
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${SNI_DICT[FALLBACK_DOMAIN]}\"]" $1)
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${SNI_DICT[FALLBACK_DOMAIN]}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.http.servers.web.routes[0].match[0].host += [\"${SNI_DICT[FALLBACK_DOMAIN]}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${SNI_DICT[FALLBACK_DOMAIN]}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_configure_caddy() {
    # DoT/DoH
    if [ ! -z "${SNI_DICT[DNS_SUBDOMAIN]}" ]; then
        fn_caddy_add_doh_dot $1
    fi
    # Xray proxies
    if [ ! -z "${SNI_DICT[VLESS_TCP_SUBDOMAIN]}" ]; then
        fn_caddy_add_vless_tcp $1
    fi
    if [ ! -z "${SNI_DICT[VLESS_GRPC_SUBDOMAIN]}" ]; then
        fn_caddy_add_vless_grpc $1
    fi
    if [ ! -z "${SNI_DICT[VLESS_WS_SUBDOMAIN]}" ]; then
        fn_caddy_add_vless_ws $1
    fi
    if [ ! -z "${SNI_DICT[TROJAN_H2_SUBDOMAIN]}" ]; then
        fn_caddy_add_trojan_h2 $1
    fi
    if [ ! -z "${SNI_DICT[TROJAN_GRPC_SUBDOMAIN]}" ]; then
        fn_caddy_add_trojan_grpc $1
    fi
    if [ ! -z "${SNI_DICT[TROJAN_WS_SUBDOMAIN]}" ]; then
        fn_caddy_add_trojan_ws $1
    fi
    if [ ! -z "${SNI_DICT[VMESS_WS_SUBDOMAIN]}" ]; then
        fn_caddy_add_vmess_ws $1
    fi
    #  MTProto
    if [ ! -z "${SNI_DICT[MTPROTO_SUBDOMAIN]}" ]; then
        fn_caddy_add_mtproto $1
    fi
    #  Hysteria
    if [ ! -z "${SNI_DICT[HYSTERIA_SUBDOMAIN]}" ]; then
        fn_caddy_add_hysteria $1
    fi
}

function fn_start_caddy() {
    fn_setup_docker_vols_networks
    fn_configure_caddy $1
    fn_start_docker_container caddy
}
