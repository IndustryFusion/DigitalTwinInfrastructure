#!/bin/bash
# Copyright (c) 2023 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
set -e

DEVICES_NAMESPACE=devices
usage="Usage: $(basename $0) [-s] [-f]"
while getopts 'sfh' opt; do
  case "$opt" in
    f)
      file=true
      ;;
    s)
      secret=true
      ;;
    ?|h)
      printf "$usage"
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

if [ -n "$file" ] && [ -n "$secret" ]; then
  echo "Error: Both -f and -s cannot be set"
  printf "${usage}"
  exit 1
fi
if [ -z "$file" ] && [ -z "$secret" ]; then
  echo "Error: Either -f and -s must be set"
  printf "${usage}"
  exit 1
fi

# Define the JSON file path
onboard_token_json_file="../data/onboard-token.json"
dev_json_file="../data/device.json"

function get_token() {
  secrets=$(kubectl -n ${DEVICES_NAMESPACE} get secret -l iff-device-onboarding=true -oname)
  for secret in $secrets; do
    echo "Processing Secret $secret" >&2
    token=$(kubectl -n ${DEVICES_NAMESPACE} get $secret -o jsonpath='{.data.onboarding_token}')
    if kubectl -n ${DEVICES_NAMESPACE} delete $secret 2>&1 >/dev/null; then 
      echo $token
      break
    fi
  done
}

success=false
while [ "$success" = "false" ]; do
  echo "Waiting for secrets ..."
  raw_token=$(get_token)
  echo $raw_token
  token=$(echo $raw_token | base64 -d ) || token=""
  if [ -n "$token" ]; then
    success=true
  fi
  sleep 2
done
echo $token
exit 0

# Check if the file exists
if [ ! -f "$dev_json_file" ]; then
    echo "JSON file not found: $dev_json_file"
    exit 1
fi

if [ ! -f "$onboard_token_json_file" ]; then
    echo "JSON file not found: $onboard_token_json_file"
    exit 1
fi

#access_token=$(jq -r '.access_token' "$onboard_token_json_file")
#if [ -z "$access_token" ]; then
#    echo "access_token not found, please check again"
#    exit 1
#fi

keycloakurl=$(jq -r '.keycloakUrl' "$dev_json_file")
#gatewayid=$(jq -r '.gateway_id' "$dev_json_file")
#deviceid=$(jq -r '.device_id' "$dev_json_file")

# Check if the file exists
#if [ -z "$keycloakurl" ] || [ -z "$gatewayid" ] ||[ -z "$deviceid" ]; then
#    echo "device json file doesnot contain required item, may run again ./set-device.sh"
#    exit 1
#fi

# Define the API endpoint
ONBOARDING_TOKEN_ENDPOINT="$keycloakurl/protocol/openid-connect/token"
#echo "API endpoint is :" $ONBOARDING_TOKEN_ENDPOINT
# Make the curl request with access token as a header and store the response in the temporary file
response_token=$(curl -X POST "$ONBOARDING_TOKEN_ENDPOINT"  -d "client_id=device" \
-d "grant_type=password" -d "password=${password}" -d "username=${username}" 2>/dev/null | jq '.')
#echo $response_token

if [ "$(echo $response_token | jq 'has("error")')" = "true" ]; then
    echo "Error: Invalid onbarding token found."
    exit 1
fi

# Replace access_key by device_key
#response_token=$(echo $response_token | jq 'with_entries(if .key == "access_token" then .key = "device_token" else . end)')
if [ "$secret_enabled" = "true" ]; then
    create_secret "$response_token"
    echo "Device token secret stored in $secret_file"
else
    echo "$response_token" > "$onboard_token_json_file"
    echo "Device token stored in $onboard_token_json_file"
fi
#updated_json_data=$(jq --argjson response "$response_token" '. += $response' "$dev_json_file")
