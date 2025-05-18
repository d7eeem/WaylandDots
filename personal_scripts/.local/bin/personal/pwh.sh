#!/bin/sh
if [ -n "$1" ];
then 
  pwd | echo -n $(sed -e 's/\/home\/id7eeem/$HOME/g')/$1 | wl-copy
else
pwd | sed -e 's/\/home\/id7eeem/$HOME/g' | wl-copy
fi
