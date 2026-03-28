#!/bin/bash
#this script is designed to test the feasbiltiy of getting an array of all Disk Names and Vomue UUIDs

echo "Begining script $0"

# Checking Flags ======================================

verbose=false
force=false
drive_filter_number=1

# Define the flags the script accepts. A colon (:) after a flag means it requires an argument.
# In this example:
# -v does not require an argument
# -f requires an argument
while getopts ":vfd:" flag; do
	case "${flag}" in
		v)
			verbose=true
		;;
	 	f)
			force=true
		;;
		d)
			drive_filter_number="${OPTARG}"
		;;
		*)
			# Handle invalid options
			echo "Invalid option: -${OPTARG}" >&2
			exit 1
		;;
	esac
done

if [ "$verbose" = true ]; then echo "Verbose = ${verbose}"; fi
if [ "$verbose" = true ]; then echo "Force = ${force}"; fi
if [ "$verbose" = true ]; then echo "Drive Filter = ${drive_filter_number}"; fi

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

# Getting Volume List =========================

volume_UUID_array=()

echo "Getting volume UUIDs from filtered disk array"
for disk in "${filtered_disk_array[@]}"; do
	echo "Filtered Disk: $disk"

	echo "Creating disk list for $disk"
	diskutil list -plist "$disk" > "${disk}List.xml"
	echo "Created disk list for $disk"

	echo "Creating volume list for $disk"
	echo "<root>" > "${disk}volumeList.xml"
	xpath -q -e "//dict[key/text()='VolumeUUID']" "${disk}List.xml" >> "${disk}volumeList.xml"
	echo "</root>" >> "${disk}volumeList.xml"
	echo "Created volume list for $disk"

	echo "Creating volume UUID list for $disk"
	xpath -q -e "/root/dict/string[last()]/text()" "${disk}volumeList.xml" > "${disk}volumeUUIDList.txt"
	echo "Created volume UUID list for $disk"

	echo "Adding volume UUIDs from $disk to array"
	while IFS= read -r line; do
		volume_UUID_array+=("$line")
	done < "${disk}volumeUUIDList.txt"
	echo "Added volume UUIDs from $disk to array"

done
echo "Got volume UUIDs from filtered disk array"

for volume in "${volume_UUID_array[@]}"; do
	echo "Volume: $volume"
done

# Erasing Volumes ======================

echo "Erasing all volumes"
for volume in "${volume_UUID_array[@]}"; do
	echo "Eraseing volume $volume"
	diskutil eraseVolume MS-DOS iPod "$volume"
	echo "Erased volume $volume"
done
echo "Erased all volumes"

# Ejecting Disks ======================

echo "Ejecting all disks"
echo "Starting eject 1"
for disk in "${filtered_disk_array[@]}"; do
	diskutil eject "$disk"
done
echo "Finished eject 1"

echo "Waiting for 1 minute for all disks to reconnect"
sleep 60

echo "Starting eject 2"
for disk in "${filtered_disk_array[@]}"; do
	diskutil eject "$disk"
done
echo "Finished eject 2"

echo "All iPods should be restored now"
