#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem


df -t ext4 -t btrfs -t fuseblk -T -h | tr -s ' '   | jq -sR   'split("\n") |
      .[1:-1] |
      map(split(" ")) |
      map({"file_system": .[0],
           "file_system_type": .[1],
           "total": .[2],
           "used": .[3],
           "available": .[4],
           "used_percent": .[5],
           "mounted": .[6]})'
