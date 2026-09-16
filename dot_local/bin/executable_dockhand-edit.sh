#!/usr/bin/env bash
#
# dockhand-edit.sh — edit a file inside a Dockhand-managed container or
# volume using your local $EDITOR instead of the web GUI.
#
# Requires: curl, jq
#
# Auth: Dockhand is assumed to sit behind Authelia ForwardAuth. Rather than
# scraping a browser session cookie (short-lived, single-login), this uses
# a dedicated Authelia service account over HTTP Basic Auth, per Authelia's
# own guide for scripted access:
# https://www.authelia.com/integration/guides/securing-apps-with-basic-auth/
#
# Config (env vars):
#   DOCKHAND_URL       e.g. https://dockhand.example.com
#   DOCKHAND_USER      Authelia service account username
#   DOCKHAND_PASSWORD  Authelia service account password
#   DOCKHAND_ENV       environment id (optional, only if you have multiple)
#
# Usage:
#   dockhand-edit.sh container <container_id> <path/in/container>
#   dockhand-edit.sh volume <volume_name> <path/in/volume>

set -euo pipefail

MODE="${1:?mode: container|volume}"
TARGET="${2:?container id or volume name}"
FPATH="${3:?path to file}"
EDITOR="${EDITOR:-nano}"

: "${DOCKHAND_URL:?set DOCKHAND_URL}"
: "${DOCKHAND_USER:?set DOCKHAND_USER}"
: "${DOCKHAND_PASSWORD:?set DOCKHAND_PASSWORD}"

ENV_QS=""
if [[ -n "${DOCKHAND_ENV:-}" ]]; then
  ENV_QS="&env=${DOCKHAND_ENV}"
fi

curl_json() {
  curl -sS -u "${DOCKHAND_USER}:${DOCKHAND_PASSWORD}" "$@"
}

# Pure bash/jq URL-encoding, avoids a python3 dependency.
urlencode() {
  jq -rn --arg s "$1" '$s|@uri'
}

case "$MODE" in
  container)
    CONTAINER_ID="$TARGET"
    READ_URL="${DOCKHAND_URL}/api/containers/${CONTAINER_ID}/files/content?path=$(urlencode "$FPATH")${ENV_QS}"
    WRITE_URL="$READ_URL"
    ;;
  volume)
    VOLUME_NAME="$TARGET"
    # Trigger the volume browse first so a helper container exists,
    # and grab its id so we can write through the container endpoint.
    BROWSE_URL="${DOCKHAND_URL}/api/volumes/${VOLUME_NAME}/browse?path=$(urlencode "$(dirname "$FPATH")")${ENV_QS}"
    HELPER_ID="$(curl_json "$BROWSE_URL" | jq -r '.helperId')"
    if [[ -z "$HELPER_ID" || "$HELPER_ID" == "null" ]]; then
      echo "Could not resolve helper container for volume ${VOLUME_NAME}" >&2
      exit 1
    fi
    ENC_PATH="$(urlencode "$FPATH")"
    READ_URL="${DOCKHAND_URL}/api/volumes/${VOLUME_NAME}/browse/content?path=${ENC_PATH}${ENV_QS}"
    WRITE_URL="${DOCKHAND_URL}/api/containers/${HELPER_ID}/files/content?path=${ENC_PATH}${ENV_QS}"
    ;;
  *)
    echo "mode must be 'container' or 'volume'" >&2
    exit 1
    ;;
esac

TMP="$(mktemp --suffix="-$(basename "$FPATH")")"
trap 'rm -f "$TMP"' EXIT

echo "Fetching ${FPATH} ..."
curl_json "$READ_URL" | jq -r '.content' > "$TMP"

CHECKSUM_BEFORE="$(sha256sum "$TMP" | awk '{print $1}')"

"$EDITOR" "$TMP"

CHECKSUM_AFTER="$(sha256sum "$TMP" | awk '{print $1}')"

if [[ "$CHECKSUM_BEFORE" == "$CHECKSUM_AFTER" ]]; then
  echo "No changes made — not writing back."
  exit 0
fi

echo "Writing changes back to ${FPATH} ..."
CONTENT_JSON="$(jq -Rs '{content: .}' < "$TMP")"

curl -sS -X PUT \
  -u "${DOCKHAND_USER}:${DOCKHAND_PASSWORD}" \
  -H "Content-Type: application/json" \
  -d "$CONTENT_JSON" \
  "$WRITE_URL" | jq .

echo "Done."