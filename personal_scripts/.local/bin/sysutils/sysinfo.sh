#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem

echo
echo
(
    uname -a
    (
        lsb_release -d || grep . /etc/*_version /etc/*-release
        grep . /sys/devices/virtual/dmi/id/{sys_vendor,product_{name,sku},board_name} | grep -vE 'illed|ystem'
    ) 2>/dev/null
    grep '^model n' /proc/cpuinfo | head -1
    grep -E '(Mem|Swap)Total' /proc/meminfo
    lspci | grep -E '[VX]GA|3D'
    echo $XDG_SESSION_TYPE
    glxinfo -B | grep -E 'Device:|Version:|GL (version|renderer) s'
    vulkaninfo --summary | grep -E 'deviceName|driverInfo'
    pactl info | grep "^Server N"
    mount | grep -E 'ntfs| on / '
) 2>&1 | sed -E -e 's/^\s*/    /'
echo
echo
