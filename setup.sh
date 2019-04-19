#!/bin/bash
trap "exit" INT
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

if [[ ! -f "$(pwd)/.env" ]] ; then
  cp "$(pwd)/.env.example" "$(pwd)/.env"
  echo "${yellow}You did not have a .env file, so the example has been copied.${reset}"
  echo "${yellow}Please modify your .env file with the correct info, then run this script again.${reset}"
  exit
elif [[ -f "$(pwd)/.env" ]] ; then
  source .env
  echo "${green}Found .env and sourced${reset}"
fi

hostnameList=(
plex
tautulli
sonarr
radarr
ombi
jackett
transmission
)

declare -A req_vars=(
[DATAFOLDERenv]=${DATAFOLDER}
[USINGNETWORKSHAREenv]=${USINGNETWORKSHARE}
[LOCALDOMAINenv]=${LOCALDOMAIN}
[RESTARTPOLICYenv]=${RESTARTPOLICY}
[VPNUSERenv]=${VPNUSER}
[VPNPASSenv]=${VPNPASS}
[VPNPROVIDERenv]=${VPNPROVIDER}
[PLEX_CLAIMenv]=${PLEX_CLAIM}
[TZenv]=${TZ}
[PUIDenv]=${PUID}
[PGIDenv]=${PGID}
)

declare -A network_share_reqs=(
[CREDENTIALFILEenv]=${CREDENTIALFILE}
[NETWORKSHAREDRIVERenv]=${NETWORKSHAREDRIVER}
[NETWORKSHAREHOSTenv]=${NETWORKSHAREHOST}
[NETWORKSHAREUSERenv]=${NETWORKSHAREUSER}
[NETWORKSHAREPASSenv]=${NETWORKSHAREPASS}
)
check_req_vars () {
  for requirement in "${!req_vars[@]}"; do
    if [[ ! ${req_vars[$requirement]} ]] ; then
      echo "${red}$requirement ${yellow}is required in the .env file.${reset}" | sed 's/env*//'
      ((reqFlag+=1))
    elif [[ "$requirement" == "USINGNETWORKSHAREenv" ]] && [[ ! "${req_vars[$requirement]}" == "" ]]; then
      if [[ "${req_vars[$requirement],,}" == "true" ]]; then
        usingShare=true
        for netRequirement in "${!network_share_reqs[@]}"; do
          if [[ ! ${network_share_reqs[$netRequirement]} ]]; then
            echo "${red}$netRequirement ${yellow}is required in the .env file to use network shares.${reset}" | sed 's/env*//'
            ((reqFlag+=1))
          fi
        done
      elif [[ "${req_vars[$requirement],,}" == "false" ]]; then
        echo "${yellow}Using Local data folder ${DATAFOLDER}${reset}"
        usingShare=false
      fi
    fi
  done
  if [[ $reqFlag -ge 1 ]]; then
    exit
  fi
}

run_as_docker() {
  sg docker -c "$@"
}

check_if_docker_group () {
  echo "${yellow}Checking if user is part of the docker group...${reset}"
  if [[ $(id -Gn $(whoami) | grep -c "docker") == 1 ]] ; then
    echo "${green}$USER is part of docker group, proceeding...${reset}"
    newGroupFlag=0
  else
    echo "${red}$USER is not part of docker group, adding...${reset}"
    newGroupFlag=1
    sudo usermod -aG docker $(whoami) && echo "${green}$USER added to docker group${reset}"
  fi
}

