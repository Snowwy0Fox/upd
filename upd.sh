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
        declare lUpd="#          Updating $1          #"
        lBor=$(draw_line ${#lUpd})

        echo
        echo "$lBor"
        echo "$lUpd"
        echo "$lBor"

    else
        echo
        echo "$lBor"
        echo

    fi
}

run() {
    declare com="$*"

    echo
    echo "[RUN] $com"
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
            run flatpak update
            
            ;;
        \?)
            echo "[ERROR]: Incorrect package manager"
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
            echo "[ERROR]:  Invalid Option"
            echo

            exit;;
    esac
done
