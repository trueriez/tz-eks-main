#!/usr/bin/env bash

# bash /init.sh
cd /topzone/tz-local/docker
export KUBE_CONFIG_PATH=/root/.kube/config

echo "vault_token: ${vault_token}"

rm -Rf /topzone/info

export AWS_PROFILE=default
function propProject {
	grep "${1}" "/topzone/resources/project" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
export eks_project=$(propProject 'project')
export aws_account_id=$(propProject 'aws_account_id')
PROJECT_BASE='/topzone/terraform-aws-eks/workspace/base'

function propConfig {
  grep "${1}" "/topzone/resources/config" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
aws_region=$(propConfig 'region')
export AWS_DEFAULT_REGION="${aws_region}"

echo "eks_project: ${eks_project}"
echo "aws_region: ${aws_region}"
echo "aws_account_id: ${aws_account_id}"

echo "
export AWS_DEFAULT_REGION=${aws_region}
export VAULT_ADDR=https://vault.${eks_domain}
export KUBE_CONFIG_PATH='~/.kube/config'
alias k='kubectl'
alias KUBECONFIG='~/.kube/config'
alias base='cd /topzone/terraform-aws-eks/workspace/base'
alias base2='cd /topzone/terraform-aws-iam/workspace/base'
alias scripts='cd /topzone/scripts'
alias tplan='terraform plan -var-file=".auto.tfvars"'
alias tapply='terraform apply -var-file=".auto.tfvars" -auto-approve'
alias ll='ls -al'
export PAGER=cat
export PATH=\"/root/.krew/bin:$PATH\"
" >> /root/.bashrc

cat >> /root/.bashrc <<EOF
function prop {
  key="\${2}=" file="/root/.aws/\${1}" rslt=\$(grep "\${3:-}" "\$file" -A 10 | grep "\$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g')
  [[ -z "\$rslt" ]] && key="\${2} = " && rslt=\$(grep "\${3:-}" "\$file" -A 10 | grep "\$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g')
  echo "\$rslt"
}
EOF

cp -Rf /root/.bashrc /home/topzone/.bashrc
chown -Rf topzone:topzone /home/topzone/.bashrc

echo "###############"
if [[ "${INSTALL_INIT}" == 'true' || ! -f "/root/.aws/config" ]]; then
  VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
  sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
  sudo chmod +x /usr/local/bin/argocd

  (
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
  )
fi

kubectl krew install neat

#wget https://github.com/lensapp/lens/releases/download/v4.1.5/Lens-4.1.5.amd64.deb
#sudo dpkg -i Lens-4.1.5.amd64.deb

export KUBECONFIG=`ls kubeconfig_${eks_project}*`
cp -Rf $KUBECONFIG /topzone/config_${eks_project}
sudo mkdir -p /root/.kube
sudo cp -Rf $KUBECONFIG /root/.kube/config
sudo chmod -Rf 600 /root/.kube/config
mkdir -p /home/topzone/.kube
cp -Rf $KUBECONFIG /home/topzone/.kube/config
sudo chmod -Rf 600 /home/topzone/.kube/config
export KUBECONFIG=/home/topzone/.kube/config
sudo chown -Rf topzone:topzone /home/topzone

echo "      env:" >> ${PROJECT_BASE}/kubeconfig_${eks_project}
echo "        - name: AWS_PROFILE" >> ${PROJECT_BASE}/kubeconfig_${eks_project}
echo '          value: '"${eks_project}"'' >> ${PROJECT_BASE}/kubeconfig_${eks_project}

export s3_bucket_id=`terraform output | grep s3-bucket | awk '{print $3}'`
echo $s3_bucket_id > s3_bucket_id

#export s3_bucket_id=`terraform output | grep s3-bucket | awk '{print $3}'`
#echo $s3_bucket_id > s3_bucket_id
#master_ip=`terraform output | grep -A 2 "public_ip" | head -n 1 | awk '{print $3}'`
#export master_ip=`echo $master_ip | sed -e 's/\"//g;s/ //;s/,//'`

# bash /topzone/scripts/eks_addtion.sh

#bastion_ip=$(terraform output | grep "bastion" | awk '{print $3}')
#echo "
#Host ${bastion_ip}
#  StrictHostKeyChecking   no
#  LogLevel                ERROR
#  UserKnownHostsFile      /dev/null
#  IdentitiesOnly yes
#  IdentityFile /root/.ssh/${eks_project}
#" >> /root/.ssh/config
#sudo chown -Rf topzone:topzone /root/.ssh/config

#secondary_az1_ip=$(terraform output | grep "secondary-az1" | awk '{print $3}')

echo "
##[ Summary ]##########################################################
  - in VM
    export KUBECONFIG='/topzone/kubeconfig_${eks_project}'

  - outside of VM
    export KUBECONFIG='kubeconfig_${eks_project}'

  - kubectl get nodes
#######################################################################
" >> /topzone/info
cat /topzone/info

sudo /usr/sbin/sshd -D

exit 0

#helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
#helm repo update
#helm install prometheus-operator prometheus-community/kube-prometheus-stack

###################################################################
cd /topzone/tz-local/docker

dockerhub_id=$(prop 'project' 'dockerhub_id')
dockerhub_password=$(prop 'project' 'dockerhub_password')
docker_url=$(prop 'project' 'docker_url')

#aws_account_id=$(aws sts get-caller-identity --query Account --output text)
#aws_region=ap-northeast-2
SNAPSHOT_IMG=devops-utils2
TAG=latest

#aws ecr create-repository \
#    --repository-name $SNAPSHOT_IMG \
#    --image-tag-mutability IMMUTABLE

#aws ecr get-login-password --region ${aws_region} \
#      | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com
#DOCKER_URL=${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com
#DOCKER_URL=xxxxxxxx.dkr.ecr.ap-northeast-2.amazonaws.com

#docker login --username AWS -p $(aws ecr get-login-password --region ${aws_region}) ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/
#  DOCKER_URL=${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com

DOCKER_URL=index.docker.io
dockerhub_id=topzone8713
dockerhub_password=''
echo $dockerhub_password | docker login -u ${dockerhub_id} --password-stdin ${DOCKER_URL}

#docker container stop $(docker container ls -a -q) && docker system prune -a -f --volumes
TAG=latest
# --no-cache
docker image build -t ${SNAPSHOT_IMG} . -f BaseDockerfile
docker tag ${SNAPSHOT_IMG}:latest ${dockerhub_id}/${SNAPSHOT_IMG}:${TAG}
docker push ${dockerhub_id}/${SNAPSHOT_IMG}:${TAG}

#docker tag ${DOCKER_URL}/${SNAPSHOT_IMG}:${TAG} ${DOCKER_URL}/devops-utils2:latest
#docker push ${DOCKER_URL}/devops-utils2:latest

docker tag ${SNAPSHOT_IMG}:latest topzone8713/${SNAPSHOT_IMG}:${TAG}
docker push topzone8713/${SNAPSHOT_IMG}:${TAG}
