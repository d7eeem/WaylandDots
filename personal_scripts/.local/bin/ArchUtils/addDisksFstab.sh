#!/bin/env bash

set -e 

create-dirs(){
mkdir /mnt/windows
mkdir /mnt/gamesav
mkdir /mnt/dataset
}

export -f create-dirs

create-dirs
su 
cat <<EOF >> ./test




#USER
UUID=86969930969921AB   /mnt/windows   ntfs uid=1000,gid=1000,rw,user,exec,umask=000 0 0
UUID=F8A424A9A4246BF6   /mnt/gamesav   ntfs uid=1000,gid=1000,rw,user,exec,umask=000 0 0
UUID=7AD06946D0690A29   /mnt/dataset   ntfs uid=1000,gid=1000,rw,user,exec,umask=000 0 0 
EOF
