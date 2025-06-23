#!/usr/bin/env bash
#
# disk-utility-helper.sh
# A friendly wrapper around macOS "diskutil" for the most frequent maintenance tasks.
#
# Usage examples
#   ./disk-utility-helper.sh list
#   sudo ./disk-utility-helper.sh verify /dev/disk2
#   sudo ./disk-utility-helper.sh repairVolume /Volumes/Backup
#   sudo ./disk-utility-helper.sh erase /dev/disk4 "MyUSB" JHFS+
#   sudo ./disk-utility-helper.sh image /dev/disk2 ./disk2_backup.dmg
#
# NOTE: Many operations require sudo (administrator privileges).

set -euo pipefail

#######################################
# Print usage and quit
#######################################
usage() {
  cat <<EOF
Usage: $0 <command> [arguments]

Commands
  list                                   List all disks and partitions.
  info        <identifier|mount_point>   Show detailed info (e.g. disk2 or /Volumes/Macintosh\ HD).
  verify       <identifier|mount_point>   Verify a disk or volume.
  repair       <identifier|mount_point>   Repair a disk or volume.
  verifyVolume <mount_point>              Verify a *mounted* volume (e.g. /).
  repairVolume <mount_point>              Repair a *mounted* volume.
  mount        <identifier>              Mount a disk (by identifier).
  unmount      <identifier|mount_point>  Unmount a disk or volume.
  erase        <identifier> <name> <fs>  Erase/format a disk. Example fs: JHFS+, APFS, exFAT
  image        <identifier> <outfile.dmg> Create a read-only disk image backup.
  restore      <in.dmg>    <identifier>   Restore a disk image onto a target disk.
  help                                   Show this help.

Examples
  sudo $0 verify /dev/disk2
  sudo $0 erase /dev/disk4 "MyUSB" exFAT
EOF
}

#######################################
# Ensure at least one argument
#######################################
[[ $# -lt 1 ]] && { usage; exit 1; }

cmd="$1"; shift || true

#######################################
# Command implementations
#######################################
case "$cmd" in
  list)
    diskutil list
    ;;

  info)
    [[ $# -ne 1 ]] && { echo "Need disk identifier or mount point"; exit 1; }
    diskutil info "$1"
    ;;

  verify|repair)
    [[ $# -ne 1 ]] && { echo "Need disk identifier or mount point"; exit 1; }
    diskutil "$cmd" "$1"
    ;;

  verifyVolume|repairVolume)
    [[ $# -ne 1 ]] && { echo "Need mount point (e.g. /Volumes/Data)"; exit 1; }
    diskutil "$cmd" "$1"
    ;;

  mount|unmount)
    [[ $# -ne 1 ]] && { echo "Need disk identifier or mount point"; exit 1; }
    diskutil "$cmd" "$1"
    ;;

  erase)
    [[ $# -ne 3 ]] && { echo "Need identifier, newName, and filesystem type"; exit 1; }
    diskutil eraseDisk "$3" "$2" "$1"
    ;;

  image)
    [[ $# -ne 2 ]] && { echo "Need source identifier and output dmg path"; exit 1; }
    hdiutil create -srcdevice "$1" -format UDZO "$2"
    ;;

  restore)
    [[ $# -ne 2 ]] && { echo "Need dmg path and target identifier"; exit 1; }
    hdiutil restore -source "$1" -target "$2" -erase
    ;;

  help|-h|--help)
    usage
    ;;

  *)
    echo "Unknown command: $cmd"; usage; exit 1;
    ;;
esac