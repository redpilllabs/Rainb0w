#!/bin/bash

function fn_configure_hysteria() {
    tmp_hysteria=$(jq ".obfs = \"${HYSTERIA_PASSWORD}\"" $1)
    tmp_hysteria=$(jq ".cert = \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${HYSTERIA_SUBDOMAIN}/${HYSTERIA_SUBDOMAIN}.crt\"" <<<"$tmp_hysteria")
    jq ".key = \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${HYSTERIA_SUBDOMAIN}/${HYSTERIA_SUBDOMAIN}.key\"" <<<"$tmp_hysteria" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_configure_hysteria_client() {
    tmp_hysteria=$(jq ".obfs = \"${HYSTERIA_PASSWORD}\"" $1)
    tmp_hysteria=$(jq ".server = \"${HYSTERIA_SUBDOMAIN}:554\"" <<<"$tmp_hysteria")
    jq ".server_name = \"${HYSTERIA_SUBDOMAIN}\"" <<<"$tmp_hysteria" >/tmp/tmp.json && mv /tmp/tmp.json $1
}
