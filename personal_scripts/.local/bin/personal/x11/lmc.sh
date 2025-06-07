#!/bin/env bash


# Uncomment the following line to use Pulseaudio.
# PULSE=true

	toggle() { pamixer -t ;}
	mute() { pamixer -m  ;}
	up() { pamixer -i 5 ;}
	down() { pamixer -d 5 ;}
	control() { alsamixer ;}

case "$1" in
	toggle) toggle ;;
	mute) mute ;;
	up) up ;;
	down) down ;;
	control) control ;;
esac
