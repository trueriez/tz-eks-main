#!/usr/bin/env bash

PROJECT_BASE='/topzone/terraform-aws-eks/workspace/base'
cd ${PROJECT_BASE}

function prop {
	grep "${2}" "/home/topzone/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
aws_region=$(prop 'config' 'region')
eks_project=$(prop 'project' 'project')

source /root/.bashrc

bash /topzone/tz-local/resource/makeuser/eks-users.sh

bash /topzone/tz-local/resource/docker-repo/install.sh
bash /topzone/tz-local/resource/persistent-storage/install.sh
bash /topzone/tz-local/resource/ingress_nginx/install.sh
bash /topzone/tz-local/resource/autoscaler/install.sh

bash /topzone/tz-local/resource/monitoring/install.sh
bash /topzone/tz-local/resource/monitoring/rules/update.sh

bash /topzone/tz-local/resource/consul/install.sh
bash /topzone/tz-local/resource/vault/helm/install.sh

exit 0

# Need to unseal vault manually !!!!
bash bootstrap.sh sh
# Go to /topzone/tz-local/resource/vault/helm/install.sh again
vi resources/unseal.txt

bash bootstrap.sh sh

# vault operator unseal
bash /topzone/tz-local/resource/vault/data/vault_user.sh
bash /topzone/tz-local/resource/vault/vault-injection/install.sh
bash /topzone/tz-local/resource/vault/vault-injection/update.sh

bash /topzone/tz-local/resource/argocd/helm/install.sh
bash /topzone/tz-local/resource/jenkins/helm/install.sh

exit 0

bash /topzone/tz-local/resource/vault/external-secrets/install.sh
