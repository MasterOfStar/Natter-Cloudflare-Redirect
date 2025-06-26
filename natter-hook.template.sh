#!/bin/sh
# required jq sed curl
# In the natterv2 protocol="$1"; private_ip="$2"; private_port="$3"; public_ip="$4"; public_port="$5"

# ENV
outter_ip=${4}
outter_port=${5}
CLOUDFLARE_ZONE_ID=''
CLOUDFLARE_AUTH_KEY=''
CLOUDFLARE_API_KEY=''
CLOUDFLARE_RULE_NAME='test8089'
CLOUDFLARE_EMAIL='for@example.com'
CLOUDFLARE_RULE_FORM_URL='http://a.test.com'
CLOUDFLARE_RULE_TARGET_URL='http://b.test.com/'


get_current_rule() {
curl -s --retry 10 --request GET \
    --url https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/rulesets/phases/http_request_dynamic_redirect/entrypoint \
    --header "Authorization: Bearer $CLOUDFLARE_AUTH_KEY" \
    --header 'Content-Type: application/json'
}
currrent_rule=$(get_current_rule)

CLOUDFLARE_RULE_TARGET_URL="${CLOUDFLARE_RULE_TARGET_URL%/}"':NEW_PORT/${1}'
CLOUDFLARE_RULE_NAME="\"$CLOUDFLARE_RULE_NAME\""
# replace NEW_PORT with outter_port 
CLOUDFLARE_RULE_TARGET_URL=$(echo $CLOUDFLARE_RULE_TARGET_URL | sed 's/NEW_PORT/'"$outter_port"'/g')
new_rule=$(echo "$currrent_rule" | jq '.result.rules| to_entries | map(select(.value.description == '"$CLOUDFLARE_RULE_NAME"')) | .[].key')
new_rule=$(echo "$currrent_rule" | jq '.result.rules['"$new_rule"'].action_parameters.from_value.target_url.expression = "wildcard_replace(http.request.full_uri, r\"'"$CLOUDFLARE_RULE_FORM_URL"'*\", \"'"$CLOUDFLARE_RULE_TARGET_URL"'\")"')

CLOUDFLARE_RULESET_ID=$(echo "$currrent_rule" | jq '.result.id' | sed 's/"//g')

body=$(echo "$new_rule" | jq '.result')
# delete last_updated
body=$(echo "$body" | jq 'del(.last_updated)')
body=$(echo "$body" | tr -d '\n')

echo $body >> 1.json
# body=$(echo "$body" | sed -E 's#(r\"http://b.test.com:[0-9]+/\$\{1\}\")#\"$CLOUDFLARE_RULE_TARGET_URL\"#')
# final: In example Cloudflare will redirect http://a.test.com/* to  http://b.test.com:8089/  . In the rule, ${1} = *   .
curl -s --retry 10 --request PUT \
  --url https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/rulesets/$CLOUDFLARE_RULESET_ID \
  --header "X-Auth-Key: $CLOUDFLARE_API_KEY" \
  --header "X-Auth-Email: $CLOUDFLARE_EMAIL" \
  --header 'Content-Type: application/json' \
  --data "$body"
