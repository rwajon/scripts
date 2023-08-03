#!/bin/bash

# Parameters
# --branches: branches to delete
# --b: alias for branches
# --exclude: branches to exclude
# --e: alias for exclude
# --force: force delete
# --e: alias for force

# Delete multiple branches example:
# ./delete_git_branches.sh --branches=br-1,br-2,...br-n

# Delete all branches and exclude specified ones example:
# ./delete_git_branches.sh --exclude=br-1,br-2,...br-n


while [ $# -gt 0 ]; do
  case "$1" in
  --branches=*)
    branches="${1#*=}"
    ;;
  --b=*) # alias for --branches
    b="${1#*=}"
    ;;
  --exclude=*)
    exclude="${1#*=}"
    ;;
  --e=*) # alias for --exclude
    e="${1#*=}"
    ;;
  --force=*)
    force="${1#*=}"
    ;;
  --f=*) # alias for --force
    f="${1#*=}"
    ;;
  *)
    printf "***************************\n"
    printf "* Error: Invalid argument (${1}).\n"
    printf "***************************\n"
    exit 1
    ;;
  esac
  shift
done

branches=$(echo ${b:-$branches} | sed -e 's/[][]//g;s/ //g;s/,/ /g')
exclude=$(echo ${e:-$exclude} | sed -e 's/[][]//g;s/ //g;s/,/ /g')
force=$(echo ${f:-$force} | tr '[:upper:]' '[:lower:]')

if [[ $branches == "" ]] && [[ $exclude == "" ]]; then
  echo "Branches to delete or to exclude are required!"
  echo "Example \"delete_git_branches --branches=br-1,br-2...br-n\" or \"delete_git_branches --exclude=br-1,br-2...br-n\""
  exit 1
fi

if [[ $branches ]] && [[ $exclude == "" ]]; then
  echo "Do you want to delete all branches(${branches// /,})[y=Yes, n=No]?: "
else
  echo "Do you want to delete all branches except(${exclude// /,})[y=Yes, n=No]?: "
fi

read answer
answer=$(echo $answer | tr '[:upper:]' '[:lower:]')

if [[ $answer == "no" ]] || [[ $answer == "n" ]]; then
  exit 1
fi

if [[ $force == "yes" ]] || [[ $force == "y" ]]; then
  if [[ $branches ]]; then
    command="git branch -D $branches"
  fi
  if [[ $exclude ]] && [[ $branches == "" ]]; then
    command="git branch | grep -v ${exclude// / | grep -v } | grep -v $(git br --show-current) | xargs git branch -D"
  fi
else
  if [[ $branches ]]; then
    command="git branch -d $branches"
  fi
  if [[ $exclude ]] && [[ $branches == "" ]]; then
    command="git branch | grep -v ${exclude// / | grep -v } | grep -v $(git br --show-current) | xargs git branch -d"
  fi
fi

echo $command
eval $command
