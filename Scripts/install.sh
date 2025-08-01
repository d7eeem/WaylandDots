#!/usr/bin/env bash
# shellcheck disable=SC2154
#--------------------------------#
# import variables and functions #
#--------------------------------#
scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi


#------------------#
# evaluate options #
#------------------#
flg_Install=0
flg_Service=0
flg_DryRun=0
flg_reboot=0
flg_flat=0
while getopts idfstmh: RunStep; do
    case $RunStep in
    i) flg_Install=1 ;;
    d)
        flg_Install=1
        export use_default="--noconfirm"
        ;;
    f) flg_flat=1 ;;
    s) flg_Service=1 ;;
    h)
        # shellcheck disable=SC2034
        export flg_Shell=0
        print_log -r "[shell] " -b "Reevaluate :: " "shell options"
        ;;
    t)
        flg_DryRun=1
        flg_Install=1
        ;;
    m) flg_ThemeInstall=0 ;;
    *)
        cat <<EOF
Usage: $0 [options]
            i : [i]nstall hyprland without configs
            d : install hyprland [d]efaults without configs --noconfirm
            r : [r]estore config files
            s : enable system [s]ervices
            n : ignore/[n]o [n]vidia actions
            h : re-evaluate S[h]ell
            m : no the[m]e reinstallations
            t : [t]est run without executing (-irst to dry run all)
EOF
        exit 1
        ;;
    esac
done

# Only export that are used outside this script
HYDE_LOG="$(date +'%y%m%d_%Hh%Mm%Ss')"
export flg_DryRun flg_Nvidia flg_Shell flg_Install flg_ThemeInstall HYDE_LOG

if [ "${flg_DryRun}" -eq 1 ]; then
    print_log -n "[test-run] " -b "enabled :: " "Testing without executing"
elif [ $OPTIND -eq 1 ]; then
    flg_Install=1
    flg_Restore=1
    flg_Service=1
    flg_flat=1
fi


#---------------------#
# install chaotic-aur #
#---------------------#
    cat <<"EOF"

┬┌┐┌┌─┐┌┬┐┌─┐┬  ┬  ┬┌┐┌┌─┐  ┌─┐┬ ┬┌─┐┌─┐┌┬┐┬┌─┐ ┌─┐┬ ┬┬─┐
││││└─┐ │ ├─┤│  │  │││││ ┬  │  ├─┤├─┤│ │ │ ││───├─┤│ │├┬┘
┴┘└┘└─┘ ┴ ┴ ┴┴─┘┴─┘┴┘└┘└─┘  └─┘┴ ┴┴ ┴└─┘ ┴ ┴└─┘ ┴ ┴└─┘┴└─



EOF


if grep -q '\[chaotic-aur\]' /etc/pacman.conf; then
    print_log -sec "CHAOTIC-AUR" -stat "skipped" "Chaotic AUR entry found in pacman.conf..."
else
    prompt_timer 120 "Would you like to install Chaotic AUR? [y/n] | q to quit "
    is_chaotic_aur=false

    case "${PROMPT_INPUT}" in
    y | Y)
        is_chaotic_aur=true
        ;;
    n | N)
        is_chaotic_aur=false
        ;;
    q | Q)
        print_log -sec "Chaotic AUR" -crit "Quit" "Exiting..."
        exit 1
        ;;
    *)
        is_chaotic_aur=true
        ;;
    esac
    if [ "${is_chaotic_aur}" == true ]; then
        sudo pacman-key --init
        sudo "${scrDir}/chaotic_aur.sh" --install
    fi
fi


#------------#
# installing #
#------------#
if [ ${flg_Install} -eq 1 ]; then
    cat <<"EOF"

 _         _       _ _ _
|_|___ ___| |_ ___| | |_|___ ___
| |   |_ -|  _| .'| | | |   | . |
|_|_|_|___|_| |__,|_|_|_|_|_|_  |
                            |___|