install_docker () {
  echo "${yellow}Updating apt, please input your password (if prompted):${reset}"
  sudo apt-get -qq update
  if [[ $(apt list --installed | grep -c 'docker\|docker-engine\|docker.io\|containerd\|runc') -ge 1 ]] ; then
    echo "${yellow}Removing old Docker install...${reset}"
    sudo apt-get -qq -y remove docker docker-engine docker.io containerd runc
  fi
  echo "${yellow}Installing Docker dependencies...${reset}"
  sudo apt-get -qq -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
  echo "${yellow}Checking for Docker GPG key...${reset}"
  if [[ ! $(sudo apt-key fingerprint 0EBFCD88) ]]; then
    echo "${yellow}Adding Docker GPG key...${reset}"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    echo "${yellow}Verifying key fingerprint...${reset}"
    if [[ $(sudo apt-key fingerprint 0EBFCD88) ]]; then
      echo "${green}Docker GPG key verified${reset}"
    elif [[ ! $(sudo apt-key fingerprint 0EBFCD88) ]]; then
      echo "${red}Docker GPG key verification failed! Cannot find GPG key.${reset}"
      exit
    fi
  else
    echo "${green}Docker GPG key already exists${reset}"
  fi
  if [[ $(cat /etc/apt/sources.list | grep -c "deb \[arch=amd64\] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable") == 0 ]]; then
    echo "${yellow}Adding Docker repo...${reset}"
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" >/dev/null
    echo "${yellow}Updating apt...${reset}"
    sudo apt-get update >/dev/null
  fi
  echo "${yellow}Installing Docker...${reset}"
  sudo apt-get -qq -y install docker-ce docker-ce-cli containerd.io \
    && sudo systemctl start docker >/dev/null \
    && sudo systemctl enable docker >/dev/null \
    && echo "${green}Docker installed and enabled on boot${reset}"
  echo "${yellow}Checking for docker-compose..."
  if [[ ! -f "/usr/local/bin/docker-compose" ]]; then
    echo "${yellow}Installing docker-compose...${reset}"
    sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose >/dev/null \
      && sudo chmod +x /usr/local/bin/docker-compose >/dev/null
    echo "${green}docker-compose installed${reset}"
  elif [[ -f "/usr/local/bin/docker-compose" ]]; then
    echo "${green}docker-compose already installed${reset}"
  fi
  check_if_docker_group
  dockerAPIVersion=$(run_as_docker "docker version | awk 'NR==3{print $3; exit}' | grep -o '[0-9.]\+'")
  if [[ $usingShare == true ]]; then
    if [[ "${NETWORKSHAREDRIVER,,}" == "cifs" ]] ; then
      if [[ $(apt list --installed | grep -c cifs-utils) == 0 ]] ; then
        echo "${yellow}Installing ${NETWORKSHAREDRIVER,,}-utils${reset}"
        sudo apt-get install cifs-utils -y >/dev/null
      fi
    elif [[ "${NETWORKSHAREDRIVER,,}" == "nfs" ]] ; then
      if [[ $(apt list --installed | grep -c nfs-common) == 0 ]] ; then
        echo "${yellow}Installing ${NETWORKSHAREDRIVER,,}-common${reset}"
        sudo apt-get install nfs-common -y >/dev/null
      fi
    fi
  fi
}

config_network_share () {
  echo "${yellow}Mounting network share..."
  if [[ $(grep -c "${NETWORKSHAREHOST}" "/etc/fstab") == 0 ]] ; then
      echo "# HMS-Docker Mount" | sudo tee -a /etc/fstab >/dev/null
      if [[ "${NETWORKSHAREDRIVER,,}" == "cifs" ]] ; then
        echo -e username=$NETWORKSHAREUSER | sudo tee -a ${CREDENTIALFILE} >/dev/null
        echo -e password=$NETWORKSHAREPASS | sudo tee -a ${CREDENTIALFILE} >/dev/null
        sudo chown $USER:$USER ${CREDENTIALFILE}
        sudo chmod 600 ${CREDENTIALFILE}
        echo "${yellow}Your network share credentials are now stored in ${CREDENTIALFILE}${reset}"
        echo "${red}CAREFUL: THESE ARE STORED IN PLAINTEXT${reset}"
        echo "//${NETWORKSHAREHOST} ${DATAFOLDER} ${NETWORKSHAREDRIVER,,} vers=3.0,credentials=${CREDENTIALFILE},uid=$USER,gid=$USER 0 0" | sudo tee -a /etc/fstab >/dev/null
      elif [[ "${NETWORKSHAREDRIVER,,}" == "nfs" ]] ; then
        if [[ ${NFSOPTIONS} ]]; then
          echo "${yellow}Creating with NFS options ${NFSOPTIONS}${reset}"
          echo "${NETWORKSHAREHOST}:${NFSFOLDER} ${DATAFOLDER} ${NETWORKSHAREDRIVER} ${NFSOPTIONS} 0 0" | sudo tee -a /etc/fstab >/dev/null
        elif [[ ! ${NFSOPTIONS} ]]; then
          echo "${yellow}No NFS options specified, using default${reset}"
          echo "${NETWORKSHAREHOST}:${NFSFOLDER} ${DATAFOLDER} ${NETWORKSHAREDRIVER} defaults 0 0" | sudo tee -a /etc/fstab >/dev/null
        fi
      fi
      sudo mount -a
      echo "${green}fstab entry created, will mount ${yellow}${NETWORKSHAREHOST}${green} to ${yellow}${DATAFOLDER}${green} on boot.${reset}"
  elif [[ $(grep -c "${NETWORKSHAREHOST}" "/etc/fstab") -ge 1 ]] ; then
      echo "${red}Entry in fstab exists.${reset}"
  fi
}

