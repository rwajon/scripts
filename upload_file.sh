#!/bin/bash

# uplod file to server(s)
# --files: file(s) to upload. eg.: --file="file1, file2"
# --user: remote server user. eg.: --user=admin
# --host: server(s) where to upload files. eg.: --host="10.0.0.1, 10.0.0.2"
# --path: where to upload files. eg.: --path=/mydir (optional)
# --ssk_key: private ssh key eg.: --path=~/.ssh/id_rsa (optional)

while [ $# -gt 0 ]; do
  case "$1" in
  --file=*)
    file="${1#*=}"
    ;;
  --user=*)
    user="${1#*=}"
    ;;
  --host=*)
    host="${1#*=}"
    ;;
  --path=*)
    path="${1#*=}"
    ;;
  --ssh_key=*)
    ssh_key="${1#*=}"
    ;;
  *)
    printf "***************************\n"
    printf "* Error(upload_file.sh): Invalid argument (${1}).\n"
    printf "***************************\n"
    exit 1
    ;;
  esac
  shift
done

for f in $(echo ${file} | sed -e 's/,/ /g'); do
  if [[ ! -f "$f" ]]; then
    printf "***************************\n"
    printf "*Error(upload_file.sh): $f is not found!*\n"
    printf "***************************\n"
    exit 1
  fi
done

for h in $(echo ${host} | sed -e 's/,/ /g'); do
  if [[ "$user" ]] && [[ "$h" ]]; then
    if [[ $ssh_key != "" ]]; then
      scp -i $ssh_key $(echo $file | sed -e 's/,/ /g') $user@$h:${path:-"~"}
    else
      scp $(echo $file | sed -e 's/,/ /g') $user@$h:${path:-"~"}
    fi
  fi
done
