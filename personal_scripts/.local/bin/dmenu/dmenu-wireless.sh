#!/bin/env bash

IFS=$'\n'

get_conection() {
	conections=$(nmcli -g UUID c)
	for conection in ${conections[@]}; do
		readarray -t data <<< $(nmcli -g connection.interface-name,802-11-wireless.ssid c show uuid $conection)
		if [ ${data[0]} = $1 ]; then
			if [ ${data[1]} = $2 ]; then
				echo $conection
				return
			fi
		fi
	done
}

readarray -t devices <<< $(nmcli -g DEVICE,TYPE d)
for device in ${devices[@]}; do
	readarray -d : -t data <<< $device
	if [ ${data[1]} = "wifi" ]; then
		available_devices+=(${data[0]})
	fi
done

amount=${#available_devices[@]}
if [ $amount = 0 ]; then
	echo "Device not found  "
elif [ $amount = 1 ]; then
	device=${available_devices[0]}
else
	device=$(printf "%s\n" ${available_devices[@]} | dmenu -c $@)
fi
if [ -z $device ]; then
	exit
fi

echo "Scanning  "
readarray -t access_points <<< $(nmcli -g SSID d wifi list --rescan yes ifname $device)

amount=${#access_points[@]}
if [ $amount = 0 ]; then
	echo "Access point not found"
else
	access_point=$(printf "%s\n" ${access_points[@]} | dmenu -p "Which one?" -c $@)
fi
if [ -z $access_point ]; then
	exit
fi

conection=$(get_conection $device $access_point)
if [ $conection ]; then
	echo "Connecting ($access_point)  "
	ret=$(nmcli c up uuid $conection 2>&1)
	if [[ $ret == *"Error"* ]]; then
		echo "Connection failed"
	else
		echo "Connected ($access_point)  "
	fi
	exit
fi

password=$(printf "" | dmenu -c -P -p Password $@)
echo "Connecting ($access_point)  "
if [ "$password" ]; then
	ret=$(nmcli d wifi connect $access_point password $password ifname $device 2>&1)
else
	ret=$(nmcli d wifi connect $access_point ifname $device 2>&1)
fi
if [[ $ret == *"Error"* ]]; then
	echo "Connection failed"
	conection=$(get_conection $device $access_point)
	if [ $conection ]; then
		$(nmcli c delete $conection)
	fi
else
	echo "Connected ($access_point)  "
fi
