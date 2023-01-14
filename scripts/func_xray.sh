#!/bin/bash

function fn_xray_add_xtls() {
    xray_entry="{
            \"listen\": \"0.0.0.0\",
            \"port\": 3443,
            \"protocol\": \"vless\",
            \"settings\": {
                \"clients\": [
                    {
                        \"id\": \"${XTLS_UUID}\",
                        \"flow\": \"xtls-rprx-vision\"
                    }
                ],
                \"decryption\": \"none\"
            },
            \"streamSettings\": {
                \"network\": \"tcp\",
                \"security\": \"tls\",
                \"tlsSettings\": {
                    \"rejectUnknownSni\": true,
                    \"certificates\": [
                        {
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${XTLS_SUBDOMAIN}/${XTLS_SUBDOMAIN}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${XTLS_SUBDOMAIN}/${XTLS_SUBDOMAIN}.key\"
                        }
                    ]
                }
            }
        }"
    jq ".inbounds[.inbounds| length] |= . + ${xray_entry}" $1 >/tmp/tmp.json && mv /tmp/tmp.json $1
    # Edit Caddy config.json
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${XTLS_SUBDOMAIN}\"
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
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes[.routes| length] |= . + ${caddy_entry}" $2)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${XTLS_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${XTLS_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${XTLS_SUBDOMAIN}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $2
}

function fn_xray_add_trojan_h2() {
    xray_entry="{
            \"listen\": \"0.0.0.0\",
            \"port\": 3444,
            \"protocol\": \"trojan\",
            \"settings\": {
                \"clients\": [
                    {
                        \"password\": \"${TROJAN_H2_PASSWORD}\"
                    }
                ]
            },
            \"streamSettings\": {
                \"network\": \"http\",
                \"httpSettings\": {
                    \"path\": \"/${TROJAN_H2_PATH}\",
                    \"host\": [
                        \"${TROJAN_H2_SUBDOMAIN}\"
                    ]
                },
                \"security\": \"tls\",
                \"tlsSettings\": {
                    \"rejectUnknownSni\": true,
                    \"certificates\": [
                        {
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${TROJAN_H2_SUBDOMAIN}/${TROJAN_H2_SUBDOMAIN}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${TROJAN_H2_SUBDOMAIN}/${TROJAN_H2_SUBDOMAIN}.key\"
                        }
                    ]
                }
            }
        }"
    jq ".inbounds[.inbounds| length] |= . + ${xray_entry}" $1 >/tmp/tmp.json && mv /tmp/tmp.json $1
    # Edit Caddy config.json
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${TROJAN_H2_SUBDOMAIN}\"
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
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes[.routes| length] |= . + ${caddy_entry}" $2)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${TROJAN_H2_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${TROJAN_H2_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${TROJAN_H2_SUBDOMAIN}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $2
}

function fn_xray_add_trojan_grpc() {
    xray_entry="{
            \"listen\": \"/dev/shm/Xray-Trojan-gRPC.socket,0666\",
            \"protocol\": \"trojan\",
            \"settings\": {
                \"clients\": [
                    {
                        \"password\": \"${TROJAN_GRPC_PASSWORD}\"
                    }
                ]
            },
            \"streamSettings\": {
                \"network\": \"grpc\",
                \"grpcSettings\": {
                    \"serviceName\": \"${TROJAN_GRPC_SERVICENAME}\"
                },
                \"security\": \"tls\",
                \"tlsSettings\": {
                    \"rejectUnknownSni\": true,
                    \"certificates\": [
                        {
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${TROJAN_GRPC_SUBDOMAIN}/${TROJAN_GRPC_SUBDOMAIN}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${TROJAN_GRPC_SUBDOMAIN}/${TROJAN_GRPC_SUBDOMAIN}.key\"
                        }
                    ]
                }
            }
        }"
    jq ".inbounds[.inbounds| length] |= . + ${xray_entry}" $1 >/tmp/tmp.json && mv /tmp/tmp.json $1
    # Edit Caddy config.json
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${TROJAN_GRPC_SUBDOMAIN}\"
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
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes[.routes| length] |= . + ${caddy_entry}" $2)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${TROJAN_GRPC_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${TROJAN_GRPC_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${TROJAN_GRPC_SUBDOMAIN}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $2
}

