#!/usr/bin/env bash
set -e

if [[ ${SYNCTHING_ENABLE} != 'true' ]]; then
    echo "SYNCTHING_ENABLE is not set to 'true'. Skipping Syncthing startup."
    exit 0
fi

SYNCTHING_CONFIG="${STHOMEDIR}/config.xml"
SYNC_DIR="${SYNCTHING_SYNC_DIR:-/workspace/syncthing}"

# If gocryptfs is enabled, wait for the encrypted mount before continuing
if [[ -n "${GOCRYPTFS_PASSWORD}" ]]; then
    ENCRYPTED_MOUNT="${ENCRYPTED_MOUNT:-/workspace/host-encrypted}"
    echo "Waiting for gocryptfs mount at ${ENCRYPTED_MOUNT}..."
    while ! mountpoint -q "${ENCRYPTED_MOUNT}" 2>/dev/null; do
        sleep 1
    done
    echo "gocryptfs mount detected."
fi

mkdir -p "${STHOMEDIR}" "${SYNC_DIR}"
chown -R kali:kali "${STHOMEDIR}" "${SYNC_DIR}"

# Generate default config if it doesn't exist
if [[ ! -f "${SYNCTHING_CONFIG}" ]]; then
    su -s /bin/bash -c "syncthing generate --no-default-folder" kali
fi

chown -R kali:kali "${STHOMEDIR}"

# Print the device ID for easy pairing (write to container stdout so it appears in `docker logs`)
DEVICE_ID=$(su -s /bin/bash -c "syncthing --device-id" kali)
echo "==============================================" > /proc/1/fd/1
echo "Syncthing Device ID: ${DEVICE_ID}"            > /proc/1/fd/1
echo "Web UI: http://localhost:8384"                 > /proc/1/fd/1
echo "==============================================" > /proc/1/fd/1

# Start Syncthing in the background
su -s /bin/bash -c "syncthing serve --no-browser" kali &
SYNCTHING_PID=$!

# Wait for the REST API to become available
echo "Waiting for Syncthing API..."
until su -s /bin/bash -c "syncthing cli show system" kali &>/dev/null; do
    sleep 1
done
echo "Syncthing API is ready."

# Add default shared folder via CLI if not already present
if ! su -s /bin/bash -c "syncthing cli config folders list" kali 2>/dev/null | grep -q 'kali-workspace-sync'; then
    echo "Adding workspace shared folder..."
    su -s /bin/bash -c "syncthing cli config folders add \
        --id kali-workspace-sync \
        --label workspace \
        --path '${SYNC_DIR}' \
        --type sendreceive \
        --rescan-intervals 60 \
        --fswatcher-enabled \
        --fswatcher-delays 10 \
        --auto-normalize" kali
    echo "Workspace folder added."
fi

# Keep the script in the foreground, following the Syncthing process
wait ${SYNCTHING_PID}
