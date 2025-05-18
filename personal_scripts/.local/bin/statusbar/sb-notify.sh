#!/bin/env bash

get_dunst_history() {
    dunstctl history | jq '.'
}

format_history() {
    local history="$1"
    local count
    local alt="none"
    local tooltip_click
    local tooltip=""
    local formatted_history

    # Extract notification count
    count=$(echo "$history" | jq '.data[0] | length')

    # Tooltip click actions (Unicode characters for icons)
    tooltip_click="\udb80\udf9f Notifications\n \udb83\udcfd <small>click-left: \uf1da history pop</small>\n \udb83\udcfd <small>click-middle: \udb81\udecc clear history</small>\n \udb83\udcfd <small>click-right: \udb84\udd0a close all</small>"

    if (( count > 0 )); then
        for ((i = 0; i < count; i++)); do
            local body
            local category
            body=$(echo "$history" | jq -r ".data[0][$i].body.data // \"\"")
            category=$(echo "$history" | jq -r ".data[0][$i].category.data // \"\"")
            if [[ -n "$category" ]]; then
                alt="${category}-notification"
                tooltip="${body} (${category})\n "
                break
            else
                alt="notification"
                if [[ -z "$tooltip" ]]; then
                    tooltip="${body}\n "
                fi
            fi
        done
    fi

    # Build the formatted JSON output
    formatted_history=$(jq -n --arg text "$count" \
                              --arg alt "$alt" \
                              --arg tooltip "$tooltip_click\n\n $tooltip" \
                              --arg class "$alt" \
                              '{text: $text, alt: $alt, tooltip: $tooltip, class: $class}')
    echo "$formatted_history"
}

main() {
    local history
    local formatted_history

    # Fetch notification history and format it
    history=$(get_dunst_history)
    formatted_history=$(format_history "$history")
    echo "$formatted_history"
}

main
