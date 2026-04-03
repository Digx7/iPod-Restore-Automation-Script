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
if [ "$verbose" = true ]; then echo "Created Disk List"; fi

if [ "$verbose" = true ]; then echo "Getting Disk Names"; fi
xpath -q -e "//array[last()]/string/text()" "diskList.xml" > "diskNameList.txt"

if [ "$verbose" = true ]; then echo "Creating Array"; fi

initial_disk_array=()
filtered_disk_array=()

while IFS= read -r line; do
        initial_disk_array+=("$line")
done < "diskNameList.txt"

disk_array_length=${#initial_disk_array[@]}
if [ "$verbose" = true ]; then echo "Disk Array length: $disk_array_length"; fi

if [ "$verbose" = true ]; then echo "Looping through initial disk array"; fi
for disk in "${initial_disk_array[@]}"; do
	if [ "$verbose" = true ]; then echo "Disk: $disk"; fi

	if [[ "$disk" != "disk"[0-$drive_filter_number]* ]]; then
		if [ "$verbose" = true ]; then echo "Should add disk to filter"; fi
		filtered_disk_array+=("$disk")
	fi
done
if [ "$verbose" = true ]; then echo "Finished looping through initial disk array"; fi

if [ "$verbose" = true ]; then echo "Looping through filtered disk array"; fi
for disk in "${filtered_disk_array[@]}"; do
	echo "Filtered Disk: $disk"
done
if [ "$verbose" = true ]; then echo "Finished looping through filtered disk array"; fi

# echo "Exting Early for Dev reasons"
# echo "We need to veirfy that the disk filtering using variables is working as expected"
# exit 0

# Getting Volume List =========================

volume_UUID_array=()

if [ "$verbose" = true ]; then echo "Getting volume UUIDs from filtered disk array"; fi
for disk in "${filtered_disk_array[@]}"; do
	if [ "$verbose" = true ]; then echo "Filtered Disk: $disk"; fi

	if [ "$verbose" = true ]; then echo "Creating disk list for $disk"; fi
	diskutil list -plist "$disk" > "${disk}List.xml"
	if [ "$verbose" = true ]; then echo "Created disk list for $disk"; fi

	#TODO: validate if partition schema is good

	echo "<root>" > "${disk}PartitionsAndVolumeList.xml"
	xpath -q -e "//dict/array/dict[key/text()='Content']" "${disk}List.xml" >> "${disk}PartitionsAndVolumeList.xml"
	echo "</root>" >> "${disk}PartitionsAndVolumeList.xml"

	partitionType=$(xpath -q -e "/root/dict[1]/string[1]/text()" "${disk}PartitionsAndVolumeList.xml")

	echo "$disk partition type is $partitionType"

	if [[ $partitionType == "FDisk_partition_scheme" ]]; then
		echo "$disk partition type is valid adding volume"

		if [ "$verbose" = true ]; then echo "Creating volume list for $disk"; fi
		echo "<root>" > "${disk}volumeList.xml"
		xpath -q -e "//dict[key/text()='VolumeUUID']" "${disk}List.xml" >> "${disk}volumeList.xml"
		echo "</root>" >> "${disk}volumeList.xml"
		if [ "$verbose" = true ]; then echo "Created volume list for $disk"; fi

		if [ "$verbose" = true ]; then echo "Creating volume UUID list for $disk"; fi
		xpath -q -e "/root/dict/string[last()]/text()" "${disk}volumeList.xml" > "${disk}volumeUUIDList.txt"
		if [ "$verbose" = true ]; then echo "Created volume UUID list for $disk"; fi

		if [ "$verbose" = true ]; then echo "Adding volume UUIDs from $disk to array"; fi
		while IFS= read -r line; do
			volume_UUID_array+=("$line")
		done < "${disk}volumeUUIDList.txt"
		if [ "$verbose" = true ]; then echo "Added volume UUIDs from $disk to array"; fi

	else
		echo "$disk partition type is INVALID not adding volume"

	fi

done
if [ "$verbose" = true ]; then echo "Got volume UUIDs from filtered disk array"; fi

for volume in "${volume_UUID_array[@]}"; do
	echo "Volume: $volume"
done

if [ "$force" = false ]; then
	read -p "Do you want to erase the above volumes? (Y/N): " choice
	if [[ $choice != [Yy] ]]; then
		echo "Exiting script"
		exit 0
	fi
else
	if [ "$verbose" = true ]; then echo "Force flag is set to true, skipping confirmation"; fi
fi

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
