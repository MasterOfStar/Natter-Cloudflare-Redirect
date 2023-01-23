#!/bin/sh
ZONE=''
RULE=''
# You can get Rulesets ID from your web dashboard, Try to add a rule in the dashboard, and then use F12 to view the request, and you will find the rulesets ID in the request URL.
AUTH=''
# API token Permissions :Zone.Config Rules, Zone.Dynamic Redirect, Zone.Dynamic Redirect
DOMAIN='example.com'
ADDR=${4}
PORT=${5}
INNER_PORT=${3}
DDNS_DOMAIN=''
# DDNS_DOMAIN = IP_ADDR DDNS to domain name or use IP Address only .
# IF NO Domain to DDNS,  Please use DDNS_DOMAIN = ${ADDR}.
JUMP='0'
if [ ${INNER_PORT} == '1234' ]; then
    PREFIX='www'
        # IF inner port is 1234,actually domain is www.example.com
    curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE}/rulesets/${RULE}" \
    -H "Authorization: Bearer ${AUTH}" \
    -H "Content-Type:application/json" \
    --data "{\"name\": \"default\",  \"kind\": \"zone\",  \"phase\": \"http_request_dynamic_redirect\",  \"rules\": [{\"description\": \"natter${INNER_PORT}\",\"expression\": \"(http.host eq \\\"${PREFIX}.${DOMAIN}\\\")\",\"action\": \"redirect\",\"action_parameters\": {\"from_value\": {\"status_code\": 302,\"preserve_query_string\": true,\"target_url\": {\"value\": \"http://${DDNS_DOMAIN}:${PORT}/\"}}},\"enabled\": true}]}" 2 >/dev/null >/dev/null
    JUMP='1'
    echo 'Clean Rule Successful!'
    echo 'ADD '${PREFIX}'.'${DOMAIN}'->'${DDNS_DOMAIN}':'${PORT}' Successful!'
    # Please set First Inner Rule in Here.And It will wipe your all redirect rules.
    # Cause Cloudflare API Just add rule,not update rule.even the rule name is same.
    # So,You must set first rule in here.
    # Such as '/zones/${ZONE}/rulesets/${RULE}/rules' is '>>' to the api list.
    # But '/zones/${ZONE}/rulesets/${RULE}' is '>' to the api list.
elif [ ${INNER_PORT} == '5678' ]; then
    PREFIX='admin'
    # IF inner port is 5678,actually domain is admin.example.com
elif [ ${INNER_PORT} == '55555' ]; then
    JUMP='1'
    # qBittorrent. Thanks https://github.com/Mythologyli/qBittorrent-NAT-TCP-Hole-Punching.
    qb_web_port="8081"
    qb_username="admin"
    qb_password="admin"
    qb_ip="192.168.1.2"
    # Update qBittorrent listen port.
    qb_cookie=$(curl -s -i --header "Referer: $qb_ip:$qb_web_port" --data "username=$qb_username&password=$qb_password" $qb_ip:$qb_web_port/api/v2/auth/login | grep -i set-cookie | cut -c13-48)
    curl -X POST -b "$qb_cookie" -d 'json={"listen_port":"'${PORT}'"}' "$qb_ip:$qb_web_port/api/v2/app/setPreferences"
    # openwrt Firewall 
    iptables -t nat -I PREROUTING -i pppoe-wan -p tcp --dport ${INNER_PORT} -j DNAT --to-destination ${qb_ip}:${PORT}
    echo "Update qBittorrent listen port to ${PORT}..."
fi
# Explorer -> ${PREFIX}.Domain == 302 to DDNS_DOMAIN:PORT
# ${PREFIX}.DOMAIN must be use CloufFlare proxied.
# Why use natter${5PORT} and ${PREFIX}.Domain? Because Natter has multiple rules, and the rule name / domain name will be same.

if[ ${JUMP} == '0' ]；then
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE}/rulesets/${RULE}/rules" \
    -H "Authorization: Bearer ${AUTH}" \
    -H "Content-Type:application/json" \
    --data "{\"description\": \"natter${INNER_PORT}\",\"expression\": \"(http.host eq \\\"${PREFIX}.${DOMAIN}\\\")\",\"action\": \"redirect\",\"action_parameters\": {\"from_value\": {\"status_code\": 302,\"preserve_query_string\": true,\"target_url\": {\"value\": \"http://${DDNS_DOMAIN}:${PORT}/\"}}},\"enabled\": true}" >/dev/null
    echo 'ADD '${PREFIX}'.'${DOMAIN}'->'${DDNS_DOMAIN}':'${PORT}' Successful!'
fi
