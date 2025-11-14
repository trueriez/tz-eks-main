#!/usr/bin/env bash

source /root/.bashrc
function prop { key="${2}=" file="/root/.aws/${1}" rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'); [[ -z "$rslt" ]] && key="${2} = " && rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'); echo "$rslt"; }
cd /topzone/tz-local/resource/docker-repo

#set -x
shopt -s expand_aliases
alias k='kubectl'

eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
dockerhub_id=$(prop 'project' 'dockerhub_id')
dockerhub_password=$(prop 'project' 'dockerhub_password')
docker_url=$(prop 'project' 'docker_url')

apt-get update -y
apt-get -y install docker.io jq
usermod -G docker topzone
chown -Rf topzone:topzone /var/run/docker.sock

mkdir -p ~/.docker
docker login -u="${dockerhub_id}" -p="${dockerhub_password}" ${docker_url}

sleep 2

cat ~/.docker/config.json
#{"auths":{"https://index.docker.io/v1/":{"username":"devops","password":"devops!323","email":"topzone8713@gmail.com","auth":"ZGV2b3BzOmRldm9wcyEzMjM="}}}
mkdir -p /home/topzone/.docker
cp -Rf ~/.docker/config.json /home/topzone/.docker/config.json
chown -Rf topzone:topzone /home/topzone/.docker

kubectl delete secret registry-creds -n kube-system
kubectl create secret generic registry-creds -n kube-system \
    --from-file=.dockerconfigjson=/home/topzone/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson

#  --docker-server=https://nexus.topzone.co.kr:5000/v2/ \
#kubectl get secret registry-creds --output=yaml

#echo "
#apiVersion: v1
#kind: Secret
#metadata:
#  name: registry-creds
#data:
#  .dockerconfigjson: docker-config
#type: kubernetes.io/dockerconfigjson
#" > docker-config.yaml
#
DOCKER_CONFIG=$(cat /home/topzone/.docker/config.json | base64 | tr -d '\r')
DOCKER_CONFIG=$(echo $DOCKER_CONFIG | sed 's/ //g')
echo "${DOCKER_CONFIG}"
cp docker-config.yaml docker-config.yaml_bak
sed -i "s/DOCKER_CONFIG/${DOCKER_CONFIG}/g" docker-config.yaml_bak
kubectl apply -f docker-config.yaml_bak

#kubectl delete -f clusterPullSecret.yaml
#kubectl apply -f clusterPullSecret.yaml

#PROJECTS=(default)
PROJECTS=(argocd consul jenkins default devops devops-dev monitoring vault)
for item in "${PROJECTS[@]}"; do
  if [[ "${item}" != "NAME" ]]; then
    echo "===================== ${item}"
    kubectl delete secret registry-creds -n ${item}
    kubectl create secret generic registry-creds \
      -n ${item} \
      --from-file=.dockerconfigjson=/home/topzone/.docker/config.json \
      --type=kubernetes.io/dockerconfigjson
  fi
done

kubectl delete secret docker-config -n jenkins
kubectl create secret generic docker-config \
     -n jenkins \
    --from-file=config.json=/home/topzone/.docker/config.json

kubectl get secret registry-creds --output=yaml
kubectl get secret registry-creds -n vault --output=yaml

kubectl get secret registry-creds --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode

exit 0

spec:
  containers:
  - name: private-reg-container
    image: <your-private-image>
  imagePullSecrets:
    - name: registry-creds

docker login index.docker.io
docker pull index.docker.io/devops-utils2:latest