function fn_xray_add_trojan_ws() {
    xray_entry="{
            \"listen\": \"0.0.0.0\",
            \"port\": 3445,
            \"protocol\": \"trojan\",
            \"settings\": {
                \"clients\": [
                    {
                        \"password\": \"${TROJAN_WS_PASSWORD}\"
                    }
                ]
            },
            \"streamSettings\": {
                \"network\": \"ws\",
                \"wsSettings\": {
                    \"path\": \"/${TROJAN_WS_PATH}\",
                    \"host\": [
                        \"${TROJAN_WS_SUBDOMAIN}\"
                    ]
                },
                \"security\": \"tls\",
                \"tlsSettings\": {
                    \"rejectUnknownSni\": true,
                    \"certificates\": [
                        {
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${TROJAN_WS_SUBDOMAIN}/${TROJAN_WS_SUBDOMAIN}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${TROJAN_WS_SUBDOMAIN}/${TROJAN_WS_SUBDOMAIN}.key\"
                        }
                    ]
                }
            }
        }"
    jq ".inbounds[.inbounds| length] |= . + ${xray_entry}" $1 >/tmp/tmp.json && mv /tmp/tmp.json $1
    # Edit Caddy config.json
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${TROJAN_WS_SUBDOMAIN}\"
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
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes[.routes| length] |= . + ${caddy_entry}" $2)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${TROJAN_WS_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${TROJAN_WS_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${TROJAN_WS_SUBDOMAIN}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $2
}

function fn_xray_add_vmess_ws() {
    xray_entry="{
            \"listen\": \"0.0.0.0\",
            \"port\": 3446,
            \"protocol\": \"vmess\",
            \"settings\": {
                \"clients\": [
                    {
                        \"id\": \"${VMESS_UUID}\",
                        \"security\": \"none\"
                    }
                ]
            },
            \"streamSettings\": {
                \"network\": \"ws\",
                \"wsSettings\": {
                    \"path\": \"/${VMESS_WS_PATH}\",
                    \"host\": [
                        \"${VMESS_WS_SUBDOMAIN}\"
                    ]
                },
                \"security\": \"tls\",
                \"tlsSettings\": {
                    \"rejectUnknownSni\": true,
                    \"certificates\": [
                        {
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${VMESS_WS_SUBDOMAIN}/${VMESS_WS_SUBDOMAIN}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${VMESS_WS_SUBDOMAIN}/${VMESS_WS_SUBDOMAIN}.key\"
                        }
                    ]
                }
            }
        }"
    jq ".inbounds[.inbounds| length] |= . + ${xray_entry}" $1 >/tmp/tmp.json && mv /tmp/tmp.json $1
    # Edit Caddy config.json
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${VMESS_WS_SUBDOMAIN}\"
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
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes[.routes| length] |= . + ${caddy_entry}" $2)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${VMESS_WS_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${VMESS_WS_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${VMESS_WS_SUBDOMAIN}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $2
}

function fn_configure_xray() {
    if [ -v "${XTLS_SUBDOMAIN}" ]; then
        fn_xray_add_xtls $1 $2
    fi
    if [ -v "${TROJAN_H2_SUBDOMAIN}" ]; then
        fn_xray_add_trojan_h2 $1 $2
    fi
    if [ -v "${TROJAN_GRPC_SUBDOMAIN}" ]; then
        fn_xray_add_trojan_grpc $1 $2
    fi
    if [ -v "${TROJAN_WS_SUBDOMAIN}" ]; then
        fn_xray_add_trojan_ws $1 $2
    fi
    if [ -v "${VMESS_WS_SUBDOMAIN}" ]; then
        fn_xray_add_vmess_ws $1 $2
    fi
}

function fn_configure_camouflage_website() {
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${CAMOUFLAGE_DOMAIN}\"]" $1)
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${CAMOUFLAGE_DOMAIN}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.http.servers.web.routes[0].match[0].host += [\"${CAMOUFLAGE_DOMAIN}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${CAMOUFLAGE_DOMAIN}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $1
}
