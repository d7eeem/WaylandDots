#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem



ufw_list=(
  22
  8384
  27015:27050/udp
  27000:27036/udp
  3478
  4379
  4380
)


for port in "${ufw_list[@]}"; do
  sudo ufw allow "$port"
done

