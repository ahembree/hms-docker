#!/bin/bash

# A setup script that will be easy to understand and
# be used to configure the .env file for the install

trap "exit" INT
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`
defaultDir="~/hms-docker_data"

if [[ -f "$(pwd)/.env" ]] ; then
  read -p "${yellow}THIS WILL ERASE YOUR CURRENT .env FILE! Are you sure you want to continue? [y/n]: ${reset}" deleteConfirm
  while true; do
    if [[ ${deleteConfirm,,} == "y" ]]; then
      rm -f "$(pwd)/.env"
      echo "${yellow}.env file deleted${reset}"
      break
    elif [[ ${deleteConfirm,,} == "n" ]]; then
      echo "${yellow}The .env file needs to be deleted to use this basic script.${reset}"
      echo "${red}Exiting...${reset}"
      exit
    fi
  done
fi
if [[ ! -f "$(pwd)/.env" ]] ; then
  echo "Where would you like your data directory to be? This is where all hms-docker data will be stored. (e.g. /path/to/folder/hms-docker_data)"
  read -p "If you're not sure, you can use the default of $defaultDir by leaving this blank: " dataDir
  if [[ $dataDir ]]; then
    echo "DATAFOLDER=$dataDir" | sudo tee -a "$(pwd)/.env" >/dev/null
  elif [[ ! $dataDir ]]; then
    echo "DATAFOLDER=$defaultDir" | sudo tee -a "$(pwd)/.env" >/dev/null
  fi
fi
