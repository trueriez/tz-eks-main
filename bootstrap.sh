#!/bin/bash

export MSYS_NO_PATHCONV=1
export tz_project=devops-utils

function cleanTfFiles() {
  rm -Rf kubeconfig_*
  rm -Rf .terraform
  rm -Rf terraform.tfstate
  rm -Rf terraform.tfstate.backup
  rm -Rf .terraform.lock.hcl
  rm -Rf s3_bucket_id
  rm -Rf ./config_*
  rm -Rf ./terraform-aws-eks/workspace/base/lb2.tf
  rm -Rf ./terraform-aws-eks/workspace/base/.terraform
}

DOCKER_NAME=`docker ps | grep docker-${tz_project} | awk '{print $1}'`
echo "======= DOCKER_NAME: ${DOCKER_NAME}"

if [[ ${DOCKER_NAME} == "" && "$1" == "remove" ]]; then
  pushd `pwd`
  cd terraform-aws-eks/workspace/base
  cleanTfFiles
  popd
  cd terraform-aws-iam/workspace/base
  cleanTfFiles
  exit 0
fi

# bash bootstrap.sh remove
if [[ "$1" == "remove" ]]; then
  docker exec -it ${DOCKER_NAME} bash /topzone/scripts/eks_remove_all.sh
  if [[ $? != 0 ]]; then
    echo "failed to remove resources!"
    exit 1
  fi
  docker exec -it ${DOCKER_NAME} bash /topzone/scripts/eks_remove_all.sh cleanTfFiles
  exit 0
fi

if [[ "$1" == "sh" ]]; then
  docker exec -it `docker ps | grep docker-${tz_project} | awk '{print $1}'` bash
  exit 0
fi

# bash bootstrap.sh
#docker exec -it ${DOCKER_NAME} bash
bash tz-local/docker/install.sh
echo docker exec -it ${DOCKER_NAME} bash /topzone/tz-local/docker/init2.sh
docker exec -it ${DOCKER_NAME} bash /topzone/tz-local/docker/init2.sh

exit 0

# install in docker
export docker_user="topzone8713"
bash /topzone/tz-local/docker/init2.sh

# remove all resources
docker exec -it ${DOCKER_NAME} bash
bash /topzone/scripts/eks_remove_all.sh
bash /topzone/scripts/eks_remove_all.sh cleanTfFiles

#docker container stop $(docker container ls -a -q) && docker system prune -a -f --volumes