if [[ "$(uname)" == "Darwin" ]] ; then
	echo "Running MacOS. The containers were tested and work on MacOS, but ${yellow}you will need to use local directories because I never tested remote shares.${reset}"
  echo "Simply running ${green}docker-compose up -d${reset} will start the containers once you have the required dependencies installed."
elif [[ "$(uname)" == "Linux" ]] ; then
  echo "Running Linux, specifically" $(lsb_release -ds)
  check_req_vars
  privateIP=$(hostname -I | awk '{print $1; exit}')
  publicIP=$(wget -qO - icanhazip.com)
  install_docker
  if [[ ! -d ${DATAFOLDER} ]] ; then
    sudo mkdir -p ${DATAFOLDER} && echo "${green}${DATAFOLDER} created${reset}"
    sudo chown $USER:$USER ${DATAFOLDER}
    sudo chmod 775 ${DATAFOLDER}
  fi
  if [[ "$usingShare" == "true" ]]; then
    if ping -c 4 ${NETWORKSHAREHOST%%/*} > /dev/null; then
      echo "${green}${NETWORKSHAREHOST%%/*} is online${reset}"
      config_network_share
    else
      echo "${red}Unable to ping host ${NETWORKSHAREHOST}${reset}"
      while [[ true ]]; do
        read -p "If this is intentional due to a firewall, press Y, otherwise press N [y/n] \n(If you don't know, press N): " pingFailure
        if [[ "${pingFailure,,}" == "y" ]]; then
          config_network_share
          break
        elif [[ "${pingFailure,,}" == "n" ]]; then
          exit
        fi
      done
    fi
  fi
  runningContainers=$(run_as_docker "docker ps | awk 'NR==2{print $2; exit}'")
  echo
  if [[ $runningContainers ]] ; then
    echo "${yellow}Killing docker images if they're already running...${reset}"
    for host in "${hostnameList[@]}"; do
      if [[ "$runningContainers" =~ "$host" ]] ; then
        run_as_docker "docker-compose kill"
        echo
        break
      fi
    done
  fi
  echo "${yellow}Starting docker images...${reset}"
  run_as_docker "docker-compose up -d" && echo -e ' \n'"${green}Docker images started successfully.${reset}"
  echo
  torrentPublicIP=$(run_as_docker "docker exec -it transmission ./usr/bin/wget -qO - icanhazip.com")
  echo -e "Private IP of docker host:" ' \t' $privateIP
  echo -e "Public  IP of docker host:" ' \t' $publicIP
  echo -e "Public IP of transmission:" ' \t' $torrentPublicIP
  echo
  if [[ $torrentPublicIP ]] ; then
    if [[ "$publicIP" == "$torrentPublicIP" ]] ; then
      echo "${red}YOU ARE NOT PROTECTED BY THE VPN${reset}"
    elif [[ "$publicIP" != "$torrentPublicIP" ]] ; then
      echo "${green}You are protected!${reset}"
    fi
  else
    echo "${red}TORRENT CONTAINER HAS NO VPN ADDRESS${reset}"
    echo "${yellow}Is the transmission container running?${reset}"
  fi
  echo
  echo "Your custom /etc/hosts entries:"
  echo
  for host in "${hostnameList[@]}"; do
    echo -e $privateIP ' \t ' $host.${LOCALDOMAIN}
  done
  if [[ $(grep -c "# Generated by HMS-Docker" "/etc/hosts") == 0 ]] ; then
    while true; do
      echo
      read -p "Should we append these to the /etc/hosts file for you? [y/n]: " addToHosts
      if [[ "${addToHosts,,}" == "y" ]]; then
        echo -e "\n# Generated by HMS-Docker" | sudo tee -a /etc/hosts >/dev/null
        for host in "${hostnameList[@]}"; do
          echo -e $privateIP ' \t ' $host.${LOCALDOMAIN} | sudo tee -a /etc/hosts >/dev/null
        done
        break
      elif [[ "${addToHosts,,}" == "n" ]]; then
        echo "${yellow}Not adding to hosts file${red}"
        break
      fi
    done
  fi
  echo
  if [[ $newGroupFlag -eq 1 ]] ; then
    echo "${yellow}Please logout then login again to use docker commands.${reset}"
  fi
  echo "${green}Data folder is located at ${DATAFOLDER}${reset}"
  echo "${green}Setup complete, the contianers are now running!${reset}"
fi
