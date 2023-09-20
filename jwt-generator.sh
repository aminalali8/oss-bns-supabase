#!/usr/bin/env bash

# JWT Encoder Bash Script

# Secret
secret=$JWT_SECRET

# Current time and 5 years from now
today=$(date +%s)
five_years=$(date -d '+5 years' +%s)

# Anon and Service Tokens
anon_token=$(cat <<- EOM
{
    "role": "anon",
    "iss": "supabase",
    "iat": $today,
    "exp": $five_years
}
EOM
)

service_token=$(cat <<- EOM
{
    "role": "service_role",
    "iss": "supabase",
    "iat": $today,
    "exp": $five_years
}
EOM
)

# Static header fields
header='{
  "typ": "JWT",
  "alg": "HS256",
  "kid": "0001",
  "iss": "Bash JWT Generator"
}'

# Functions
base64_encode() {
  declare input=${1:-$(</dev/stdin)}
  printf '%s' "${input}" | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'
}

json() {
  declare input=${1:-$(</dev/stdin)}
  printf '%s' "${input}" | jq -c .
}

hmacsha256_sign() {
  declare input=${1:-$(</dev/stdin)}
  printf '%s' "${input}" | openssl dgst -binary -sha256 -hmac "${secret}"
}

generate_token() {
  local payload=$1
  header_base64=$(echo "${header}" | json | base64_encode)
  payload_base64=$(echo "${payload}" | json | base64_encode)
  header_payload=$(echo "${header_base64}.${payload_base64}")
  signature=$(echo "${header_payload}" | hmacsha256_sign | base64_encode)
  echo "${header_payload}.${signature}"
}

# Generate and export tokens
export JWT_ANON=$(generate_token "$anon_token")
export JWT_SVC=$(generate_token "$service_token")

echo "JWT_ANON and JWT_SVC environment variables set."
