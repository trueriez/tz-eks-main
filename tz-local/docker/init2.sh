#!/usr/bin/env bash

function prop { key="${2}=" file="/root/.aws/${1}" rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'); [[ -z "$rslt" ]] && key="${2} = " && rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'); echo "$rslt"; }

export KUBE_CONFIG_PATH=/root/.kube/config

cd /topzone

sudo mkdir -p /home/topzone/.aws
sudo cp -Rf /topzone/resources/config /home/topzone/.aws/config
sudo cp -Rf /topzone/resources/credentials /home/topzone/.aws/credentials
sudo cp -Rf /topzone/resources/project /home/topzone/.aws/project
sudo chown -Rf topzone:topzone /home/topzone/.aws
sudo rm -Rf /root/.aws
sudo cp -Rf /home/topzone/.aws /root/.aws

sudo mkdir -p /home/topzone/.kube
sudo cp -Rf /topzone/resources/kubeconfig_${eks_project} /home/topzone/.kube/config
sudo chown -Rf topzone:topzone /home/topzone/.kube
sudo rm -Rf /root/.kube
sudo cp -Rf /home/topzone/.kube /root/.kube

git config --global --add safe.directory '*'

export AWS_ACCESS_KEY_ID=$(prop 'credentials' 'aws_access_key_id' ${eks_project})
export AWS_SECRET_ACCESS_KEY=$(prop 'credentials' 'aws_secret_access_key' ${eks_project})
export AWS_DEFAULT_REGION=$(prop 'config' 'region' ${eks_project})

PROJECT_BASE2='/topzone/terraform-aws-iam/workspace/base'
cp -Rf /topzone/resources/${eks_project} ${PROJECT_BASE2}
cp -Rf /topzone/resources/${eks_project}.pub ${PROJECT_BASE2}
cp -Rf /topzone/resources/kubeconfig_${eks_project} ${PROJECT_BASE2}
cp -Rf /topzone/resources/.auto.tfvars ${PROJECT_BASE2}
echo "===== PROJECT_BASE2: ${PROJECT_BASE2}"
cd ${PROJECT_BASE2}
if [ ! -d "${PROJECT_BASE2}/.terraform" ]; then
  terraform init
  terraform plan -var-file=".auto.tfvars"
  terraform apply -var-file=".auto.tfvars" -auto-approve
  if [[ $? != 0 ]]; then
    exit 1
  fi
  #terraform destroy -auto-approve
fi

export PROJECT_BASE='/topzone/terraform-aws-eks/workspace/base'
cp -Rf /topzone/resources/${eks_project} ${PROJECT_BASE}
cp -Rf /topzone/resources/${eks_project}.pub ${PROJECT_BASE}
cp -Rf /topzone/resources/kubeconfig_${eks_project} ${PROJECT_BASE}
cp -Rf /topzone/resources/.auto.tfvars ${PROJECT_BASE}
echo "===== PROJECT_BASE: ${PROJECT_BASE}"
cd ${PROJECT_BASE}
if [ ! -d "${PROJECT_BASE}/.terraform" ]; then
  rm -Rf ${eks_project}*
  ssh-keygen -t rsa -C ${eks_project} -P "" -f ${eks_project} -q
  chmod -Rf 600 ${eks_project}*
  mkdir -p /home/topzone/.ssh
  cp -Rf ${eks_project}* /home/topzone/.ssh
  cp -Rf ${eks_project}* /topzone/resources
  chown -Rf topzone:topzone /home/topzone/.ssh
  chown -Rf topzone:topzone /topzone/resources

  rm -Rf ${PROJECT_BASE}/lb2.tf
  rm -Rf ${PROJECT_BASE}/.terraform
  rm -Rf ${PROJECT_BASE}/terraform.tfstate
  rm -Rf ${PROJECT_BASE}/terraform.tfstate.backup

  terraform init
  terraform plan -var-file=".auto.tfvars"
  terraform apply -var-file=".auto.tfvars" -auto-approve
  if [[ $? != 0 ]]; then
    exit 1
  fi

  terraform output kubeconfig | head -n -1 | tail -n +2 > kubeconfig_${eks_project}

  #aws eks update-kubeconfig --region ap-northeast-2 --name ${eks_project}
  #cp -Rf /root/.kube/config ${PROJECT_BASE}/kubeconfig_${eks_project}

#  if [[ $? != 0 ]]; then
#    echo "############ failed provisioning! ############"
#    terraform destroy -auto-approve
#    bash /topzone/scripts/eks_remove_all.sh
##    bash /topzone/scripts/eks_remove_all.sh cleanTfFiles
#    exit 1
#  fi

  export KUBECONFIG=`ls kubeconfig_${eks_project}*`
  export KUBE_CONFIG_PATH=/root/.kube/config
  cp -Rf ${KUBECONFIG} /topzone/resources/kubeconfig_${eks_project}
  echo "      env:" >> /topzone/resources/kubeconfig_${eks_project}
  echo "        - name: AWS_PROFILE" >> /topzone/resources/kubeconfig_${eks_project}
  echo '          value: '"${eks_project}"'' >> /topzone/resources/kubeconfig_${eks_project}

  sudo mkdir -p /root/.kube
  sudo cp -Rf ${KUBECONFIG} /root/.kube/config
  sudo chmod -Rf 600 /root/.kube/config
  mkdir -p /home/topzone/.kube
  cp -Rf ${KUBECONFIG} /home/topzone/.kube/config
  sudo chmod -Rf 600 /home/topzone/.kube/config
  export KUBECONFIG=/home/topzone/.kube/config
  sudo chown -Rf topzone:topzone /home/topzone

  cp -Rf lb2.tf_ori lb2.tf

  terraform init
  terraform plan -var-file=".auto.tfvars"
  terraform apply -var-file=".auto.tfvars" -auto-approve

  bash /topzone/scripts/eks_addtion.sh

  echo "
  ##[ Summary ]##########################################################
    - in Docker
      export KUBECONFIG='/topzone/kubeconfig_${eks_project}'

    - outside of Docker
      export KUBECONFIG='terraform-aws-eks/workspace/base/kubeconfig_${eks_project}'

    - kubectl get nodes
    - S3 bucket: ${s3_bucket_id}
  #######################################################################
  " > /topzone/info
  cat /topzone/info
fi

exit 0
