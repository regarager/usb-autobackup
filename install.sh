#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# usb-autobackup Installer Script
# This installer is 100% written using Gemini 
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This installer must be run as root (use sudo ./install.sh)." >&2
    exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
if [ "$REAL_USER" = "root" ]; then
    echo "ERROR: Please run this script with sudo as your regular user, not directly as root." >&2
    exit 1
fi

USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing usb-autobackup for user: $REAL_USER"

# 1. Install backup script to /usr/local/bin
echo "--> Installing main script to /usr/local/bin/usb-backup.sh..."
cp "$SCRIPT_DIR/usb-backup.sh" /usr/local/bin/usb-backup.sh
chmod +x /usr/local/bin/usb-backup.sh

# 2. Setup user configuration directory and default config
CONFIG_DIR="$USER_HOME/.config/usb-backup"
CONFIG_FILE="$CONFIG_DIR/usb-backup.conf"

if [ ! -d "$CONFIG_DIR" ]; then
    echo "--> Creating configuration directory at $CONFIG_DIR..."
    mkdir -p "$CONFIG_DIR"
    chown -R "$REAL_USER:$REAL_USER" "$CONFIG_DIR"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    if [ -f "$SCRIPT_DIR/usb-backup.conf.example" ]; then
        echo "--> Copying template to $CONFIG_FILE..."
        cp "$SCRIPT_DIR/usb-backup.conf.example" "$CONFIG_FILE"
        chown "$REAL_USER:$REAL_USER" "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE"
    else
        echo "--> Warning: usb-backup.conf.example not found."
    fi
else
    echo "--> Existing configuration found at $CONFIG_FILE (skipping overwrite)."
fi

# 3. Prompt for UUID option
read -rp "Enter your USB Drive UUID (press Enter to set it manually in $CONFIG_FILE later): " INPUT_UUID

if [ -n "$INPUT_UUID" ] && [ -f "$CONFIG_FILE" ]; then
    sed -i "s/TARGET_UUID=\".*\"/TARGET_UUID=\"$INPUT_UUID\"/" "$CONFIG_FILE" || true
    echo "--> Set TARGET_UUID in $CONFIG_FILE"
fi

RULE_UUID="${INPUT_UUID:-YOUR_USB_UUID_HERE}"

# 4. Install systemd service unit
SYSTEMD_SERVICE="/etc/systemd/system/usb-backup.service"
echo "--> Installing systemd service unit..."

cat <<EOF > "$SYSTEMD_SERVICE"
[Unit]
Description=Automated USB Backup Service
After=local-fs.target

[Service]
Type=oneshot
User=root
ExecStart=/usr/local/bin/usb-backup.sh
Environment="SUDO_USER=$REAL_USER"
Environment="HOME=$USER_HOME"

[Install]
WantedBy=multi-user.target
EOF

chmod 644 "$SYSTEMD_SERVICE"

# 5. Install udev rule
UDEV_RULE="/etc/udev/rules.d/99-usb-backup.rules"
echo "--> Installing udev rule..."

cat <<EOF > "$UDEV_RULE"
# udev rule for usb-autobackup
ACTION=="add", SUBSYSTEM=="block", ENV{ID_FS_UUID}=="$RULE_UUID", TAG+="systemd", ENV{SYSTEMD_WANTS}="usb-backup.service"
EOF

chmod 644 "$UDEV_RULE"

# 6. Reload systemd daemon and udev rules
echo "--> Reloading systemd daemon and udev rules..."
systemctl daemon-reload
udevadm control --reload-rules

echo "=============================================================================="
echo " Installation Complete!"
echo " Make sure your UUID in $UDEV_RULE and $CONFIG_FILE match your drive!"
echo "=============================================================================="

