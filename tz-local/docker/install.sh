#!/usr/bin/env bash

function prop { key="${2}=" file="./resources/${1}" rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'); [[ -z "$rslt" ]] && key="${2} = " && rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'); echo "$rslt"; }

export aws_account_id=$(prop 'project' 'aws_account_id')
export aws_region=$(prop 'config' 'region')
export eks_project=$(prop 'project' 'project')
export eks_domain=$(prop 'project' 'domain')
export tz_project=devops-utils
export AWS_DEFAULT_REGION="${aws_region}"
dockerhub_id=$(prop 'project' 'dockerhub_id')
dockerhub_password=$(prop 'project' 'dockerhub_password')

echo "aws_account_id: ${aws_account_id}"
echo "aws_region: ${aws_region}"
echo "eks_project: ${eks_project}"
echo "eks_domain: ${eks_domain}"
echo "dockerhub_id: ${dockerhub_id}"
echo "dockerhub_password: ${dockerhub_password}"

cd tz-local/docker

#DOCKER_URL=${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com

#TAG=${DOCKER_URL}/${tz_project}:latest
TAG=${tz_project}:latest

#aws_account_id=$(aws sts get-caller-identity --query Account --output text)
#aws ecr get-login-password --region ${aws_region} \
#      | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com
#docker login -u="${dockerhub_id}" -p="${dockerhub_password}" ${docker_url}
docker login -u="${dockerhub_id}" -p="${dockerhub_password}"

cp -Rf docker-compose.yml docker-compose.yml_bak
sed -ie "s|\${eks_project}|${eks_project}|g" docker-compose.yml_bak
sed -ie "s|\${eks_domain}|${eks_domain}|g" docker-compose.yml_bak
sed -ie "s|\${tz_project}|${tz_project}|g" docker-compose.yml_bak
sed -ie "s|\${aws_account_id}|${aws_account_id}|g" docker-compose.yml_bak
#sed -ie "s|\${vault_token}|${vault_token}|g" docker-compose.yml_bak

# --no-cache
docker-compose -f docker-compose.yml_bak build
docker-compose -f docker-compose.yml_bak up -d
#docker-compose -f docker-compose.yml_bak down
sleep 10
echo docker exec -it `docker ps | grep docker-${tz_project} | awk '{print $1}'` bash /topzone/tz-local/docker/init2.sh
docker exec -it `docker ps | grep docker-${tz_project} | awk '{print $1}'` bash /topzone/tz-local/docker/init2.sh
#docker exec -it `docker ps | grep docker-${tz_project} | awk '{print $1}'` bash
#docker exec -it docker_devops-utils_1 bash
#bash /topzone/tz-local/docker/init2.sh

exit 0


