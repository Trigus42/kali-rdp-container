#!/usr/bin/env bash
set -e

# Default environment variable values
if [[ -z "${RAW_MOUNT}" ]]; then
    RAW_MOUNT="/workspace/host-unencrypted"
fi
if [[ -z "${ENCRYPTED_MOUNT}" ]]; then
    ENCRYPTED_MOUNT="/workspace/host-encrypted"
fi
if [[ -z "${ENCRYPTED_FOLDER_NAME}" ]]; then
    ENCRYPTED_FOLDER_NAME="kali-encrypted-mount"
fi

CIPHER_DIR="${RAW_MOUNT}/${ENCRYPTED_FOLDER_NAME}"
MOUNT_DIR="${ENCRYPTED_MOUNT}"

if [[ -z "${GOCRYPTFS_PASSWORD}" ]]; then
    echo "GOCRYPTFS_PASSWORD is not set. Skipping encrypted volume setup."
    exit 0
fi

mkdir -p "${CIPHER_DIR}" "${MOUNT_DIR}"

# Initialize the encrypted filesystem if not already done
if [[ ! -f "${CIPHER_DIR}/gocryptfs.conf" ]]; then
    echo "Initializing gocryptfs encrypted filesystem..."
    mkdir -p "${CIPHER_DIR}"
    echo "${GOCRYPTFS_PASSWORD}" | gocryptfs -init -q -nosyslog "${CIPHER_DIR}"
fi

# Mount the encrypted filesystem in foreground (logs to stdout/stderr)
echo "Mounting encrypted filesystem at ${MOUNT_DIR}"
echo "${GOCRYPTFS_PASSWORD}" | gocryptfs -fg -nosyslog "${CIPHER_DIR}" "${MOUNT_DIR}"