EOF

    #----------------------#
    # prepare package list #
    #----------------------#
    shift $((OPTIND - 1))
    custom_pkg=$1
    cp "${scrDir}/pkg_core.lst" "${scrDir}/install_pkg.lst"
    trap 'mv "${scrDir}/install_pkg.lst" "${cacheDir}/logs/${HYDE_LOG}/install_pkg.lst"' EXIT

    if [ -f "${custom_pkg}" ] && [ -n "${custom_pkg}" ]; then
        cat "${custom_pkg}" >>"${scrDir}/install_pkg.lst"
    fi
    echo -e "\n#user packages" >>"${scrDir}/install_pkg.lst" # Add a marker for user packages
    #----------------#
    # get user prefs #
    #----------------#
    echo ""
    if ! chk_list "aurhlpr" "${aurList[@]}"; then
        print_log -c "\nAUR Helpers :: "
        aurList+=("yay-bin" "paru-bin") # Add this here instead of in global_fn.sh
        for i in "${!aurList[@]}"; do
            print_log -sec "$((i + 1))" " ${aurList[$i]} "
        done

        prompt_timer 120 "Enter option number [default: yay-bin] | q to quit "

        case "${PROMPT_INPUT}" in
        1) export getAur="yay" ;;
        2) export getAur="paru" ;;
        3) export getAur="yay-bin" ;;
        4) export getAur="paru-bin" ;;
        q)
            print_log -sec "AUR" -crit "Quit" "Exiting..."
            exit 1
            ;;
        *)
            print_log -sec "AUR" -warn "Defaulting to yay-bin"
            print_log -sec "AUR" -stat "default" "yay-bin"
            export getAur="yay-bin"
            ;;
        esac
        if [[ -z "$getAur" ]]; then
            print_log -sec "AUR" -crit "No AUR helper found..." "Log file at ${cacheDir}/logs/${HYDE_LOG}"
            exit 1
        fi
    fi

    if ! chk_list "myShell" "${shlList[@]}"; then
        print_log -c "Shell :: "
        for i in "${!shlList[@]}"; do
            print_log -sec "$((i + 1))" " ${shlList[$i]} "
        done
        prompt_timer 120 "Enter option number [default: zsh] | q to quit "

        case "${PROMPT_INPUT}" in
        1) export myShell="zsh" ;;
        2) export myShell="fish" ;;
        q)
            print_log -sec "shell" -crit "Quit" "Exiting..."
            exit 1
            ;;
        *)
            print_log -sec "shell" -warn "Defaulting to zsh"
            export myShell="zsh"
            ;;
        esac
        print_log -sec "shell" -stat "Added as shell" "${myShell}"
        echo "${myShell}" >>"${scrDir}/install_pkg.lst"

        if [[ -z "$myShell" ]]; then
            print_log -sec "shell" -crit "No shell found..." "Log file at ${cacheDir}/logs/${HYDE_LOG}"
            exit 1
        else
            print_log -sec "shell" -stat "detected :: " "${myShell}"
        fi
    fi

    if ! grep -q "^#user packages" "${scrDir}/install_pkg.lst"; then
        print_log -sec "pkg" -crit "No user packages found..." "Log file at ${cacheDir}/logs/${HYDE_LOG}/install.sh"
        exit 1
    fi

    #--------------------------------#
    # install packages from the list #
    #--------------------------------#
    [ ${flg_DryRun} -eq 1 ] || "${scrDir}/install_pkg.sh" "${scrDir}/install_pkg.lst"
fi

if [[ ${flg_flat} -eq 1 ]]; then
  "${scrDir}"/install_fpk.sh
fi


#------------------------#
# enable system services #
#------------------------#
if [ ${flg_Service} -eq 1 ]; then
    cat <<"EOF"

                 _
 ___ ___ ___ _ _|_|___ ___ ___
|_ -| -_|  _| | | |  _| -_|_ -|
|___|___|_|  \_/|_|___|___|___|

EOF


    while read -r serviceChk; do

        # Handle .timer units separately
        if [[ "$serviceChk" == *.timer ]]; then
            if systemctl list-units --all -t timer --full --no-legend "${serviceChk}" | sed 's/^\s*//g' | cut -f1 -d' ' | grep -Fxq "${serviceChk}"; then
                print_log -y "[skip] " -b "active " "Timer ${serviceChk}"
            else
                print_log -y "enable" "Timer ${serviceChk}"
                if [ "$flg_DryRun" -ne 1 ]; then
                    sudo systemctl enable "${serviceChk}"
                fi
            fi
        else
            # Default: assume it's a service
            if [[ $(systemctl list-units --all -t service --full --no-legend "${serviceChk}.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "${serviceChk}.service" ]]; then
                print_log -y "[skip] " -b "active " "Service ${serviceChk}"
            else
                print_log -y "start" "Service ${serviceChk}"
                if [ "$flg_DryRun" -ne 1 ]; then
                    sudo systemctl enable --now "${serviceChk}.service"
                fi
            fi
        fi

    done <"${scrDir}/system_ctl.lst"
fi

if [ $flg_Install -eq 1 ]; then
    print_log -stat "\nInstallation" "completed"
fi


if [ ${flg_reboot} -eq 1 ]; then
    cat <<"EOF"
    
     
 _     _____ _____  _____ 
| |   |  _  |  __ \/  ___|
| |   | | | | |  \/\ `--. 
| |   | | | | | __  `--. \
| |___\ \_/ / |_\ \/\__/ /
\_____/\___/ \____/\____/ 
                          
                          
EOF

print_log -stat "Log" "View logs at ${cacheDir}/logs/${HYDE_LOG}"
if [ $flg_Install -eq 1 ] ||
    [ $flg_Restore -eq 1 ] ||
    [ $flg_Service -eq 1 ]; then
    print_log -stat "It is not recommended to use newly installed or upgraded HyDE without rebooting the system. Do you want to reboot the system? (y/N)"
    read -r answer

    if [[ "$answer" == [Yy] ]]; then
        echo "Rebooting system"
        systemctl reboot
    else
        echo "The system will not reboot"
    fi
fi
else
    print_log -sec "LOGS" -stat "skipped" "Consider REBOOTING"
fi
