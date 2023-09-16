#!/bin/bash

# Example of how to run this script
# sudo kill -9 $(sudo pgrep -f update_upstream_servers.sh); nohup ~/update_upstream_servers.sh --upstream_name=prod_servers --config_file=/etc/nginx/sites-enabled/myapp.config 1>/dev/null 2>/dev/null &

while [ $# -gt 0 ]; do
  case "$1" in
  --rg=*)
    rg="${1#*=}"
    ;;
  --ss=*)
    ss="${1#*=}"
    ;;
  --upstream_name=*)
    upstream_name="${1#*=}"
    ;;
  --port=*)
    port="${1#*=}"
    ;;
  --config_file=*)
    config_file="${1#*=}"
    ;;
  *)
    printf "***************************\n"
    printf "* Invalid argument (${1}).\n"
    printf "***************************\n"
    exit 1
    ;;
  esac
  shift
done

upstream_name=${upstream_name:-"prod_servers"}
port=${port:-"443"}
config_file=${config_file:-"/etc/nginx/sites-enabled/default"}
current_ips=""

if [[ ! -f "$config_file" ]]; then
  printf "***************************\n"
  printf "*Error(--config_file): $config_file is not found!*\n"
  printf "***************************\n"
  exit 1
fi

trim() {
  echo "$@" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

replace() {
  if [[ $1 == "" ]] || [[ $2 == "" ]]; then
    printf "***************************\n"
    printf "* replace(): invalid arguments\n!"
    printf "***************************\n"
    exit 1
  fi
  echo "$1" | sed -e "s/$2/$3/gI"
}

is_valid_ip() {
  local ip=$1
  local stat=1

  if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    IFS='.' read -ra ip_parts <<<"$ip"
    if [[ ${#ip_parts[@]} -eq 4 ]]; then
      stat=0
      for part in "${ip_parts[@]}"; do
        if ! [[ $part =~ ^[0-9]+$ ]] || [[ $part -lt 0 || $part -gt 255 ]]; then
          stat=1
          break
        fi
      done
    fi
  fi

  return $stat
}

update_nginx_config() {
  ips=$(az vmss nic list -g $rg --vmss-name $ss | grep -w -i 'privateIPAddress')
  ips=$(trim $(replace "$ips" '[a-z":,]' ''))

  if [[ $current_ips == $ips ]]; then
    echo "same IPs :>> $current_ips"
    return 0
  fi

  current_ips=$ips
  upstream_servers=""

  for ip in $(trim $(replace "$ips" '[a-z":,]' '')); do
    if is_valid_ip "$ip"; then
      upstream_servers="$upstream_servers\n  server  $ip:$port;"
    fi
  done

  if [[ $upstream_servers != "" ]]; then
    upstream_servers="upstream $upstream_name {\n  least_conn;$upstream_servers\n}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
      upstream_servers=$(replace "$upstream_servers" '\\n' '\\\n')
      upstream_servers="$upstream_servers\\\n"
    fi
    new_config=$(cat $config_file | sed '/upstream '$upstream_name' {/,/}/c\'$'\n'"$upstream_servers")
    sudo nginx -t
    echo -e "$new_config" >$upstream_name.config.tmp
    sudo mv $upstream_name.config.tmp $config_file
    sudo nginx -s reload
  fi
}

while true; do
  echo "updating nginx config..."
  update_nginx_config
  sleep 5
done
