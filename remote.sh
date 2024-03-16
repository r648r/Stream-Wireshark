#!/bin/bash

#############
# CONSTANTE #
#############

# Default Arg
SSH_HOST_TO_CAPTURE="vps"
REMOTE_DIR="/tmp/capture"
LOCAL_DIR="/tmp/vps_pcap"
INTERFACE="eth0"
CAPTURE_FILE="capture.pcap"

# Color message
OK="[\033[32m + \033[0m]"
NOT_OK="[\033[31m - \033[0m]"

############
# FONCTION #
############
success_or_not() {

    if [ $1 -eq 0 ]; then
        echo -e "$OK OK : $2"
    else
        echo -e "$NOT_OK Fail : $2"
        exit 1
    fi
}

install_sshfs() {
    if ! command -v sshfs &> /dev/null; then
        echo -e "$NOT_OK Install SSHFS"
        sudo apt-get update -y && sudo apt-get install -y sshfs
    else
        echo -e "$OK OK : SSHFS installed."
    fi
}

create_remote_dir() {
    ssh $SSH_HOST_TO_CAPTURE "sudo mkdir -p $REMOTE_DIR"
    success_or_not $? "Create remote directory"
}

mount_remote_dir() {
    mkdir -p $LOCAL_DIR
    sudo sshfs $SSH_HOST_TO_CAPTURE:$REMOTE_DIR $LOCAL_DIR
    success_or_not $? "Mount distante directory in $LOCAL_DIR, try sudo fusermount -u $LOCAL_DIR"
}

start_capture() {
    local CAPTURE_COMMAND="tcpdump -i $INTERFACE -w $REMOTE_DIR/$CAPTURE_FILE -vv"
    echo -e "Do ctrl+C for stop capture"
    ssh -t $SSH_HOST_TO_CAPTURE "$CAPTURE_COMMAND"
}

help() {
    echo "Utilisation: $0 -u VPS_USER -d REMOTE_DIR -l LOCAL_DIR -i INTERFACE"
    echo "Après avoir arrêté la capture, démontez le dossier partagé avec 'fusermount -u $LOCAL_DIR'"
}

#######
# ARG #
#######
while getopts u:d:l:i:h option; do
    case "${option}" in
        u) SSH_HOST_TO_CAPTURE=${OPTARG};;
        d) REMOTE_DIR=${OPTARG};;
        l) LOCAL_DIR=${OPTARG};;
        i) REMOTE_INTERFACE=${OPTARG};;
        h) help
           exit 0;;
        *) echo "Option invalide: -$OPTARG"
           help
           exit 1;;
    esac
done

# Arg obligatoire
if [[ -z $SSH_HOST_TO_CAPTURE || -z "$REMOTE_DIR" || -z $LOCAL_DIR || -z $REMOTE_INTERFACE ]]; then
    echo "SSH host, remote interface, local and remote directory are requiered"
    help
    exit 1
fi

########
# MAIN #
########
install_sshfs
mount_remote_dir
start_capture

echo "Après avoir arrêté la capture, démontez le dossier partagé avec 'fusermount -u $LOCAL_DIR'"
