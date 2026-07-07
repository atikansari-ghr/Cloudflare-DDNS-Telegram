#!/usr/bin/env bash
cf_api(){ local method="$1" endpoint="$2" data="${3:-}"; if [[ -n "$data" ]]; then curl -sS --connect-timeout 10 --max-time 30 -X "$method" "https://api.cloudflare.com/client/v4${endpoint}" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" --data "$data"; else curl -sS --connect-timeout 10 --max-time 30 -X "$method" "https://api.cloudflare.com/client/v4${endpoint}" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json"; fi; }
validate_token(){ cf_api GET "/user/tokens/verify"|jq -r '.success'; }
get_zone_id(){ cf_api GET "/zones?name=$1"|jq -r '.result[0].id // empty'; }
get_record_id(){ cf_api GET "/zones/$1/dns_records?type=$3&name=$2"|jq -r '.result[0].id // empty'; }
get_record_content(){ cf_api GET "/zones/$1/dns_records/$2"|jq -r '.result.content // empty'; }
create_record(){ payload=$(jq -n --arg type "$3" --arg name "$2" --arg content "$4" --argjson ttl "$5" --argjson proxied "$6" '{type:$type,name:$name,content:$content,ttl:$ttl,proxied:$proxied}'); cf_api POST "/zones/$1/dns_records" "$payload"; }
update_record(){ payload=$(jq -n --arg type "$4" --arg name "$3" --arg content "$5" --argjson ttl "$6" --argjson proxied "$7" '{type:$type,name:$name,content:$content,ttl:$ttl,proxied:$proxied}'); cf_api PUT "/zones/$1/dns_records/$2" "$payload"; }
