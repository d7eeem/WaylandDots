#!/bin/bash
upload() {
    RESPONSE="$(curl -s -F "token=token_5583ed0627e4d9067369a7d26a3bb934" -F "upload=@${1}" https://xback.aloqaili.xyz/upload)";

    if [[ "$(echo "${RESPONSE}" | jq -r '.message')" == "OK" ]]; then
        URL="$(echo "${RESPONSE}" | jq -r '.url')";
        if [ "${DESKTOP_SESSION}" != "" ]; then
            echo "${URL}" | wl-copy;
            notify-send "Upload completed" "<a href='${URL}'>${URL}</a>";
        else
            echo "${URL}" && notify-send "Upload completed" "<a href='${URL}'>${URL}</a>" || notify-send "Upload completed" "<a href='${URL}'>${URL}</a>"
        fi
        exit 0;
    else
        MESSAGE="$(echo "${RESPONSE}" | jq -r '.message')";
        if [ $? -ne 0 ]; then
            echo "Unexpected response:";
            echo "${RESPONSE}";
            exit 1;
        fi
        if [ "${DESKTOP_SESSION}" != "" ]; then
            notify-send "Error!" "${MESSAGE}";
        else
            echo "Error! ${MESSAGE}";
        fi
        exit 1;
    fi
}

check() {
    ERRORS=0;

    if [ ! -x "$(command -v jq)" ]; then
        echo "jq command not found.";
        ERRORS=1;
	fi	

	if [ ! -x "$(command -v curl)" ]; then
        echo "curl command not found.";
        ERRORS=1;
	fi

	if [ ! -x "$(command -v wl-copy)" ] && [ "${DESKTOP_SESSION}" != "" ]; then
        echo "wl-copy command not found.";
        ERRORS=1;
	fi

	if [ ! -x "$(command -v notify-send)" ] && [ "${DESKTOP_SESSION}" != "" ]; then
        echo "notify-send command not found.";
        ERRORS=1;
	fi

	if [ "${ERRORS}" -eq 1 ]; then
	  exit 1;
	fi
}

if [ -f "${1}" ]; then
    upload "${1}";
else
    if [ "${DESKTOP_SESSION}" != "" ]; then
        notify-send "Error!" "File specified not exists.";
	exit 1;
    else
        echo "Error! File specified not exists.";
	exit 1;
    fi
fi
