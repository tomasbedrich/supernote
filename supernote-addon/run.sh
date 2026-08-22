#!/bin/bash
set -euo pipefail

OPTIONS_FILE=/data/options.json
BOOTSTRAP_MARKER=/data/.admin_bootstrapped

get_option() {
  jq -r --arg key "$1" 'if has($key) then (.[$key] // "") else "" end' "$OPTIONS_FILE"
}

export SUPERNOTE_STORAGE_DIR="/data/storage"
export SUPERNOTE_CONFIG_DIR="/data/config"
export SUPERNOTE_HOST="0.0.0.0"
export SUPERNOTE_PORT="${SUPERNOTE_PORT:-8080}"
export SUPERNOTE_MCP_PORT="${SUPERNOTE_MCP_PORT:-8081}"

mkdir -p "$SUPERNOTE_STORAGE_DIR" "$SUPERNOTE_CONFIG_DIR"

set_env_if_present() {
  # $1: option name in options.json, $2: env var name to export
  local value
  value="$(get_option "$1")"
  if [ -n "$value" ]; then
    export "$2=$value"
  fi
}

set_env_if_present base_url SUPERNOTE_BASE_URL
set_env_if_present jwt_secret SUPERNOTE_JWT_SECRET
set_env_if_present enable_registration SUPERNOTE_ENABLE_REGISTRATION
set_env_if_present enable_remote_password_reset SUPERNOTE_ENABLE_REMOTE_PASSWORD_RESET
set_env_if_present gemini_api_key SUPERNOTE_GEMINI_API_KEY
set_env_if_present gemini_ocr_model SUPERNOTE_GEMINI_OCR_MODEL
set_env_if_present gemini_embedding_model SUPERNOTE_GEMINI_EMBEDDING_MODEL

initial_admin_email="$(get_option initial_admin_email)"
initial_admin_password="$(get_option initial_admin_password)"

if [ -n "$initial_admin_email" ] && [ -n "$initial_admin_password" ] && [ ! -f "$BOOTSTRAP_MARKER" ]; then
  (
    echo "[bootstrap] Waiting for server to become ready to create initial admin user..."
    for _ in $(seq 1 60); do
      if curl -sf "http://127.0.0.1:${SUPERNOTE_PORT}/" >/dev/null 2>&1; then
        if supernote admin --url "http://127.0.0.1:${SUPERNOTE_PORT}" user add \
          "$initial_admin_email" --password "$initial_admin_password"; then
          touch "$BOOTSTRAP_MARKER"
          echo "[bootstrap] Initial admin user '$initial_admin_email' created."
        else
          echo "[bootstrap] Failed to create initial admin user (it may already exist)."
        fi
        exit 0
      fi
      sleep 1
    done
    echo "[bootstrap] Server did not become ready in time; skipping admin bootstrap."
  ) &
fi

exec supernote-server serve
