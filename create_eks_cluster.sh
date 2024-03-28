#!/bin/bash

# "eks_cluster.yaml" filesample
# apiVersion: eksctl.io/v1alpha5
# kind: ClusterConfig

# metadata:
#   name: myapp
#   region: eu-central-1

# vpc:
#   clusterEndpoints:
#     publicAccess: true
#     privateAccess: true

# nodeGroups:
#   - name: ng-1
#     instanceType: t3.medium
#     desiredCapacity: 2
#     ssh:
#       allow: true

while [ $# -gt 0 ]; do
  case "$1" in
  --name=*)
    name="${1#*=}"
    ;;
  --region=*)
    region="${1#*=}"
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

region=${region-"eu-central-1"}

eksctl delete cluster --name $name --region $region --wait
eksctl create cluster -f eks_cluster.yaml
