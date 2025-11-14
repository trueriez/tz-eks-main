#!/usr/bin/env bash

#set -x
## https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/add-user-role.html

source /root/.bashrc
function prop { key="${2}=" file="/root/.aws/${1}" rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'); [[ -z "$rslt" ]] && key="${2} = " && rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'); echo "$rslt"; }
#bash /topzone/tz-local/resource/makeuser/eks-users.sh
cd /topzone/tz-local/resource/makeuser

eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')

aws_account_id=$(aws sts get-caller-identity --query Account --output text)

export AWS_DEFAULT_PROFILE="default"
aws sts get-caller-identity
kubectl -n kube-system get configmap aws-auth -o yaml
#kubectl get node

#PROJECTS=(default)
PROJECTS=(devops devops-dev default argocd consul monitoring vault)
for item in "${PROJECTS[@]}"; do
  if [[ "${item}" != "NAME" ]]; then
    kubectl create ns ${item}

    staging="dev"
    if [[ "${item/*-dev/}" != "" ]]; then
      staging="prod"
    fi
cat <<EOF > sa.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${item}-svcaccount
  namespace: ${item}
EOF
    kubectl -n ${item} apply -f sa.yaml

    if [ "${staging}" == "prod" ]; then
cat <<EOF > sa.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${item}-stg-svcaccount
  namespace: ${item}
EOF
      kubectl -n ${item} apply -f sa.yaml
    fi
  fi
done
rm -Rf sa.yaml

#eks_role=$(aws iam list-roles --out=text | grep "${eks_project}2" | grep "0000000" | head -n 1 | awk '{print $7}')
pushd `pwd`
cd /topzone/terraform-aws-eks/workspace/base
eks_role=$(terraform output | grep cluster_iam_role_arn | awk '{print $3}' | tr "/" "\n" | tail -n 1 | sed 's/"//g')
popd
echo eks_role: ${eks_role}

# add a eks-users
#kubectl delete -f eks-roles.yaml
#kubectl delete -f eks-rolebindings.yaml
kubectl apply -f eks-roles.yaml
kubectl apply -f eks-rolebindings.yaml
kubectl apply -f eks-rolebindings-developer.yaml

eksctl get iamidentitymapping --cluster ${eks_project}
kubectl auth can-i --list
kubectl auth can-i --list --as=[${eks_project}-k8sDev]
kubectl auth can-i --list --as=${eks_project}-k8sDev

exit 0

# for ${eks_project}-k8sDev
1) Role: devops-developer
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: devops
  name: devops-developer
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["get", "watch", "list"]

2) role Group: ${eks_project}-k8sDev
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${eks_project}-k8sDev
subjects:
- kind: Group
  name: ${eks_project}-k8sDev
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: devops-developer
  apiGroup: rbac.authorization.k8s.io

3) terraform locals.tf
  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${var.account_id}:role/${local.cluster_name}-k8sDev"
      username = "${local.cluster_name}-k8sDev"
      groups   = ["${eks_project}-k8sDev"]
    },

4) vi ~/.kube/sl_${eks_project}
users:
- name: ${eks_project}-k8sDev
  user:
    exec:
      env:
        - name: AWS_PROFILE
          value: ${eks_project}-dev

5) aws credentials
  [profile ${eks_project}-dev]
  role_arn = arn:aws:iam::${aws_account_id}:role/${eks_project}-k8sDev
  source_profile=${eks_project}-dev
  region = ap-northeast-2
  output = json

  [${eks_project}-dev]
  aws_access_key_id = xxxx
  aws_secret_access_key = xxxx


# for ${eks_project}-k8sAdmin
1) Role: devops-developer
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: devops-admin
rules:
- apiGroups: ["", "metrics.k8s.io", "extensions", "apps", "batch"]
  resources: ["*"]
  verbs: ["*"]

2) role Group: ${eks_project}-k8sAdmin
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${eks_project}-k8sAdmin
subjects:
- kind: Group
  name: ${eks_project}-k8sAdmin
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: devops-admin
  apiGroup: rbac.authorization.k8s.io

3) terraform locals.tf
  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${var.account_id}:role/${local.cluster_name}-k8sAdmin"
      username = "${local.cluster_name}-k8sAdmin"
      groups   = ["${eks_project}-k8sAdmin"]
    },

4) vi ~/.kube/sl_${eks_project}
users:
- name: ${eks_project}-k8sAdmin
  user:
    exec:
      env:
        - name: AWS_PROFILE
          value: ${eks_project}-admin

5) aws credentials
  [profile ${eks_project}-admin]
  role_arn = arn:aws:iam::${aws_account_id}:role/${eks_project}-k8sAdmin
  source_profile=${eks_project}-admin
  region = ap-northeast-2
  output = json

  [${eks_project}-admin]
  aws_access_key_id = xxxx
  aws_secret_access_key = xxxx
