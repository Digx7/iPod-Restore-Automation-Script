#!/bin/bash
#this script is designed to test the feasbiltiy of getting an array of all Disk Names and Vomue UUIDs

echo "Begining script $0"

# Getting Disk List =======================

echo "Getting Disk List"
diskutil list -plist > diskList.xml
echo "Created Disk List"

echo "Getting Disk Names"
xpath -q -e "//array[last()]/string/text()" "diskList.xml" > "diskNameList.txt"

echo "Creating Array"

initial_disk_array=()
filtered_disk_array=()

while IFS= read -r line; do
        initial_disk_array+=("$line")
done < "diskNameList.txt"

disk_array_length=${#my_disk_array[@]}
echo "Disk Array length: $disk_array_length"

echo "Looping through initial disk array"
for disk in "${initial_disk_array[@]}"; do
	echo "Disk: $disk"
	if [[ "$disk" != "disk"[0-1]* ]]; then
		echo "Should add disk to filter"
		filtered_disk_array+=("$disk")
	fi
done
echo "Finished looping through initial disk array"

echo "Looping through filtered disk array"
for disk in "${filtered_disk_array[@]}"; do
	echo "Filtered Disk: $disk"
done
echo "Finished looping through filtered disk array"

# Ejecting Disks ======================

echo "Ejecting all disks"
echo "Starting eject 1"
for disk in "${filtered_disk_array[@]}"; do
	diskutil eject "$disk"
done
echo "Finished eject 1"

echo "All iPods should be ejected now"
