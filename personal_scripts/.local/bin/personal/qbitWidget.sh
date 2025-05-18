#!/bin/sh

qbt torrent list --format json | grep state |
	sed "
	s/.*pausedDL.*/A 🛑/;
	s/.*uploading.*/Z 🌱/;
	s/.*pausedUP.*/N ✅/;
	s/.*stalledUP.*/R 🕰️/;
	s/.*stalledDL.*/B 🕰️/
	s/.*error.*/M ❗/;
  s/.*pausedDL.*/N ⬇️/;
	s/.*metaDL.*/N ⬇️/;
	s/.*downloading.*/M ⬇️/;
	s/.*queuedDL.*/M ⬇️/;" |
	sort -h |
  uniq -c |
  awk '{print $3 $1}' |
  paste -sd ' '
