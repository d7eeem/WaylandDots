#!/usr/bin/env sh

# Restores the shader after screenhot has been taken
restore_shader() {
	if [ -n "$shader" ]; then
		hyprshade on "$shader"
	fi
}

# Saves the current shader and turns it off
save_shader() {
	shader=$(hyprshade current)
	hyprshade off
	trap restore_shader EXIT
}

save_shader # Saving the current shader

if [ -z "$XDG_PICTURES_DIR" ]; then
	XDG_PICTURES_DIR="$HOME/Pictures"
fi

scrDir=$(dirname "$(realpath "$0")")
source $scrDir/globalcontrol.sh
swpy_dir="${confDir}/swappy"
save_dir="/home/tinker/Nextcloud/Hyprshot"
save_file=$(date +'%y%m%d_%H%M%S_screenshot.png')
temp_screenshot="/tmp/screenshot.png"

mkdir -p $save_dir
mkdir -p $swpy_dir
echo -e "[Default]\nsave_dir=$save_dir\nsave_filename_format=$save_file" >$swpy_dir/config

function print_error
{
	cat <<"EOF"
    ./screenshot.sh <action>
    ...valid actions are...
        p  : print all screens
        s  : snip current screen
        sf : snip current screen (frozen)
        m  : print focused monitor
EOF
}

case $1 in
p) # print all outputs grimblast copysave screen $temp_screenshot && restore_shader && swappy -f $temp_screenshot && xbackbone_uploader.sh "$save_dir/$save_file"
        grimblast copysave screen "$temp_screenshot" && restore_shader && {
            swappy -f "$temp_screenshot" || true
            cp "$temp_screenshot" "$save_dir/$save_file"
            xbackbone_uploader.sh "$save_dir/$save_file"
        }
        ;;
s) # drag to manually snip an area / click on a window to print it grimblast copysave area $temp_screenshot && restore_shader && swappy -f $temp_screenshot   && xbackbone_uploader.sh "$save_dir/$save_file";;
        grimblast copysave area "$temp_screenshot" && restore_shader && {
            swappy -f "$temp_screenshot" || true
            cp "$temp_screenshot" "$save_dir/$save_file"
            xbackbone_uploader.sh "$save_dir/$save_file"
        }
        ;;
sf) # frozen screen, drag to manually snip an area / click on a window to print it grimblast --freeze copysave area $temp_screenshot && restore_shader && swappy -f $temp_screenshot  && xbackbone_uploader.sh "$save_dir/$save_file" ;;
        grimblast --freeze copysave area "$temp_screenshot" && restore_shader && {
            swappy -f "$temp_screenshot" || true
            cp "$temp_screenshot" "$save_dir/$save_file"
            xbackbone_uploader.sh "$save_dir/$save_file"
        }
        ;;
m) # print focused monitor grimblast copysave output $temp_screenshot && restore_shader && swappy -f $temp_screenshot && xbackbone_uploader.sh "$save_dir/$save_file";;
        grimblast copysave output "$temp_screenshot" && restore_shader && {
            swappy -f "$temp_screenshot" || true
            cp "$temp_screenshot" "$save_dir/$save_file"
            xbackbone_uploader.sh "$save_dir/$save_file"
        }
        ;;
*) # invalid option
	print_error ;;
esac

rm "$temp_screenshot"

if [ -f "${save_dir}/${save_file}" ]; then
	notify-send -a "t1" -i "${save_dir}/${save_file}" "saved in ${save_dir}"
fi
