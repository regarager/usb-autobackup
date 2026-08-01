#!/usr/bin/env bash
set -euo pipefail

USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
HOME="$USER_HOME"
CONFIG_FILE="$USER_HOME/.config/usb-backup/usb-backup.conf"

# Load config file 
if [ -f "$CONFIG_FILE" ]; then 
	source "$CONFIG_FILE"
else
	echo "ERROR: Config file not found at ${CONFIG_FILE}." >&2
	exit 1
fi 

# Validating required variables
if [ -z "${TARGET_UUID}" ]; then
	echo "ERROR: TARGET_UUID is not set in ${CONFIG_FILE}." >&2
	exit 1
elif [ -z "${MOUNT_POINT}" ]; then
	echo "ERROR: MOUNT_POINT is not set in ${CONFIG_FILE}." >&2
	exit 1
elif [ -z "${BACKUP_DIR}" ]; then
	echo "ERROR: BACKUP_DIR is not set in ${CONFIG_FILE}."  >&2
	exit 1
elif [ "${FILEPATHS[@]}" -eq 0 ]; then
	echo "ERROR: no filepaths set in ${CONFIG_FILE}." >&2
fi 


mkdir -p "$MOUNT_POINT"
if ! mountpoint -q "$MOUNT_POINT"; then
	mount /dev/disk/by-uuid/"$TARGET_UUID" "$MOUNT_POINT"
fi 

cleanup() {
	if mountpoint -q "$MOUNT_POINT"; then
		umount "$MOUNT_POINT"
	fi 

}
trap cleanup EXIT



DESTINATION_DIR="$MOUNT_POINT/$BACKUP_DIR"
mkdir -p "$DESTINATION_DIR"

for ITEM in "${#FILEPATHS[@]}"; do 
	if [ -e "$ITEM" ]; then
		rsync -rtv --no-perms --no-owner --no-group --delete "$ITEM" "$DESTINATION_DIR"
	else
		echo "WARNING: $ITEM does not exist, skipping."
	fi 
done

echo "Backup complete!"
