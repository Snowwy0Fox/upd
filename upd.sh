#!/usr/bin/env bash

#########################################
#  UPDATE - Script for running updates  #
#########################################

##########################
#      Help Message      #
##########################

Help() {

    # Display Help
    echo "Script for running system updates"
    echo
    echo "SYNTAX: sudo update [-a|-p|..]"
    echo
    echo "OPTIONS:"
    echo " [-a]:  update all packages"
    echo " [-p]:  update packages from pacman"
    echo " [-y]:  update packages from yay"
    echo " [-f]:  update packages from Flatpak"
    echo

}

#############################
#      Program Options      #
#############################

draw_line() {
    declare -i x=0
    declare -i y=$1
    
    declare l

    until [ $x  == $y ]; do
        l="#$l"
        x=$(( x + 1))

    done


    echo $l
}

wm() {
    if [ $# == 1 ]; then
        declare mUpd="          Updating $1          "
        declare lUpd="#$mUpd#"
        lBor="$(draw_line ${#lUpd})"

        echo
        echo -e "\x1b[1;38;5;40m$lBor\e[0m"
        echo -e "\x1b[1;38;5;40m#\e[0m\x1b[38;5;40m$mUpd\e[0m\x1b[1;38;5;40m#\e[0m"
        echo -e "\x1b[1;38;5;40m$lBor\e[0m"

    else
        echo
        echo -e "\x1b[1;38;5;40m$lBor\e[0m"
        echo

    fi
}

run() {
    declare com="$*"

    echo
    echo -e "\x1b[1;38;5;40m[\e[0m\x1b[38;5;40mRUN\e[0m\x1b[1;38;5;40m]\e[0m $com"
    echo

    com="$com"

    [[ ! $(expr index "$com" "pacman") > 0 ]] && com="sudo -u sfox $com"

   eval nice -n 19 chrt -i 0 ionice -c 3 $com || return 1

    return 0
}

update() {
    wm $1

    case $1 in
        "pacman")
            local lockfile="/var/lib/pacman/db.lck"

            if [[ -f "$lockfile" ]] && ! pgrep -x pacman >/dev/null; then
                rm "$lockfile"
            fi
            
            run pacman --noconfirm -Syy
            run pacman-key --refresh-keys
            run pacman-key --populate archlinux manjaro
            run pacman --noconfirm -Syu

            ;;
        "yay")
            run yay -Syua

            ;;
        "flatpak")
            run flatpak update --appstream -y
            run flatpak update --system -y
            
            ;;
        \?)
            echo -e "\x1b[38;5;196m[ERROR]: Incorrect package manager\e[0m"
            echo

            return 1
            ;;
    esac

    [ $# > 1 ] && wm

    return 0
}

##########################
#      Main Program      #
##########################

# Set to exit if error occures
set -e

# if no extra arguments display help message
if [ $# == 0 ]; then
    Help

    exit;
fi

# Check if script is run by sudo
if [ $UID != 0 ]; then
    echo "Script require sudo use"
    echo

    exit;
fi

declare lBor

# Checking user input for designated options
while getopts ":aypf" option; do
    case $option in
        a) # Update all Packages
            update pacman
            update yay
            update flatpak

            exit;;
        y) # Update Packages from Yay
            update yay

            exit;;
        p) # Update Packages from Pacman
            update pacman

            exit;;
        f) # Update Packages from Flatpak
            update flatpak

            exit;;
        \?) # Handle invalid option
            echo -e "\x1b[38;5;196m[ERROR]:  Invalid Option\e[0m"
            echo

            exit;;
    esac
done
