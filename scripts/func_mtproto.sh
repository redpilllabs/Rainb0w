#!/bin/bash

function fn_configure_mtproto_users() {
    sed -i -e "s/\<TG_SECRET\>/$TG_SECRET/" $1
}

function fn_configure_mtproto() {
    # This is a TOML file so we revert to sed
    sed -i -e "s/\<MTPROTO_SUBDOMAIN\>/$MTPROTO_SUBDOMAIN/g" $1
    # Edit Caddy config.json
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${MTPROTO_SUBDOMAIN}\"
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
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes[.routes| length] |= . + ${caddy_entry}" $2)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${MTPROTO_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${MTPROTO_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${MTPROTO_SUBDOMAIN}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $2
}
