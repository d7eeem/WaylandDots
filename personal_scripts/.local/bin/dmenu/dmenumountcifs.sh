#!/bin/sh
# Gives a dmenu prompt to mount unmounted local NAS shares for read/write.
# Requirements - "%wheel ALL=(ALL) NOPASSWD: ALL"
#
# Browse for mDNS/DNS-SD services using the Avahi daemon...
srvname=$(avahi-browse _smb._tcp -t | awk '{print $4}' | dmenu -c -i -l 5 -p "Which NAS?") || exit 1
notify-send "Searching for network shares..." "Please wait..."
# Choose share disk...
share=$(smbclient -L "$srvname" -N | grep Disk | awk '{print $1}' | dmenu -c -i -l 5 -p "Mount which share?") || exit 1
# Format URL...
share2mnt=//"$srvname".local/"$share"

sharemount() {
	mounted=$(mount -v | grep "$share2mnt") || ([ ! -d /mnt/"$share" ] && sudo mkdir /mnt/"$share")
	[ -z "$mounted" ] && sudo mount -t cifs "$share2mnt" -o user=nobody,password="",noperm /mnt/"$share" && notify-send "Netshare $share mounted" && exit 0
	notify-send "Netshare $share already mounted"; exit 1
}

sharemount
