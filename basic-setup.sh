#!/bin/bash

# A setup script that will be easy to understand and
# be used to configure the .env file for the install

trap "exit" INT
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
cyan=`tput setaf 6`
reset=`tput sgr0`
defaultDir="~/hms-docker_data"
defaultMount="/mnt/hms-docker_data"
defaultDomain="local"
defaultPolicy="always"
defaultTZ="America/New_York"
defaultUsingNetworkShare=false
defaultCredPath=~/.hms-docker.creds
defaultUsingRatio=false
defaultRatio=1
defaultPUID=1000
defaultPGID=1000

if [[ -f "$(pwd)/.env" ]] ; then
  while true; do
    read -p "${yellow}THIS WILL ERASE YOUR CURRENT .env FILE! Are you sure you want to continue? [y/n]: ${reset}" deleteConfirm
    if [[ ${deleteConfirm,,} == "y" ]]; then
      rm -f "$(pwd)/.env"
      touch $(pwd)/.env
      sudo chown $USER:$USER $(pwd)/.env
      sudo chmod 700 $(pwd)/.env
      echo "${red}.env file deleted${reset}"
      if [[ -f "$(pwd)/.env" ]] ; then
        # Define DATAFOLDER
        echo
        echo "${cyan}Where would you like your data directory to be? This is where all hms-docker data will be stored. (e.g. /path/to/folder/hms-docker_data)${reset}"
        read -p "If you're not sure, you can use the default of '$defaultDir' by leaving this blank: " dataDir
        if [[ $dataDir ]]; then
          echo "DATAFOLDER=$dataDir" | sudo tee -a "$(pwd)/.env" >/dev/null
        elif [[ ! $dataDir ]]; then
          echo "DATAFOLDER=$defaultDir" | sudo tee -a "$(pwd)/.env" >/dev/null
        fi

        # Define LOCALDOMAIN
        echo
        echo "${cyan}What is the domain of your local network? (e.g. 'example.com')${reset}"
        read -p "If you're not sure, you can use the default of '$defaultDomain' by leaving this blank: " locDomain
        if [[ $locDomain ]]; then
          echo "LOCALDOMAIN=$locDomain" | sudo tee -a "$(pwd)/.env" >/dev/null
        elif [[ ! $locDomain ]]; then
          echo "LOCALDOMAIN=$defaultDomain" | sudo tee -a "$(pwd)/.env" >/dev/null
        fi

        # Define RESTARTPOLICY
        echo
        echo "${cyan}How should containers restart?${reset}"
        echo "1.) always: will restart containers if host is rebooted"
        echo "2.) unless-stopped: will restart the containers unless manually stopped"
        echo "3.) never: will never restart containers"
        read -p "If you're not sure, you can use the default of '$defaultPolicy' by leaving this blank (enter 1, 2, or 3): " resPolicy
        if [[ $resPolicy ]]; then
          while true; do
            if [[ "$resPolicy" == "1" ]]; then
              echo "RESTARTPOLICY=always" | sudo tee -a "$(pwd)/.env" >/dev/null
              break
            elif [[ "$resPolicy" == "2" ]]; then
              echo "RESTARTPOLICY=unless-stopped" | sudo tee -a "$(pwd)/.env" >/dev/null
              break
            elif [[ "$resPolicy" == "3" ]]; then
              echo "RESTARTPOLICY=never" | sudo tee -a "$(pwd)/.env" >/dev/null
              break
            else
              echo "${yellow}Please enter a valid number${reset}"
            fi
          done
        elif [[ ! $resPolicy ]]; then
          echo "RESTARTPOLICY=$defaultPolicy" | sudo tee -a "$(pwd)/.env" >/dev/null
        fi

        # Define VPNPROVIDER
        while true; do
          echo
          echo "${cyan}What VPN provider do you use?${reset}"
          echo "You can find the list of supported providers here: https://github.com/haugene/docker-transmission-openvpn#supported-providers"
          read -p "VPN Provider: " vProvider
          if [[ $vProvider ]]; then
            echo "VPNPROVIDER=${vProvider^^}" | sudo tee -a "$(pwd)/.env" >/dev/null
            break
          elif [[ ! $vProvider ]]; then
            echo "You must specify a VPN provider"
          fi
        done

        # Define VPNUSER
        while true; do
          echo
          echo "${cyan}What is the username/email address for your VPN?${reset}"
          read -p "VPN Username/Email Address: " vUser
          if [[ $vUser ]]; then
            echo "VPNUSER=$vUser" | sudo tee -a "$(pwd)/.env" >/dev/null
            break
          elif [[ ! $vUser ]]; then
            echo "${yellow}You must enter a username or email${reset}"
          fi
        done

        # Define VPNPASS
        while true; do
          echo
          echo "${cyan}What is the password for your VPN?${reset}"
          read -sp "VPN Password (will not be shown while typing): " vPass
          if [[ $vPass ]]; then
            echo "VPNPASS=$vPass" | sudo tee -a "$(pwd)/.env" >/dev/null
            break
          elif [[ ! $vPass ]]; then
            echo "${yellow}You must enter a password${reset}"
          fi
        done

        # Define PLEX_CLAIM token
        while true; do
          echo
          echo "${cyan}Please enter your Plex Claim token, you can obtain one from here:${reset} https://plex.tv/claim"
          read -p "Claim Token: " claimToken
          if [[ $claimToken ]]; then
            echo "PLEX_CLAIM=$claimToken" | sudo tee -a "$(pwd)/.env" >/dev/null
            break
          elif [[ ! $claimToken ]]; then
            echo "${yellow}You must enter a Plex Claim token${reset}"
          fi
        done

        # Define Time Zone
        echo
        echo "${cyan}Which Time Zone are you located in? (e.g. America/New_York)${reset}"
        echo "You can find a list of Time Zones here: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"
        read -p "If you're not sure, you can use the default of '$defaultTZ' by leaving this blank, but this may cause issues: " timeZone
        if [[ $timeZone ]]; then
          echo "TZ=$timeZone" | sudo tee -a "$(pwd)/.env" >/dev/null
        elif [[ ! $timeZone ]]; then
          echo "TZ=$defaultTZ" | sudo tee -a "$(pwd)/.env" >/dev/null
        fi

        # Define RATIO_LIMIT and RATIO_ENABLED
        echo
        echo "${cyan}Do you want to set a custom seeding ratio limit?${reset}"
        read -p "If you're not sure, you can use the default of 'no' (yes/no): " useRatio
        if [[ $useRatio ]]; then
          if [[ "${useRatio,,}" == "yes" ]] || [[ "${useRatio,,}" == "y" ]]; then
            echo "RATIO_ENABLED=true" | sudo tee -a "$(pwd)/.env" >/dev/null
            echo "${cyan}What is the ratio limit?${reset}"
            read -p "Set your own or you can use the default of '1' by leaving this blank: " ratioLimit
            if [[ $ratioLimit ]]; then
              echo "RATIO_LIMIT=$ratioLimit" | sudo tee -a "$(pwd)/.env" >/dev/null
            elif [[ ! $ratioLimit ]]; then
              echo "RATIO_LIMIT=$defaultRatio" | sudo tee -a "$(pwd)/.env" >/dev/null
            fi
          elif [[ "${useRatio,,}" == "no" ]] || [[ "${useRatio,,}" == "n" ]]; then
            echo "RATIO_ENABLED=false" | sudo tee -a "$(pwd)/.env" >/dev/null
          fi
        elif [[ ! $useRatio ]]; then
          echo "RATIO_ENABLED=false" | sudo tee -a "$(pwd)/.env" >/dev/null
          echo "RATIO_LIMIT=1" | sudo tee -a "$(pwd)/.env" >/dev/null
        fi

        # Define USINGNETWORKSHARE
        while true; do
          echo
          echo "${cyan}Will you be using a network share, such as a NAS or other service?${reset}"
          read -p "If you're not sure, you can use the default of "$defaultUsingNetworkShare" by leaving this blank (Yes/No): " useShare
          if [[ ${useShare,,} == "yes" ]] || [[ ${useShare,,} == "y" ]]; then
            echo "USINGNETWORKSHARE=true" | sudo tee -a "$(pwd)/.env" >/dev/null
            echo

            # Define MOUNTFOLDER
            echo "${cyan}Where will this network share folder be mounted?${reset}"
            read -p "If you're not sure, you can use the default of '$defaultMount' by leaving this blank: " mountDir
            if [[ $mountDir ]]; then
              echo "MOUNTFOLDER=$mountDir" | sudo tee -a "$(pwd)/.env" >/dev/null
            elif [[ ! $mountDir ]]; then
              echo "MOUNTFOLDER=$defaultMount" | sudo tee -a "$(pwd)/.env" >/dev/null
            fi

            # Define NETWORKSHAREDRIVER
            while true; do
              while true; do
                echo
                echo "${cyan}What is the IP or hostname of the machine hosting the network share?${reset}"
                read -p "IP or hostname: " getShareHost
                if [[ $getShareHost ]]; then
                  while true; do
                    read -p "${cyan}Where is the folder located on the network share: ${reset}" shareDir
                    if [[ $shareDir ]]; then
                      networkDir="$shareDir"
                      break
                    elif [[ ! $shareDir ]]; then
                      echo "${yellow}You must specify a folder${reset}"
                      echo $shareDir
                    fi
                  done
                  break
                elif [[ ! $getShareHost ]]; then
                  echo "${yellow}You must specify an IP or hostname to use network shares.${reset}"
                fi
              done
              echo
              echo "${cyan}Which network share driver should be used?${reset}"
              echo "If this is a network share on a Windows machine, it will be CIFS, unless you specifically setup NFS shares (CIFS/NFS): "
              read -p "Network share driver (CIFS or NFS): " shareDriver
              if [[ ${shareDriver,,} == "cifs" ]]; then
                echo "NETWORKSHAREDRIVER=cifs" | sudo tee -a "$(pwd)/.env" >/dev/null
                echo "NETWORKSHAREHOST=${getShareHost}${networkDir}" | sudo tee -a "$(pwd)/.env" >/dev/null
                echo
                while true; do
                  read -p "${cyan}What is the username for the network share?: ${reset}" shareUser
                  if [[ $shareUser ]]; then
                    echo "NETWORKSHAREUSER=$shareUser" | sudo tee -a "$(pwd)/.env" >/dev/null
                    break
                  elif [[ ! $shareUser ]]; then
                    echo "${yellow}You must specify a username for the network share${reset}"
                  fi
                done
                while true; do
                  echo
                  read -sp "${cyan}What is the password for the network share? (will not be shown while typing): ${reset}" sharePass
                  if [[ $sharePass ]]; then
                    echo "NETWORKSHAREPASS=$sharePass" | sudo tee -a "$(pwd)/.env" >/dev/null
                    break
                  elif [[ ! $sharePass ]]; then
                    echo "${yellow}You must specify a password for the network share${reset}"
                  fi
                done
                if [[ $shareUser ]] && [[ $sharePass ]]; then
                  echo
                  echo "${cyan}Since you're using CIFS, where should we store the credential file? (/path/to/file)${reset}"
                  echo "This credential file will store your credentials in plain text, but will only be accessable by the current user, $USER"
                  read -p "If you don't specify anything, the default path of "$defaultCredPath" will be used: " credPath
                  if [[ $credPath ]]; then
                    echo "CREDENTIALFILE=$credPath" | sudo tee -a "$(pwd)/.env" >/dev/null
                  elif [[ ! $credPath ]]; then
                    echo "CREDENTIALFILE=$defaultCredPath" | sudo tee -a "$(pwd)/.env" >/dev/null
                  fi
                fi
                break
              elif [[ ${shareDriver,,} == "nfs" ]]; then
                echo "NETWORKSHAREDRIVER=nfs" | sudo tee -a "$(pwd)/.env" >/dev/null
                echo "NETWORKSHAREHOST=${getShareHost}:${networkDir}" | sudo tee -a "$(pwd)/.env" >/dev/null
                echo
                break
              fi
            done
            break
          elif [[ ${useShare,,} == "no" ]] || [[ ${useShare,,} == "n" ]]; then
            echo "USINGNETWORKSHARE=false" | sudo tee -a "$(pwd)/.env" >/dev/null
            if [[ $dataDir ]]; then
              echo "MOUNTFOLDER=$dataDir" | sudo tee -a "$(pwd)/.env" >/dev/null
            elif [[ ! $dataDir ]]; then
              echo "MOUNTFOLDER=$defaultDir" | sudo tee -a "$(pwd)/.env" >/dev/null
            fi
            echo
            break
          elif [[ ! $useShare ]]; then
            echo "USINGNETWORKSHARE=false" | sudo tee -a "$(pwd)/.env" >/dev/null
            if [[ $dataDir ]]; then
              echo "MOUNTFOLDER=$dataDir" | sudo tee -a "$(pwd)/.env" >/dev/null
            elif [[ ! $dataDir ]]; then
              echo "MOUNTFOLDER=$defaultDir" | sudo tee -a "$(pwd)/.env" >/dev/null
            fi
            echo
            break
          fi
        done
        echo "TRANSMISSION_WEB_UI=transmission-web-control" | sudo tee -a "$(pwd)/.env" >/dev/null
        echo "TRANSMISSION_DOWNLOAD_QUEUE_SIZE=25" | sudo tee -a "$(pwd)/.env" >/dev/null
        echo "TRANSMISSION_MAX_PEERS_GLOBAL=3000" | sudo tee -a "$(pwd)/.env" >/dev/null
        echo "TRANSMISSION_PEER_LIMIT_GLOBAL=3000" | sudo tee -a "$(pwd)/.env" >/dev/null
        echo "TRANSMISSION_PEER_LIMIT_PER_TORRENT=300" | sudo tee -a "$(pwd)/.env" >/dev/null
        echo "PUID=1000" | sudo tee -a "$(pwd)/.env" >/dev/null
        echo "PGID=1000" | sudo tee -a "$(pwd)/.env" >/dev/null

        echo
        echo "${green}Your variables:${reset}"
        cat $(pwd)/.env
        echo
        read -p "Ready to run the setup? (yes/no): " isReady
        while true; do
          if [[ "${isReady,,}" == "yes" ]] || [[ "${isReady,,}" == "y" ]]; then
            source $(pwd)/setup.sh
            exit
          elif [[ "${isReady,,}" == "no" ]] || [[ "${isReady,,}" == "n" ]]; then
            echo "${yellow}Quitting...${reset}"
            exit
          fi
        done
      fi
      break
    elif [[ ${deleteConfirm,,} == "n" ]]; then
      echo
      echo "${yellow}The .env file needs to be deleted to use this basic script since this recreates it from scratch.${reset}"
      echo "${red}Exiting...${reset}"
      exit
    fi
  done
fi
