#!/bin/bash
#############
# CONSTANTE #
#############
SSH_HOST_TO_CAPTURE="vps"
REMOTE_DIR="/tmp/capture"
LOCAL_DIR="/tmp/vps_pcap"
INTERFACE="eth0"
CAPTURE_FILE="capture.pcap"

############
# FONCTION #
############
install_sshfs() {
    if ! command -v sshfs &> /dev/null; then
        echo "SSHFS n'est pas installé. Installation en cours..."
        sudo apt-get update && sudo apt-get install -y sshfs
    else
        echo "SSHFS est déjà installé."
    fi
}

create_remote_dir() {
    echo "[\033[32m + \033[0m] Création du répertoire distant si nécessaire"
    ssh $SSH_HOST_TO_CAPTURE "mkdir -p $REMOTE_DIR"
}

mount_remote_dir() {
    mkdir -p $LOCAL_DIR
    echo "[\033[32m + \033[0m] Montage du dossier distant..."
    sudo sshfs $SSH_HOST_TO_CAPTURE:$REMOTE_DIR $LOCAL_DIR
}

start_capture() {
    local CAPTURE_COMMAND="tcpdump -i $INTERFACE -w $REMOTE_DIR/$CAPTURE_FILE"
    echo $CAPTURE_COMMAND
    echo "[\033[32m + \033[0m] Démarrage de la capture du trafic réseau sur la machine distante..."
    ssh -t $SSH_HOST_TO_CAPTURE "$CAPTURE_COMMAND"
}

#######
# ARG #
#######
while getopts u:d:l:n:h option; do
    case "${option}" in
        u) SSH_HOST_TO_CAPTURE=${OPTARG};;
        d) REMOTE_DIR=${OPTARG};;
        l) LOCAL_DIR=${OPTARG};;
        n) INTERFACE=${OPTARG};;
        h) echo "Utilisation: $0 -u VPS_USER -i VPS_IP -d REMOTE_DIR -l LOCAL_DIR -n INTERFACE"
           exit 0;;
        *) echo "Option invalide: -$OPTARG"
           exit 1;;
    esac
done

# Arg 
if [[ $SSH_HOST_TO_CAPTURE || -z "$REMOTE_DIR" || -z $LOCAL_DIR ]]; then
    echo "VPS_USER, VPS_IP, et REMOTE_DIR sont obligatoires."
    echo "Utilisation: $0 -u VPS_USER -i VPS_IP -d REMOTE_DIR [-l LOCAL_DIR] [-n INTERFACE]"
    exit 1
fi

########
# MAIN #
########
install_sshfs
mount_remote_dir
start_capture

echo "La capture du trafic réseau a commencé. Le fichier pcap sera disponible localement dans $LOCAL_DIR"
echo "Pour arrêter la capture, utilisez 'ssh $VPS_USER@$VPS_IP killall tcpdump'"
echo "Après avoir arrêté la capture, démontez le dossier partagé avec 'fusermount -u $LOCAL_DIR'"
