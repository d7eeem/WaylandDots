#!/bin/sh

# Module showing network traffic. Shows how much data has been received (RX) or
# transmitted (TX) since the previous time this script ran. So if run every
# second, gives network traffic per second.

update() {
    sum=0
    for arg; do
        read -r i < "$arg"
        sum=$(( sum + i ))
    done
    cache=${XDG_CACHE_HOME:-$HOME/.cache}/${1##*/}
    [ -f "$cache" ] && read -r old < "$cache" || old=0
    printf %d\\n "$sum" > "$cache"
    printf %d\\n $(( sum - old ))
}

rx=$(update /sys/class/net/[ew]*/statistics/rx_bytes)
tx=$(update /sys/class/net/[ew]*/statistics/tx_bytes)

printf " %4sB  %4sB\\n" $(numfmt --to=iec $rx) $(numfmt --to=iec $tx)
