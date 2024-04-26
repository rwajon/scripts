#!/bin/bash

# download directories
# --dir: directories to download. eg.: --dir="dir1, dir2"
# --user: remote server user. eg.: --user=admin
# --host: server(s) where remote dirs are located. eg.: --host="10.0.0.1, 10.0.0.2"
# --path: where to download directories. eg.: --path=/local_mydir (optional)
# --delete_remote_dir: if set, delete the remote directory when downloaded. eg.: --delete_remote_dir=yes (optional)
# --ssk_key: private ssh key eg.: --ssh_key=~/.ssh/id_rsa (optional)
# eg.: ./download_dir.sh --dir="dir1,dir2" --path="~/mydirs" -user=admin --host=10.0.0.1 --ssh_key=~/.ssh/id_rsa_ossix --delete_remote_dir=yes

while [ $# -gt 0 ]; do
  case "$1" in
  --dir=*)
    dir="${1#*=}"
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
  --delete_remote_dir=*)
    delete_remote_dir="${1#*=}"
    ;;
  --ssh_key=*)
    ssh_key="${1#*=}"
    ;;
  *)
    printf "***************************\n"
    printf "* Error(download_dir.sh): Invalid argument (${1}).\n"
    printf "***************************\n"
    exit 1
    ;;
  esac
  shift
done

path=${path:-"."}

mkdir -p $path

for h in $(echo ${host} | sed -e 's/,/ /g'); do
  if [[ "$user" ]] && [[ "$h" ]]; then
    f=$(echo $dir | sed -e 's/,/ /g')
    if [[ $ssh_key != "" ]]; then
      scp -i $ssh_key -r $user@$h:$f $path
    else
      scp -r $user@$h:$f $path
    fi

    if [ $? -eq 0 ]; then
      echo "Directory downloaded successfully."

      if [[ $delete_remote_dir == "yes" ]]; then
        if [[ $ssh_key != "" ]]; then
            ssh -i $ssh_key $user@$h "rm -rf $f"
        else
            ssh $user@$h "rm -rf $f"
        fi

        if [ $? -eq 0 ]; then
            echo "Directory deleted remotely."
        else
            echo "Error: Failed to delete directory remotely."
        fi
      fi
    else
      echo "Error: Failed to download directory."
    fi
  fi
done
