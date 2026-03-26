#!/bin/bash
#this script is designed to test the feasbiltiy of getting an array of all Disk Names and Vomue UUIDs

echo "Begining script $0"

echo "Getting Disk List"
diskutil list -plist > diskList.xml
echo "Created Disk List"

echo "Getting Volume List"
echo "<root>" > "volumeList.xml"
xpath -e "//dict[key/text()='VolumeUUID']" "diskList.xml" >> "volumeList.xml"
echo "</root>" >> "volumeList.xml"
echo "created Volume List"

echo "Getting Volume UUIDs"
xpath -e "/root/dict/string[last()]/text()" "volumeList.xml" > "volumeUUIDList.txt"
echo "Created Volume UUIDs List"

echo "Getting Disk Names"
xpath -e "//array[last()]/string/text()" "diskList.xml" > "diskNameList.txt"

echo "Creating Array"

my_disk_array=()

while IFS= read -r line; do
        my_disk_array+=("$line")
done < "diskNameList.txt"

disk_array_length=${#my_disk_array[@]}
echo "Disk Array length: $disk_array_length"

my_volume_array=()

while IFS= read -r line; do
	my_volume_array+=("$line")
done < "volumeUUIDList.txt"

volume_array_length=${#my_volume_array[@]}
echo "Volume Array length: $volume_array_length"


echo "Looping through disk array"

for item in "${my_disk_array[@]}"; do
        echo "Disk: $item"
done

echo "Finished Looping throug disk Array"


echo "Looping through volume array"

for item in "${my_volume_array[@]}"; do
	echo "Volume UUID: $item"
done

echo "Finished Looping throug volume Array"

echo "Exiting Script $0"
