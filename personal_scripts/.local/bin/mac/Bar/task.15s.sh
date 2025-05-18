#!/bin/bash

num=$(ts -l | awk -v numr=0 -v numq=0 '{if (/running/)numr++; if (/queued/)numq++} END{print numr+numq"("numq")"}')

if [ "$num" != "0(0)" ]; then
	echo "🤖$num"
else
	exit 0
fi
