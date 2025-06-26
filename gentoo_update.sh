#!/usr/bin/env bash

# heavily inspired by https://github.com/alicela1n/gentoo-update

PROGNAME="$(basename "${0}")"

kernel_build="NO"
use_running_config="NO"
reboot="YES"

red="\e[0;91m"
blue="\e[0;94m"
green="\e[0;92m"
white="\e[0;97m"
bold="\e[1m"
uline="\e[4m"
reset="\e[0m"

# force TERM if none found (e.g. when running from cron)
# otherwise mach builds (firefox etc.) will fail
if ! tty -s; then
    export TERM="dumb"
fi

prerun_checks() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${red}Please run as root${reset}"
        error
}

restart() {
    exec "${SCRIPTPATH}" ${ARGS}
}

error() {
    echo -e "${red}Error: exiting${reset}" >&2
    exit 1
}

successful_quit() {
    exit 0
}

sync_portage_tree() {
        # Using emerge-webrsync to bring portage tree up to a recent snapshot
        echo -e "${green}Upgrading portage tree with webrsync before doing a sync...${reset}"
        emerge-webrsync
        echo
}


clean_prior_history() {
    echo -e "${green}Cleaning any prior emerge resume history...${reset}"
    emaint --fix cleanresume
    echo
}

update_portage() {
    echo -e "${green}Updating portage...${reset}"
    emerge --oneshot --update portage
    echo
}

do_the_complete_system_upgrade() {
    echo -e "${green}Running a complete system upgrade...${reset}"
    echo -e "${red}This process could fail and require manual intervention!${reset}"
    echo -e "${blue}Running emerge --deep --with-bdeps=y --changed-use --update @world${reset}"
    
    # Check if user changes are required to percede
    if grep -qi "The following \(keyword\|mask\|USE\|license\) changes are necessary to proceed" \
        <(emerge --pretend --deep --with-bdeps=y --changed-use --update --backtrack=50 @world 2>&1 || true); then
        # Silently note this and fail later
        USER_CHANGES_REQUIRED="YES"
    fi
    
    # Actually do the system upgrade
    START=`date`
    emerge --deep --with-bdeps=y --changed-use --update @world
    STOP=`date`
    if [[ "$USER_CHANGES_REQUIRED" == "YES" ]]; then
        echo -e "${red}User changes are required! Attempt to fix it in another console window then return here${reset}"
        read -p "Press enter to continue"
        do_the_complete_system_upgrade
    fi
    echo -e "${blue}Start : ${reset}" $START
    echo -e "${blue}End   : ${reset}" $STOP
    echo
}

process_dependencies() {
    echo -e "${green}Cleaning up dependencies...${reset}"
    emerge --depclean
    echo
    echo -e "${green}Checking and rebuilding dependencies...${reset}"
    revdep-rebuild
    echo
    echo -e "${green}Rebuilding any packages that depend on stale libraries...${reset}"
    emerge @preserved-rebuild
    echo
    echo -e "${green}Updating environmental settings${reset}"
    env-update
    echo
}

update_old_perl_modules() {
    # perl modules need to be updated as they are built for a particular perl target but not automatically
    # rebuilt when perl gets upgraded
    echo -e "${green}Rebuilding old perl modules...${reset}"
    perl-cleaner --all
}

clean_python_config() {
    # Remove uninstalled versions of python from /etc/python-exec/python-exec.conf
    if [ -f /usr/share/eselect/modules/python.eselect ]; then
        eselect python cleanup
    fi
}

build_kernel() {
    if [[ "$kernel_build" == "YES" ]]; then
        echo -e "${green}Upgrading kernel...${reset}"
        if [[ $(findmnt -M "$FOLDER") ]]; then
            echo -e "${green}/boot is mounted! continuing${reset}"
        else
            echo -e "${green}Mounting /boot!${reset}"
            mount /boot
        fi
    
        if [[ $use_running_config == YES ]]; then
            # Building kernel with config in /proc/config.gz
            echo -e "${green}Using current running config in /proc/config.gz...${reset}"
            genkernel --kernel-config=/proc/config.gz all
        else
            genkernel all
        fi
    fi
}

rebuild_modules() {
    echo -e "${green}Rebuilding any external kernel modules (example virtualbox or vmware)${reset}"
    emerge @module-rebuild --exclude '*-bin'
    echo
}

env_update() {
    env-update
}

reboot() {
    echo -e "${green}Upgrade completed!${reset}"
    if [[ $reboot == YES ]]; then
        # Prompt asking if you want to reboot the computer
        read -r -p "Reboot? [Y/n] " input
        case $input in
                [yY][eE][sS]|[yY])
            echo "Rebooting"
            reboot
            ;;
                [nN][oO]|[nN])
            ;;
            *)
            echo -e "${red}Invalid input...${reset}"
            exit 1
            ;;
        esac
    fi
}


prerun_checks
sync_portage_tree
clean_prior_history
update_portage
do_the_complete_system_upgrade
process_dependencies
update_old_perl_modules
clean_python_config
#build_kernel
rebuild_modules
env_update
reboot
successful_quit
