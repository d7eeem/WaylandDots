#!/bin/bash

tagName=$(curl --silent "https://api.github.com/repos/pineappleEA/pineapple-src/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/')

curl -JLO "https://github.com/pineappleEA/pineapple-src/releases/download/${tagName}/Linux-Yuzu-${tagName}.AppImage"

mv -f "Linux-Yuzu-${tagName}.AppImage" $HOME/Applications/yuzu.AppImage

exit 0