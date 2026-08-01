# usb-autobackup
Script to automatically back up files whenever a specific external hard drive is plugged in on Arch systems.

# Setup & Configuration
Before running install.sh, plug in your desired external drive and run 'lsblk -f' to determine the UUID. After running install.sh, the configuration file should be under '~/.config/usb-backup.conf'. Enter the hard drive UUID in the TARGET_UUID field and populate the FILEPATHS variable with files/directories you want to back up.
Backups will be stored in the external drive in a folder named 'backups' by default.
