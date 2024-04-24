#!/bin/bash

# download files
# --file: file(s) to download. eg.: --file="file1, file2"
# --user: remote server user. eg.: --user=admin
# --host: server(s) where remote files are located. eg.: --host="10.0.0.1, 10.0.0.2"
# --path: where to download files. eg.: --path=/local_mydir (optional)
# --delete_remote_file: if set, delete the remote file when downloaded. eg.: --delete_remote_file=yes (optional)
# --ssk_key: private ssh key eg.: --ssh_key=~/.ssh/id_rsa (optional)
# eg.: ./download_file.sh --file="file1.tx,file2.tx" --path="~/myfiles" --user=admin --host=10.0.0.1 --ssh_key=~/.ssh/id_rsa --delete_remote_file=yes

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
  --delete_remote_file=*)
    delete_remote_file="${1#*=}"
    ;;
  --ssh_key=*)
    ssh_key="${1#*=}"
    ;;
  *)
    printf "***************************\n"
    printf "* Error(download_file.sh): Invalid argument (${1}).\n"
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
    f=$(echo $file | sed -e 's/,/ /g')
    if [[ $ssh_key != "" ]]; then
      scp -i $ssh_key $user@$h:$f $path
    else
      scp $user@$h:$f $path
    fi

    if [ $? -eq 0 ]; then
      echo "File downloaded successfully."

      if [[ $delete_remote_file == "yes" ]]; then
        if [[ $ssh_key != "" ]]; then
            ssh -i $ssh_key $user@$h "rm $f"
        else
            ssh $user@$h "rm $f"
        fi

        if [ $? -eq 0 ]; then
            echo "File deleted remotely."
        else
            echo "Error: Failed to delete file remotely."
        fi
      fi
    else
      echo "Error: Failed to download file."
    fi
  fi
done
