#!/bin/bash
# This script takes an identifier for a given disk and volume
# It first erases the volume then ejects the disk twice
# It takes the form
# iPod_Restore.sh <Disk ID> <Volume ID> <Format>

echo "Erasing the volume $2 from disk $1 using the format $3

diskutil eraseVolume $3 iPod $2

echo "volume $2 from disk $1 is erased"
echo "Ejecting disk $1"

diskutil eject $1

echo "Waiting 30 seconds for disk $1 to reconnect"

sleep 30

echo "Ejecting disk $1"

diskutil eject $1

echo "Volume $2 from disk $1 should now be full erased and restored"

