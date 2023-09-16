#!/bin/bash

while [ $# -gt 0 ]; do
  case "$1" in
  --azure_subscription=*)
    azure_subscription="${1#*=}"
    ;;
  --rg=*)
    rg="${1#*=}"
    ;;
  --ss=*)
    ss="${1#*=}"
    ;;
  --script_url=*)
    script_url="${1#*=}"
    ;;
  --app_url=*)
    app_url="${1#*=}"
    ;;
  --env_file=*)
    env_file="${1#*=}"
    ;;
  *)
    printf "***************************\n"
    printf "* Error(deploy.sh): Invalid argument (${1}).\n"
    printf "***************************\n"
    exit 1
    ;;
  esac
  shift
done

env_file=${env_file:-$(dirname "$0")/.env}

if [[ "$rg" == "" || "$ss" == "" ]]; then
  printf "***************************\n"
  printf "*Error(deploy.sh): resource group(--rg) and scale set(--ss) are required!*\n"
  printf "***************************\n"
  exit 1
fi

if [[ -f $env_file ]]; then
  AZURE_SUBSCRIPTION=$(grep -w $env_file -e "AZURE_SUBSCRIPTION" | sed "s/AZURE_SUBSCRIPTION=//" | sed "s/\"//g" | sed "s/\'//g" | grep -v "#")
  SCRIPT_URL=$(grep -w $env_file -e "SCRIPT_URL" | sed "s/SCRIPT_URL=//" | sed "s/\"//g" | sed "s/\'//g" | grep -v "#")
  APP_URL=$(grep -w $env_file -e "APP_URL" | sed "s/APP_URL=//" | sed "s/\"//g" | sed "s/\'//g" | grep -v "#")

  if [[ $AZURE_SUBSCRIPTION && "$azure_subscription" == "" ]]; then
    azure_subscription=$AZURE_SUBSCRIPTION
  fi
  if [[ $SCRIPT_URL && "$script_url" == "" ]]; then
    script_url=$SCRIPT_URL
  fi
  if [[ $APP_URL && "$app_url" == "" ]]; then
    app_url=$APP_URL
  fi
fi

if [[ "$azure_subscription" == "" || "$script_url" == "" || "$app_url" == "" ]]; then
  printf "***************************\n"
  printf "*Error(deploy.sh): Azure subscription, install script URL(--script_url) and app download URL(--app_url) are required!*\n"
  printf "***************************\n"
  exit 1
fi

echo ">>> Set Azure subscription <<<"
az account set --subscription $azure_subscription

echo ">>> View the VM instances in a scale set <<<"
az vmss list-instances --resource-group $rg --name $ss --output table

echo ">>> List connection information <<<"
az vmss list-instance-connection-info --resource-group $rg --name $ss

# echo ">>> Delete CustomScriptExtension extension <<<"
# az vmss extension delete --name CustomScriptExtension --resource-group $rg --vmss-name $ss

echo ">>> Apply the Custom Script Extension <<<"
az vmss extension set \
  --publisher Microsoft.Compute \
  --version 1.10 \
  --name CustomScriptExtension \
  --resource-group $rg \
  --vmss-name $ss \
  --force-update \
  --settings '{"commandToExecute": "curl -o install.bat \"'$script_url'\" & install.bat \"'$app_url'\""}'

echo ">>> List extensions <<<"
az vmss extension list --resource-group $rg --vmss-name $ss
