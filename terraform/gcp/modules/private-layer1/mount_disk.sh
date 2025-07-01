#!/bin/bash
# Mount GCP disk by disk name to /var/<module_name>, no partitioning

set -e

DISK_NAME="${1:-kaia-helper}"                         # e.g., device_name = "kaia-helper"
MODULE_NAME="${2:-kaia-helper}"                       # e.g., kcnd, kpnd, kend
MOUNT_POINT="/var/${MODULE_NAME}"
# GCP disk path pattern: /dev/disk/by-id/google-{disk_name}
DISK_PATH="/dev/disk/by-id/google-${DISK_NAME}"
FILESYSTEM="ext4"

echo "[INFO] Using disk: $DISK_PATH"
echo "[INFO] Mount point: $MOUNT_POINT"
echo "[INFO] Module name: $MODULE_NAME"

# Check if disk exists
if [ ! -L "$DISK_PATH" ]; then
  echo "[ERROR] Disk not found: $DISK_PATH"
  echo "[INFO] Available disks:"
  ls -la /dev/disk/by-id/google-* 2>/dev/null || echo "No google disks found"
  exit 1
fi

# Format disk if no filesystem exists
if ! blkid "$DISK_PATH" &>/dev/null; then
  echo "[INFO] No filesystem found. Creating $FILESYSTEM on $DISK_PATH"
  mkfs.$FILESYSTEM "$DISK_PATH"
else
  echo "[INFO] Filesystem already exists on $DISK_PATH"
fi

# Create and mount
mkdir -p "$MOUNT_POINT"
mount "$DISK_PATH" "$MOUNT_POINT"
echo "[INFO] Mounted $DISK_PATH to $MOUNT_POINT"

# Add to /etc/fstab
if ! grep -q "$DISK_PATH" /etc/fstab; then
  echo "$DISK_PATH $MOUNT_POINT $FILESYSTEM defaults 0 2" >> /etc/fstab
  echo "[INFO] fstab entry added"
fi