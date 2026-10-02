#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

asb_admin_server="${KEYCLOAK_ADMIN_SERVER:-http://127.0.0.1:8080}"
asb_admin_user="${KC_BOOTSTRAP_ADMIN_USERNAME:-admin}"
asb_admin_password="${KC_BOOTSTRAP_ADMIN_PASSWORD:?KC_BOOTSTRAP_ADMIN_PASSWORD must be set}"
: "${KEYCLOAK_SYNC_CLIENT_SECRET:?KEYCLOAK_SYNC_CLIENT_SECRET must be set}"
: "${KEYCLOAK_USER_CLIENT_SECRET:?KEYCLOAK_USER_CLIENT_SECRET must be set}"
: "${KEYCLOAK_ADMIN_CLIENT_SECRET:?KEYCLOAK_ADMIN_CLIENT_SECRET must be set}"
# Export defaults so that realm import and the Admin CLI use identical URLs.
export KEYCLOAK_USER_BASE_URL="${KEYCLOAK_USER_BASE_URL:-https://asb-hh-mitte.de}"
export KEYCLOAK_USER_REDIRECT_URI="${KEYCLOAK_USER_REDIRECT_URI:-${KEYCLOAK_USER_BASE_URL}/auth/callback}"
export KEYCLOAK_ADMIN_BASE_URL="${KEYCLOAK_ADMIN_BASE_URL:-https://asb-hh-mitte.de/admin}"
export KEYCLOAK_ADMIN_REDIRECT_URI="${KEYCLOAK_ADMIN_REDIRECT_URI:-${KEYCLOAK_ADMIN_BASE_URL}/auth/callback}"
asb_kcadm_dir="$(mktemp -d /tmp/asb-hh-mitte-kcadm.XXXXXX)"
asb_kcadm_config="${asb_kcadm_dir}/config"
asb_server_pid=""

stop_keycloak() {
  if [[ -n "${asb_server_pid}" ]] && kill -0 "${asb_server_pid}" 2>/dev/null; then
    kill -TERM "${asb_server_pid}" 2>/dev/null || true
    wait "${asb_server_pid}" 2>/dev/null || true
  fi
  rm -f "${asb_kcadm_config}"
  rmdir "${asb_kcadm_dir}"
}

find_client_uuid() {
  /opt/keycloak/bin/kcadm.sh get clients \
    --config "${asb_kcadm_config}" \
    -r "$1" -q "clientId=$2" --fields id \
    | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1
}

configure_client() {
  local asb_realm="$1" asb_label="$2" asb_secret="$3" asb_base_url="$4" asb_redirect_uri="$5"
  local asb_client_id="asb-hh-mitte-${asb_realm}"
  local asb_client_uuid
  local -a asb_client_settings=(
    -s "clientId=${asb_client_id}"
    -s "name=ASB HH Mitte${asb_label:+ – ${asb_label}}"
    -s "description=OpenID-Connect-Anmeldung für ASB HH Mitte${asb_label:+ (${asb_label})}"
    -s enabled=true
    -s protocol=openid-connect
    -s publicClient=false
    -s clientAuthenticatorType=client-secret
    -s "secret=${asb_secret}"
    -s serviceAccountsEnabled=false
    -s standardFlowEnabled=true
    -s implicitFlowEnabled=false
    -s directAccessGrantsEnabled=false
    -s consentRequired=false
    -s fullScopeAllowed=false
    -s "rootUrl=${asb_base_url}"
    -s "baseUrl=${asb_base_url}"
    -s "redirectUris=[\"${asb_redirect_uri}\"]"
    -s 'webOrigins=[]'
    -s 'defaultClientScopes=["profile","email"]'
    -s 'attributes={"pkce.code.challenge.method":"S256"}'
  )

  asb_client_uuid="$(find_client_uuid "${asb_realm}" "${asb_client_id}")"
  if [[ -n "${asb_client_uuid}" ]]; then
    /opt/keycloak/bin/kcadm.sh update "clients/${asb_client_uuid}" \
      --config "${asb_kcadm_config}" -r "${asb_realm}" \
      "${asb_client_settings[@]}" >/dev/null
  else
    /opt/keycloak/bin/kcadm.sh create clients \
      --config "${asb_kcadm_config}" -r "${asb_realm}" \
      "${asb_client_settings[@]}" >/dev/null
  fi
  echo "Keycloak-Client '${asb_client_id}' im Realm '${asb_realm}' konfiguriert."
}

configure_realms() {
  local asb_attempt=1 asb_realm asb_label asb_sync_uuid

  until /opt/keycloak/bin/kcadm.sh config credentials \
    --config "${asb_kcadm_config}" --server "${asb_admin_server}" \
    --realm master --user "${asb_admin_user}" \
    --password "${asb_admin_password}" >/dev/null 2>&1; do
    if ! kill -0 "${asb_server_pid}" 2>/dev/null || (( asb_attempt >= 60 )); then
      echo "ASB-Realm-Konfiguration fehlgeschlagen: Keycloak-Admin-Anmeldung war nicht möglich." >&2
      return 1
    fi
    asb_attempt=$((asb_attempt + 1))
    sleep 2
  done

  for asb_realm in user admin; do
    asb_label=""
    if [[ "${asb_realm}" == admin ]]; then
      asb_label="Administration"
    fi
    /opt/keycloak/bin/kcadm.sh update "realms/${asb_realm}" \
      --config "${asb_kcadm_config}" \
      -s "displayName=ASB HH Mitte${asb_label:+ – ${asb_label}}" \
      -s loginTheme=asb-hh-mitte \
      -s accountTheme=asb-hh-mitte \
      -s emailTheme=asb-hh-mitte \
      -s resetPasswordAllowed=false \
      -s editUsernameAllowed=false \
      -s internationalizationEnabled=false >/dev/null
  done

  configure_client user "" "${KEYCLOAK_USER_CLIENT_SECRET}" \
    "${KEYCLOAK_USER_BASE_URL}" "${KEYCLOAK_USER_REDIRECT_URI}"
  configure_client admin Administration "${KEYCLOAK_ADMIN_CLIENT_SECRET}" \
    "${KEYCLOAK_ADMIN_BASE_URL}" "${KEYCLOAK_ADMIN_REDIRECT_URI}"

  asb_sync_uuid="$(find_client_uuid user asb-hh-mitte-user-sync)"
  if [[ -z "${asb_sync_uuid}" ]]; then
    echo "ASB-Realm-Konfiguration fehlgeschlagen: User-Synchronisierungsclient fehlt." >&2
    return 1
  fi
  /opt/keycloak/bin/kcadm.sh update "clients/${asb_sync_uuid}" \
    --config "${asb_kcadm_config}" -r user \
    -s "secret=${KEYCLOAK_SYNC_CLIENT_SECRET}" >/dev/null

  # Remove the stored Admin CLI token after configuration.
  rm -f "${asb_kcadm_config}"
  echo "ASB HH Mitte: User- und Admin-Realm konfiguriert."
}

trap stop_keycloak EXIT
trap 'exit 143' TERM
trap 'exit 130' INT

/opt/keycloak/bin/kc.sh "$@" &
asb_server_pid=$!

configure_realms
wait "${asb_server_pid}"
