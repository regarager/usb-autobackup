#!/usr/bin/env bash
set -euo pipefail

# External drive identifier
# replace TARGET_UUID with your drive's UUID (lsblk -f)
TARGET_UUID = ""
MOUNT_POINT = "/mnt/usb_backup"
BACKUP_DIR = "backups"

# Paths to files you want to back up 
FILEPATHS = (
	"$HOME/Documents"

	)

mkdir -p "$MOUNT_POINT"
if ! mountpoint -q "$MOUNT_POINT"; then
	mount /dev/disk/by-uuid/"$TARGET_UUID" "$MOUNT_POINT"
fi 

cleanup() {
	if mountpoint -q "$MOUNT_POINT"; then
		unmount "$MOUNT_POINT"
	fi 

}
trap cleanup EXIT



DESTINATION_DIR = "$MOUNT_POINT/$BACKUP_DIR"
mkdir -p "$DESTINATION_DIR"

for ITEM in "$FILEPATHS"; do 
	if [ -e "$ITEM" ]; then
		rsync -av --relative --delete "$ITEM" "$DESTINATION_DIR"
	else
		echo "WARNING: $ITEM does not exist, skipping."
	fi 
done

echo "Backup complete!"
