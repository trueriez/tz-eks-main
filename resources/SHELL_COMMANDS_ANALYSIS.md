# 프로젝트 쉘스크립트 명령어 종합 분석

## 📋 목차
1. [스크립트 파일 구조](#스크립트-파일-구조)
2. [기본 쉘 명령어](#기본-쉘-명령어)
3. [AWS CLI 명령어](#aws-cli-명령어)
4. [Kubernetes 명령어](#kubernetes-명령어)
5. [Docker 명령어](#docker-명령어)
6. [Terraform 명령어](#terraform-명령어)
7. [Helm 명령어](#helm-명령어)
8. [텍스트 처리 명령어](#텍스트-처리-명령어)
9. [기타 도구](#기타-도구)
10. [공통 패턴](#공통-패턴)

---

## 스크립트 파일 구조

### 주요 스크립트 파일 (총 51개)
```
tz-eks-main/
├── bootstrap.sh                    # 메인 부트스트랩 스크립트
├── scripts/
│   ├── eks_addtion.sh             # EKS 추가 리소스 설치
│   └── eks_remove_all.sh          # 모든 리소스 삭제
├── tz-local/
│   ├── docker/
│   │   ├── install.sh             # Docker 컨테이너 설치
│   │   ├── init2.sh               # 초기화 스크립트
│   │   ├── k8s.sh                 # K8s 배포 스크립트
│   │   └── vault.sh               # Vault 관련
│   └── resource/
│       ├── argocd/install.sh      # ArgoCD 설치
│       ├── jenkins/helm/install.sh # Jenkins 설치
│       ├── monitoring/install.sh   # 모니터링 스택 설치
│       ├── vault/helm/install.sh   # Vault 설치
│       ├── ingress_nginx/install.sh # Nginx Ingress 설치
│       ├── makeuser/eks-users.sh   # EKS 사용자 생성
│       └── ... (기타 리소스 설치 스크립트)
└── terraform-aws-eks/
    └── scripts/
        └── eks-main-bastion-init.sh # Bastion 초기화
```

---

## 기본 쉘 명령어

### 1. 환경 변수 설정
```bash
export MSYS_NO_PATHCONV=1              # Windows Git Bash 경로 변환 비활성화
export tz_project=devops-utils         # 프로젝트 이름
export AWS_DEFAULT_REGION="ap-northeast-2"
export KUBECONFIG=/root/.kube/config
export VAULT_ADDR=https://vault.default.example.com
```

### 2. 함수 정의
```bash
# 간단한 함수
function cleanTfFiles() {
  rm -Rf .terraform
  rm -Rf terraform.tfstate
}

# 복잡한 prop 함수 (설정 파일에서 값 추출)
function prop {
  key="${2}="
  file="/root/.aws/${1}"
  rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g')
  [[ -z "$rslt" ]] && key="${2} = " && rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g')
  echo "$rslt"
}

# 사용 예시
eks_project=$(prop 'project' 'project')
aws_region=$(prop 'config' 'region')
```

### 3. 조건문
```bash
# 기본 if 문
if [[ "${DOCKER_NAME}" == "" ]]; then
  echo "Docker container not found"
  exit 1
fi

# 여러 조건
if [[ "${DOCKER_NAME}" == "" && "$1" == "remove" ]]; then
  cleanTfFiles
fi

# 종료 상태 확인
if [[ $? != 0 ]]; then
  echo "failed to remove resources!"
  exit 1
fi
```

### 4. 디렉토리 관리
```bash
pushd `pwd`                           # 현재 디렉터리 스택에 저장
cd /topzone/terraform-aws-eks/workspace/base
# ... 작업 수행 ...
popd                                  # 이전 디렉터리로 복귀

mkdir -p /home/topzone/.aws           # 디렉터리 생성 (-p: 부모 디렉터리도 생성)
cd ${PROJECT_BASE}                    # 변수로 디렉터리 이동
```

### 5. 파일 조작
```bash
# 복사
cp -Rf /source/file /dest/file        # -R: 재귀적, -f: 강제
sudo cp -Rf config /home/topzone/.aws/

# 삭제
rm -Rf .terraform                     # -R: 재귀적, -f: 강제 (확인 없음)
rm -Rf kubeconfig_*                   # 와일드카드 사용

# 권한 변경
chmod -Rf 600 ${eks_project}*         # 파일 권한 설정
chmod +x /usr/local/bin/argocd        # 실행 권한 부여
sudo chown -Rf topzone:topzone /home/topzone/.aws  # 소유자 변경
```

### 6. 출력 및 디버깅
```bash
echo "======= DOCKER_NAME: ${DOCKER_NAME}"
echo "#######################################################"

# 표준 출력 리다이렉션
echo "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}" >> log

# 디버깅 모드
set -x                                # 명령어 실행 전 출력
set +x                                # 디버깅 모드 해제
#set -x                               # 주석으로 비활성화
```

### 7. 배열 및 반복문
```bash
# 배열 선언
PROJECTS=(devops devops-dev default argocd consul monitoring vault)

# for 루프 (배열)
for item in "${PROJECTS[@]}"; do
  echo "Processing: ${item}"
  kubectl create ns ${item}
done

# for 루프 (명령 결과)
for item in $(eksctl get nodegroup --cluster=${eks_project} | grep ${eks_project} | awk '{print $2}'); do
  eksctl delete nodegroup --cluster=${eks_project} --name=${item}
done
```

### 8. 별칭 (Alias)
```bash
shopt -s expand_aliases               # 별칭 확장 활성화
alias k='kubectl --kubeconfig ~/.kube/config'
alias trace_on='set -x'
alias trace_off='{ set +x; } 2>/dev/null'

# 사용
k get pods -n default
trace_on
```

### 9. 소스 및 스크립트 실행
```bash
source /root/.bashrc                  # bashrc 로드
bash /topzone/scripts/eks_remove_all.sh
exit 0                                # 스크립트 정상 종료
exit 1                                # 오류로 종료
```

---

## AWS CLI 명령어

### 1. 계정 및 인증
```bash
# 계정 정보 조회
aws sts get-caller-identity
aws_account_id=$(aws sts get-caller-identity --query Account --output text)

# ECR 로그인
aws ecr get-login-password --region ${aws_region} \
  | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com

# 프로필 설정
export AWS_PROFILE=default
export AWS_DEFAULT_REGION="${aws_region}"
```

### 2. EKS (Elastic Kubernetes Service)
```bash
# EKS 클러스터 kubeconfig 업데이트
aws eks update-kubeconfig --region ap-northeast-2 --name ${eks_project}

# 노드 그룹 조회 (eksctl 사용)
eksctl get nodegroup --cluster=${eks_project}

# 노드 그룹 삭제
eksctl delete nodegroup --cluster=${eks_project} --name=${item} --disable-eviction
```

### 3. Auto Scaling
```bash
# Auto Scaling 그룹 조회
aws autoscaling describe-auto-scaling-groups --max-items 75 \
  | grep 'AutoScalingGroupName' | grep ${eks_project}

# Auto Scaling 그룹 삭제
aws autoscaling delete-auto-scaling-group \
  --auto-scaling-group-name ${item} --force-delete

# Launch Configuration 조회 및 삭제
aws autoscaling describe-launch-configurations --max-items 75
aws autoscaling delete-launch-configuration --launch-configuration-name ${item}
```

### 4. EC2
```bash
# VPC 조회
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=${eks_project}-vpc" \
  --out=text | awk '{print $8}' | head -n 1)

# Elastic IP 조회 및 해제
aws ec2 describe-addresses \
  --filters "Name=tag:Name,Values=${eks_project}*" \
  | grep '"PublicIp"'

aws ec2 release-address --public-ip ${item}
```

### 5. ELB (Elastic Load Balancer)
```bash
# ALB/NLB 조회 (ELBv2)
aws elbv2 describe-load-balancers --output text | grep ${VPC_ID}

# Load Balancer 삭제
aws elbv2 delete-load-balancer --load-balancer-arn ${elb_arn}

# Classic ELB 조회 및 삭제
aws elb describe-load-balancers --output text | grep ${VPC_ID}
aws elb describe-tags --load-balancer-name ${item} --output=text
aws elb delete-load-balancer --load-balancer-name ${item}
```

### 6. IAM (Identity and Access Management)
```bash
# Role 조회
aws iam list-roles --out=text | grep ${eks_project}

# Policy 조회 및 분리
aws iam list-attached-role-policies --role-name ${role} --out=text
aws iam detach-role-policy --role-name ${role} --policy-arn ${policy}
aws iam list-role-policies --role-name ${role} --out=text

# Policy 삭제
aws iam delete-policy --policy-arn arn:aws:iam::${aws_account_id}:policy/PolicyName
```

### 7. KMS (Key Management Service)
```bash
# KMS 키 별칭 조회
vault_kms_key=$(aws kms list-aliases \
  | grep -w "${eks_project}-vault-kms-unseal_01" -A 1 \
  | tail -n 1 | awk -F\" '{print $4}')
```

### 8. Route53 (DNS)
```bash
# Hosted Zone ID 조회
HOSTZONE_ID=$(aws route53 list-hosted-zones \
  --query "HostedZones[?Name == '${eks_domain}.']" \
  | grep '"Id"' | awk '{print $2}' \
  | sed 's/\"//g;s/,//' | cut -d'/' -f3)

# 레코드 조회
aws route53 list-resource-record-sets --hosted-zone-id ${HOSTZONE_ID} \
  --query "ResourceRecordSets[?Name == '\\052.${NS}.${eks_project}.${eks_domain}.']"

# 레코드 변경 (CNAME 삭제)
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTZONE_ID} \
  --change-batch '{ "Comment": "'"${eks_project}"'", "Changes": [{"Action": "DELETE", ...}]}'
```

### 9. CloudWatch Logs
```bash
# Log Group 삭제
aws logs delete-log-group --log-group-name /aws/eks/${eks_project}/cluster
```

---

## Kubernetes 명령어

### 1. 네임스페이스 관리
```bash
kubectl create namespace argocd
kubectl delete namespace jenkins
kubectl get namespace
kubectl -n kube-system get configmap
```

### 2. 리소스 조회
```bash
# Pod 조회
kubectl get pods -n default
kubectl get pods --all-namespaces

# Service 조회
kubectl get service -n argocd
kubectl get svc | grep ingress-nginx-controller

# ConfigMap 조회
kubectl -n kube-system get configmap aws-auth -o yaml

# Node 조회
kubectl get node
```

### 3. 리소스 생성/적용
```bash
# YAML 파일 적용
kubectl apply -f jenkins.yaml
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n ${item} apply -f sa.yaml

# 삭제
kubectl delete -n argocd -f https://raw.githubusercontent.com/.../install.yaml
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
```

### 4. 리소스 수정 (Patch)
```bash
# Service 타입 변경
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# JSON Patch
kubectl patch svc jenkins --type='json' \
  -p '[{"op":"replace","path":"/spec/type","value":"NodePort"}]' -n jenkins
```

### 5. Secret 관리
```bash
# Secret 생성
kubectl -n vault create secret generic eks-creds \
  --from-literal=AWS_ACCESS_KEY_ID="${aws_access_key_id}" \
  --from-literal=AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}"

kubectl create secret generic basic-auth-argocd --from-file=auth -n argocd

# Secret 조회
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
kubectl get secret basic-auth-argocd -o yaml -n argocd

# Secret 삭제
kubectl -n vault delete secret generic eks-creds
```

### 6. ServiceAccount 생성
```bash
cat <<EOF > sa.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${item}-svcaccount
  namespace: ${item}
EOF
kubectl -n ${item} apply -f sa.yaml
```

### 7. 별칭 사용
```bash
# 별칭 설정
alias k='kubectl --kubeconfig ~/.kube/config'

# 사용
k get pods -n default
k apply -f deployment.yaml
k -n monitoring get svc
```

---

## Docker 명령어

### 1. 이미지 관리
```bash
# 이미지 빌드
docker build -t ${TAG} .

# 로그인
docker login -u="${dockerhub_id}" -p="${dockerhub_password}"
docker login --username AWS --password-stdin ${ECR_URL}
```

### 2. 컨테이너 관리
```bash
# 실행 중인 컨테이너 조회
docker ps
DOCKER_NAME=`docker ps | grep docker-${tz_project} | awk '{print $1}'`

# 컨테이너 내부 명령 실행
docker exec -it ${DOCKER_NAME} bash
docker exec -it ${DOCKER_NAME} bash /topzone/scripts/eks_remove_all.sh

# 컨테이너 중지
docker container stop $(docker container ls -a -q)
```

### 3. Docker Compose
```bash
# 빌드 및 실행
docker-compose -f docker-compose.yml_bak build
docker-compose -f docker-compose.yml_bak up -d

# 중지 및 삭제
docker-compose -f docker-compose.yml_bak down
```

### 4. 시스템 정리
```bash
# 모든 미사용 리소스 정리
docker system prune -a -f --volumes
# -a: 모든 미사용 이미지
# -f: 확인 없이 강제 실행
# --volumes: 볼륨도 함께 삭제
```

---

## Terraform 명령어

### 1. 초기화
```bash
terraform init                        # Terraform 초기화 (provider 다운로드)
```

### 2. 계획 및 적용
```bash
# 변경사항 미리보기
terraform plan -var-file=".auto.tfvars"

# 적용
terraform apply -var-file=".auto.tfvars" -auto-approve

# 종료 상태 확인
if [[ $? != 0 ]]; then
  exit 1
fi
```

### 3. 출력값 추출
```bash
# kubeconfig 출력
terraform output kubeconfig | head -n -1 | tail -n +2 > kubeconfig_${eks_project}
```

### 4. 삭제
```bash
terraform destroy -auto-approve
```

### 5. 파일 정리
```bash
rm -Rf .terraform                     # Provider 플러그인
rm -Rf terraform.tfstate              # 상태 파일
rm -Rf terraform.tfstate.backup       # 백업 파일
rm -Rf .terraform.lock.hcl            # 의존성 잠금 파일
```

---

## Helm 명령어

### 1. Repository 관리
```bash
# Repository 추가
helm repo add jenkins https://charts.jenkins.io
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo add stable https://charts.helm.sh/stable

# Repository 업데이트
helm repo update

# Chart 검색
helm search repo jenkins
helm search repo hashicorp/vault
```

### 2. Chart 정보 조회
```bash
# Chart 정보
helm show chart prometheus-community/kube-prometheus-stack

# Values 파일 생성
helm show values hashicorp/vault > values2.yaml
helm show values jenkins/jenkins > values.yaml
```

### 3. 설치 및 업그레이드
```bash
# 신규 설치
helm install jenkins jenkins/jenkins -f values.yaml -n jenkins --version ${APP_VERSION}

# 업그레이드 (없으면 설치)
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -f values.yaml --version ${APP_VERSION} -n ${NS}

# 재사용 값 및 디버그
helm upgrade --reuse-values --debug --install jenkins jenkins/jenkins \
  -f values.yaml_bak -n jenkins --version ${APP_VERSION}
```

### 4. 삭제
```bash
helm uninstall jenkins -n jenkins
helm delete vault -n vault
```

### 5. 목록 조회
```bash
helm list --all-namespaces -a
```

---

## 텍스트 처리 명령어

### 1. grep (패턴 검색)
```bash
# 기본 사용
grep "docker-${tz_project}"
grep -w "argocd-server"               # -w: 단어 단위 매칭

# 파일에서 검색
grep "${2}" "/home/topzone/.aws/${1}"

# 여러 라인 후 출력
grep -A 1 "${eks_project}-vault-kms-unseal_01"  # -A 1: 매칭 후 1줄 더
grep -A 10 "$key"                     # 매칭 후 10줄

# 반전 매칭
grep -v "pattern"                     # 패턴이 없는 라인만
```

### 2. awk (텍스트 처리)
```bash
# 특정 컬럼 출력
awk '{print $1}'                      # 첫 번째 컬럼
awk '{print $4}'                      # 네 번째 컬럼
awk '{print $NF}'                     # 마지막 컬럼

# 구분자 지정
awk -F\" '{print $4}'                 # 큰따옴표로 구분
awk -F':' '{print $1}'                # 콜론으로 구분

# 조건부 처리
awk 'NR > 1 {print $0}'              # 2번째 라인부터
awk '/pattern/ {print $2}'           # 패턴 매칭 시만

# 파이프라인에서 사용
docker ps | grep docker-${tz_project} | awk '{print $1}'
aws ec2 describe-vpcs | awk '{print $8}' | head -n 1
```

### 3. sed (스트림 편집)
```bash
# 문자열 치환
sed 's/ //g'                          # 공백 제거 (g: 전역)
sed 's/"//g'                          # 큰따옴표 제거
sed 's/\"//g;s/,//'                   # 여러 치환 (세미콜론으로 구분)
sed -E 's/.*"([^"]+)".*/\1/'          # 정규표현식 (-E)

# 인플레이스 편집 (파일 수정)
sed -i "s/eks_project/${eks_project}/g" values.yaml_bak
sed -i "s|jenkins_aws_access_key|${aws_access_key_id}|g" values.yaml_bak
sed -ie "s|\${eks_project}|${eks_project}|g" docker-compose.yml_bak

# 특정 라인 추출
sed 's/eks-main/project/'
```

### 4. cut (필드 잘라내기)
```bash
# 구분자로 잘라내기
cut -d '=' -f2                        # '='로 구분, 2번째 필드
cut -d '/' -f3                        # '/'로 구분, 3번째 필드
cut -d '=' -f2 | sed 's/ //g'        # 파이프라인 조합
```

### 5. head / tail
```bash
head -n 1                             # 첫 번째 라인만
head -n -1                            # 마지막 라인 제외
tail -n 1                             # 마지막 라인만
tail -n +2                            # 두 번째 라인부터
terraform output kubeconfig | head -n -1 | tail -n +2  # 첫/끝 라인 제외
```

### 6. tr (문자 변환)
```bash
# 문자 치환
echo "$3" | tr ',' '\n'               # 콤마를 줄바꿈으로
```

### 7. sort / uniq
```bash
sort                                  # 정렬
uniq                                  # 중복 제거
sort | uniq                           # 정렬 후 중복 제거
```

### 8. wc (단어/라인 수)
```bash
wc -l                                 # 라인 수
wc -w                                 # 단어 수
```

---

## 기타 도구

### 1. curl (HTTP 클라이언트)
```bash
# 파일 다운로드
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
curl -sSL -o /usr/local/bin/argocd https://github.com/.../argocd-linux-amd64

# API 호출
curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" \
  | grep '"tag_name"'

# GPG 키 추가
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
```

### 2. wget (파일 다운로드)
```bash
wget "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz"
wget https://releases.hashicorp.com/vault/1.3.1/vault_1.3.1_linux_amd64.zip
```

### 3. tar (압축 관리)
```bash
tar xvfz "eksctl_$(uname -s)_amd64.tar.gz"
# x: 압축 해제
# v: 상세 출력
# f: 파일 지정
# z: gzip
```

### 4. unzip (ZIP 압축 해제)
```bash
unzip vault_1.3.1_linux_amd64.zip
```

### 5. ssh-keygen (SSH 키 생성)
```bash
ssh-keygen -t rsa -C ${eks_project} -P "" -f ${eks_project} -q
# -t: 키 타입 (rsa)
# -C: 코멘트
# -P: 패스프레이즈
# -f: 파일명
# -q: 조용한 모드
```

### 6. base64 (인코딩/디코딩)
```bash
# 디코딩
kubectl get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# 인코딩
echo -n "password" | base64
```

### 7. sleep (대기)
```bash
sleep 10                              # 10초 대기
sleep 60                              # 1분 대기
sleep 150                             # 2.5분 대기
```

### 8. git
```bash
git config --global --add safe.directory '*'
```

### 9. jq (JSON 처리)
```bash
# JSON 파싱 (설치 필요)
aws sts get-caller-identity | jq -r '.Account'
```

### 10. htpasswd (기본 인증)
```bash
echo ${basic_password} | htpasswd -i -n admin > auth
```

### 11. argocd CLI
```bash
# 로그인
argocd login `k get service -n argocd | grep -w "argocd-server" | awk '{print $4}'` \
  --username admin --password ${TMP_PASSWORD} --insecure

# 비밀번호 변경
argocd account update-password --account admin \
  --current-password ${TMP_PASSWORD} --new-password ${admin_password}
```

### 12. vault CLI
```bash
# Vault 로그인
vault login ${vault_token}

# Secret 읽기
vault kv get -field=${item} ${vault_secret_key}

# 자동완성 설치
vault -autocomplete-install
complete -C /usr/local/bin/vault vault
```

### 13. apt (패키지 관리 - Ubuntu/Debian)
```bash
# Repository 추가
sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

# 업데이트
sudo apt-get update -y

# 설치
sudo apt install terraform=0.13.6
sudo apt install awscli jq unzip -y
sudo apt-get install -y apt-transport-https gnupg2 curl

# 제거
sudo apt purge terraform -y
```

---

## 공통 패턴

### 1. prop 함수 (설정 값 추출)
```bash
# 다양한 버전의 prop 함수가 프로젝트 전반에 사용됨

# 버전 1: 간단한 버전
function prop {
  grep "${2}" "/home/topzone/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}

# 버전 2: 고급 버전 (여러 줄 검색, 공백 처리)
function prop {
  key="${2}="
  file="/root/.aws/${1}"
  rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g')
  [[ -z "$rslt" ]] && key="${2} = " && rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g')
  echo "$rslt"
}

# 사용 예시
eks_project=$(prop 'project' 'project')
aws_region=$(prop 'config' 'region')
admin_password=$(prop 'project' 'admin_password')
```

### 2. 스크립트 시작 부분 공통 패턴
```bash
#!/usr/bin/env bash                   # 또는 #!/bin/bash

source /root/.bashrc                  # bashrc 로드 (환경 변수)
function prop { ... }                 # prop 함수 정의

#set -x                               # 디버깅 (주로 주석 처리)
shopt -s expand_aliases               # 별칭 확장 활성화
alias k='kubectl --kubeconfig ~/.kube/config'

# 변수 로드
eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
AWS_REGION=$(prop 'config' 'region')
```

### 3. 파일 템플릿 치환 패턴
```bash
# 원본 파일 백업 후 변수 치환
cp -Rf values.yaml values.yaml_bak
sed -i "s/eks_project/${eks_project}/g" values.yaml_bak
sed -i "s/eks_domain/${eks_domain}/g" values.yaml_bak
sed -i "s|jenkins_aws_access_key|${aws_access_key_id}|g" values.yaml_bak

# 사용
helm install ... -f values.yaml_bak
kubectl apply -f jenkins-ingress.yaml_bak
```

### 4. Docker 컨테이너 이름 추출 패턴
```bash
# 프로젝트 전반에 걸쳐 반복적으로 사용
DOCKER_NAME=`docker ps | grep docker-${tz_project} | awk '{print $1}'`
docker exec -it `docker ps | grep docker-${tz_project} | awk '{print $1}'` bash
```

### 5. 에러 처리 패턴
```bash
# 명령 실행 후 종료 상태 확인
terraform apply -var-file=".auto.tfvars" -auto-approve
if [[ $? != 0 ]]; then
  echo "failed to apply terraform!"
  exit 1
fi

# 변수 값 확인
if [[ "${AWS_DEFAULT_REGION}" == "" || "${eks_project}" == "" ]]; then
  echo "AWS_DEFAULT_REGION or eks_project is null"
  exit 1
fi
```

### 6. AWS 리소스 일괄 삭제 패턴
```bash
# for 루프로 리소스 목록 조회 후 삭제
for item in $(aws autoscaling describe-auto-scaling-groups --max-items 75 \
  | grep 'AutoScalingGroupName' | grep ${eks_project} \
  | awk '{print $2}' | sed 's/"//g'); do
  aws autoscaling delete-auto-scaling-group --auto-scaling-group-name ${item::-1} --force-delete
done

# ${item::-1}: 마지막 문자 제거 (쉘 문자열 슬라이싱)
```

### 7. Heredoc 패턴 (다중 라인 입력)
```bash
# YAML 파일 생성
cat <<EOF > sa.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${item}-svcaccount
  namespace: ${item}
EOF

# JSON 데이터
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTZONE_ID} \
  --change-batch '{ "Comment": "'"${eks_project}"'", "Changes": [...]}'
```

### 8. 대기 및 재시도 패턴
```bash
# Service 생성 후 대기
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
sleep 150

# ELB 주소 추출 (반복 확인)
DEVOPS_ELB=$(kubectl get svc | grep ingress-nginx-controller | grep LoadBalancer | awk '{print $4}')
if [[ "${DEVOPS_ELB}" == "" ]]; then
  echo "No elb! check nginx-ingress-controller"
  exit 1
fi
sleep 20
```

### 9. 명령 치환 패턴
```bash
# 백틱 사용 (구식)
DOCKER_NAME=`docker ps | grep docker-${tz_project} | awk '{print $1}'`
pushd `pwd`

# $() 사용 (권장)
VERSION=$(curl --silent "https://api.github.com/repos/.../releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
aws_account_id=$(aws sts get-caller-identity --query Account --output text)
```

### 10. 파이프라인 체인 패턴
```bash
# 긴 파이프라인 (여러 명령어 조합)
aws ec2 describe-addresses \
  --filters "Name=tag:Name,Values=${eks_project}*" \
  | grep '"PublicIp"' \
  | awk '{print $2}' \
  | sed 's/"//g'

# grep → awk → sed 조합
docker ps | grep docker-${tz_project} | awk '{print $1}'
aws iam list-roles --out=text | grep ${eks_project} | awk '{print $7}'
```

---

## 명령어 빈도 분석

### 가장 많이 사용되는 명령어 Top 20
1. `kubectl` (k8s 리소스 관리)
2. `aws` (AWS 리소스 관리)
3. `echo` (출력 및 로깅)
4. `grep` (텍스트 검색 및 필터링)
5. `awk` (컬럼 추출 및 텍스트 처리)
6. `sed` (문자열 치환)
7. `rm` (파일/디렉터리 삭제)
8. `cp` (파일 복사)
9. `docker` (컨테이너 관리)
10. `helm` (K8s 패키지 관리)
11. `terraform` (인프라 프로비저닝)
12. `export` (환경 변수 설정)
13. `if [[ ]]` (조건문)
14. `for` (반복문)
15. `cd` (디렉터리 이동)
16. `curl` (HTTP 요청)
17. `bash` (스크립트 실행)
18. `sleep` (대기)
19. `cut` (필드 추출)
20. `tail` / `head` (라인 추출)

---

## 스크립트 실행 흐름

### 1. 초기 설치 플로우
```
bootstrap.sh (인자 없음)
  ↓
tz-local/docker/install.sh
  ├─ Docker 이미지 빌드
  ├─ Docker Compose up
  └─ 컨테이너 내부에서 init2.sh 실행
      ↓
tz-local/docker/init2.sh
  ├─ AWS 설정 파일 복사
  ├─ Kubeconfig 설정
  ├─ terraform-aws-iam 적용
  └─ terraform-aws-eks 적용
      ↓
scripts/eks_addtion.sh
  ├─ makeuser/eks-users.sh (사용자 생성)
  ├─ docker-repo/install.sh
  ├─ persistent-storage/install.sh
  ├─ ingress_nginx/install.sh
  ├─ autoscaler/install.sh
  ├─ monitoring/install.sh
  ├─ consul/install.sh
  ├─ vault/helm/install.sh
  ├─ argocd/helm/install.sh
  └─ jenkins/helm/install.sh
```

### 2. 리소스 삭제 플로우
```
bootstrap.sh remove
  ↓
scripts/eks_remove_all.sh
  ├─ EKS 노드 그룹 삭제
  ├─ Auto Scaling 그룹 삭제
  ├─ Launch Configuration 삭제
  ├─ Elastic IP 해제
  ├─ Load Balancer 삭제
  ├─ IAM Role/Policy 삭제
  └─ CloudWatch Logs 삭제
      ↓
scripts/eks_remove_all.sh cleanTfFiles
  └─ Terraform 파일 정리
```

---

## 주요 학습 포인트

### 1. 쉘 스크립팅 기본
- 변수와 환경 변수 사용
- 함수 정의 및 재사용
- 조건문과 반복문
- 에러 처리 ($? 활용)
- 배열과 별칭

### 2. 텍스트 처리 마스터
- grep, awk, sed의 조합
- 파이프라인 구성
- 정규표현식 활용

### 3. AWS CLI 숙달
- 리소스 조회 및 필터링
- JSON/텍스트 출력 처리
- 대량 리소스 관리

### 4. Kubernetes 운영
- kubectl 명령어 체계
- YAML 적용 및 관리
- Secret, ConfigMap 다루기

### 5. Infrastructure as Code
- Terraform 워크플로우
- Helm Chart 커스터마이징
- 템플릿 변수 치환

### 6. DevOps 자동화
- Docker 기반 개발 환경
- CI/CD 파이프라인
- 멱등성 있는 스크립트 작성

---

## 참고 자료

### 공식 문서
- [Bash Manual](https://www.gnu.org/software/bash/manual/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Terraform Documentation](https://www.terraform.io/docs/)

### 유용한 명령어 치트시트
- [Kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [AWS CLI Cheat Sheet](https://github.com/eon01/AWS-CheatSheet)
- [Docker Cheat Sheet](https://docs.docker.com/get-started/docker_cheatsheet.pdf)

---

**작성일**: 2025-11-14  
**프로젝트**: KUBE (tz-eks-main, tz-devops-admin)  
**분석 대상**: 총 51개 쉘스크립트 파일

