# Helm 사용법 종합 가이드 (프로젝트 기반)

## 📋 목차
1. [Helm 개요](#helm-개요)
2. [Helm 설치](#helm-설치)
3. [Repository 관리](#repository-관리)
4. [Chart 검색 및 정보 조회](#chart-검색-및-정보-조회)
5. [Chart 설치 및 업그레이드](#chart-설치-및-업그레이드)
6. [Release 관리](#release-관리)
7. [Values 파일 커스터마이징](#values-파일-커스터마이징)
8. [프로젝트별 Helm 사용 예시](#프로젝트별-helm-사용-예시)
9. [고급 패턴](#고급-패턴)
10. [트러블슈팅](#트러블슈팅)

---

## Helm 개요

### Helm이란?
- Kubernetes의 **패키지 매니저**
- 복잡한 Kubernetes 애플리케이션을 쉽게 배포하고 관리
- **Chart**: Helm 패키지 (앱 설치에 필요한 모든 리소스 정의)
- **Release**: Chart의 실행 인스턴스
- **Repository**: Chart를 저장하고 공유하는 저장소

### Helm의 장점
✅ 복잡한 애플리케이션을 한 번에 배포  
✅ 버전 관리 및 롤백 기능  
✅ Values 파일로 환경별 설정 관리  
✅ 템플릿 엔진으로 재사용 가능한 매니페스트 생성  
✅ 의존성 관리 자동화  

---

## Helm 설치

### Helm 3 설치 (프로젝트 방식)

```bash
# Helm 설치 스크립트 다운로드 및 실행
sudo curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
sudo bash get_helm.sh
sudo rm -Rf get_helm.sh

# Helm 버전 확인
helm version
```

### 기본 Repository 추가
```bash
# Stable Charts (레거시)
helm repo add stable https://charts.helm.sh/stable
helm repo update
```

**파일 위치**: `tz-eks-main/terraform-aws-eks/scripts/eks-main-bastion-init.sh`

---

## Repository 관리

### 1. Repository 추가

프로젝트에서 사용하는 주요 Repository:

```bash
# Prometheus & Grafana (모니터링)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts

# Ingress NGINX
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Jenkins
helm repo add jenkins https://charts.jenkins.io

# HashiCorp Vault
helm repo add hashicorp https://helm.releases.hashicorp.com

# ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm

# AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts

# Harbor (Container Registry)
helm repo add harbor https://helm.goharbor.io

# Nexus
helm repo add oteemocharts https://oteemo.github.io/charts

# Cert-Manager
helm repo add jetstack https://charts.jetstack.io

# Kube-State-Metrics (선택적)
helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics
```

### 2. Repository 업데이트
```bash
# 모든 Repository의 최신 Chart 정보 동기화
helm repo update
```

### 3. Repository 조회
```bash
# 등록된 Repository 목록
helm repo list

# Repository 삭제
helm repo remove <repo-name>
```

---

## Chart 검색 및 정보 조회

### 1. Chart 검색
```bash
# Repository에서 Chart 검색
helm search repo jenkins
helm search repo hashicorp/vault
helm search repo prometheus-community
helm search repo nginx-ingress
helm search repo oteemocharts/sonatype-nexus

# 사용 가능한 모든 버전 보기
helm search repo jenkins --versions
```

### 2. Chart 정보 조회
```bash
# Chart 메타데이터 보기
helm show chart prometheus-community/kube-prometheus-stack

# Chart의 기본 Values 보기
helm show values jenkins/jenkins
helm show values hashicorp/vault

# Chart의 모든 정보 보기
helm show all jenkins/jenkins

# Values를 파일로 저장
helm show values jenkins/jenkins > values.yaml
helm show values hashicorp/vault > values2.yaml
```

**실제 사용 예시:**
```bash
# Jenkins Values 파일 생성
cd /topzone/tz-local/resource/jenkins/helm
helm show values jenkins/jenkins > values.yaml

# 이후 values.yaml을 편집하여 커스터마이징
```

---

## Chart 설치 및 업그레이드

### 1. 기본 설치 명령어

```bash
helm install [RELEASE_NAME] [CHART] [FLAGS]
```

**예시:**
```bash
# 기본 설치
helm install my-jenkins jenkins/jenkins

# 네임스페이스 지정
helm install my-jenkins jenkins/jenkins -n jenkins

# Values 파일 사용
helm install my-jenkins jenkins/jenkins -f values.yaml -n jenkins

# 특정 버전 설치
helm install my-jenkins jenkins/jenkins --version 4.3.27 -n jenkins
```

### 2. Upgrade (업그레이드)

```bash
helm upgrade [RELEASE_NAME] [CHART] [FLAGS]
```

**기본 옵션:**
- `--install`: Release가 없으면 설치, 있으면 업그레이드
- `--reuse-values`: 기존 Values 유지 (새로운 Values와 병합)
- `--debug`: 디버그 출력
- `--version`: Chart 버전 지정
- `-f, --values`: Values 파일 지정
- `-n, --namespace`: 네임스페이스 지정

### 3. 프로젝트 실전 패턴

#### 패턴 1: 기본 설치/업그레이드
```bash
helm upgrade --debug --install [RELEASE] [CHART] \
  -f values.yaml \
  --version [VERSION] \
  -n [NAMESPACE]
```

#### 패턴 2: 기존 값 재사용
```bash
helm upgrade --reuse-values --debug --install [RELEASE] [CHART] \
  -f values.yaml_bak \
  -n [NAMESPACE] \
  --version [VERSION]
```

#### 패턴 3: Inline 설정
```bash
helm upgrade --debug --install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --version 44.3.0 \
  --set alertmanager.persistentVolume.storageClass="gp3" \
  --set server.persistentVolume.storageClass="gp3"
```

---

## Release 관리

### 1. Release 목록 조회
```bash
# 특정 네임스페이스의 Release
helm list -n jenkins

# 모든 네임스페이스의 Release
helm list --all-namespaces
helm list --all-namespaces -a

# 삭제된 Release 포함
helm list -a -n jenkins
```

### 2. Release 삭제 (Uninstall)
```bash
# Release 삭제
helm uninstall jenkins -n jenkins
helm delete jenkins -n jenkins  # 동일

# 삭제 전 확인
helm list -n jenkins
```

**프로젝트 예시:**
```bash
# Vault 삭제
helm uninstall vault -n vault

# Ingress NGINX 삭제
helm uninstall ingress-nginx -n default

# Jenkins 삭제
helm delete jenkins -n jenkins
```

### 3. Release 상태 확인
```bash
# Release 상태
helm status jenkins -n jenkins

# Release 이력
helm history jenkins -n jenkins
```

### 4. Release 롤백
```bash
# 이전 버전으로 롤백
helm rollback jenkins -n jenkins

# 특정 리비전으로 롤백
helm rollback jenkins 2 -n jenkins
```

---

## Values 파일 커스터마이징

### 프로젝트의 Values 파일 처리 패턴

대부분의 스크립트에서 다음 패턴을 사용:

```bash
# 1. 원본 Values 파일 복사
cp -Rf values.yaml values.yaml_bak

# 2. 변수 치환 (sed 사용)
sed -i "s/eks_project/${eks_project}/g" values.yaml_bak
sed -i "s/eks_domain/${eks_domain}/g" values.yaml_bak
sed -i "s/admin_password/${admin_password}/g" values.yaml_bak
sed -i "s|jenkins_aws_access_key|${aws_access_key_id}|g" values.yaml_bak

# 3. 치환된 파일로 설치
helm upgrade --install jenkins jenkins/jenkins -f values.yaml_bak -n jenkins
```

### Values 파일 우선순위

```bash
# 여러 Values 파일 사용 (뒤에 오는 것이 우선)
helm install myapp myrepo/myapp \
  -f values.yaml \
  -f values-dev.yaml

# Command line 설정이 최우선
helm install myapp myrepo/myapp \
  -f values.yaml \
  --set image.tag=v2.0.0
```

### Values 오버라이드 예시

```bash
# 단일 값 설정
--set key=value

# 중첩된 값 설정
--set server.service.type=LoadBalancer

# 배열 설정
--set servers[0].port=8080,servers[0].host=example

# 여러 값 설정
helm upgrade --debug --install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --version 44.3.0 \
  --set alertmanager.persistentVolume.storageClass="gp3" \
  --set server.persistentVolume.storageClass="gp3" \
  --set alertmanager.baseURL=https://alertmanager.default.${eks_project}.${eks_domain}
```

---

## 프로젝트별 Helm 사용 예시

### 1. Jenkins 설치

**파일**: `tz-eks-main/tz-local/resource/jenkins/helm/install.sh`

```bash
#!/usr/bin/env bash

# 변수 로드
eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
AWS_REGION=$(prop 'config' 'region')
aws_access_key_id=$(prop 'credentials' 'aws_access_key_id')
aws_secret_access_key=$(prop 'credentials' 'aws_secret_access_key')

# Repository 추가
helm repo add jenkins https://charts.jenkins.io
helm search repo jenkins

# Release 목록 확인
helm list --all-namespaces -a

# 네임스페이스 생성
kubectl create namespace jenkins
kubectl apply -f jenkins.yaml

# Values 파일 커스터마이징
cp -Rf values.yaml values.yaml_bak
sed -i "s|jenkins_aws_access_key|${aws_access_key_id}|g" values.yaml_bak
sed -i "s|jenkins_aws_secret_key|${aws_secret_access_key}|g" values.yaml_bak
sed -i "s|aws_region|${AWS_REGION}|g" values.yaml_bak
sed -i "s|eks_project|${eks_project}|g" values.yaml_bak
sed -i "s|tz-registrykey|registry-creds|g" values.yaml_bak

# Jenkins 설치
APP_VERSION=4.3.27
helm upgrade --reuse-values --debug --install jenkins jenkins/jenkins \
  -f values.yaml_bak \
  -n jenkins \
  --version ${APP_VERSION}

# Ingress 설정
cp -Rf jenkins-ingress.yaml jenkins-ingress.yaml_bak
sed -i "s/eks_project/${eks_project}/g" jenkins-ingress.yaml_bak
sed -i "s/eks_domain/${eks_domain}/g" jenkins-ingress.yaml_bak
kubectl apply -f jenkins-ingress.yaml_bak -n jenkins
```

**핵심 포인트:**
- `--reuse-values`: 기존 설정 유지
- `--debug`: 상세한 출력
- `--install`: 없으면 신규 설치
- `-f values.yaml_bak`: 커스터마이즈된 Values 사용
- `--version`: 특정 버전 고정

---

### 2. HashiCorp Vault 설치

**파일**: `tz-eks-main/tz-local/resource/vault/helm/install.sh`

```bash
#!/usr/bin/env bash

# 변수 로드
eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
AWS_REGION=$(prop 'config' 'region')
vault_kms_key=$(aws kms list-aliases | grep -w "${eks_project}-vault-kms-unseal_01" -A 1 | tail -n 1 | awk -F\" '{print $4}')

# KMS 키 확인
if [[ "${vault_kms_key}" == "" ]]; then
  echo "kms is empty!!!!"
  exit 1
fi

# Repository 추가
helm repo add hashicorp https://helm.releases.hashicorp.com
helm search repo hashicorp/vault

# 기존 설치 제거
helm uninstall vault -n vault

# 네임스페이스 및 Secret 생성
kubectl create namespace vault
kubectl -n vault delete secret generic eks-creds
kubectl -n vault create secret generic eks-creds \
    --from-literal=AWS_ACCESS_KEY_ID="${aws_access_key_id}" \
    --from-literal=AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}"

# TLS 인증서 생성
bash /topzone/tz-local/resource/vault/vault-injection/cert.sh vault

# Values 파일 커스터마이징
cp -Rf values_cert.yaml values_cert.yaml_bak
sed -i "s/eks_project/${eks_project}/g" values_cert.yaml_bak
sed -i "s/AWS_REGION/${AWS_REGION}/g" values_cert.yaml_bak
sed -i "s/VAULT_KMS_KEY/${vault_kms_key}/g" values_cert.yaml_bak

# Vault 설치
helm upgrade --debug --install vault hashicorp/vault \
  -n vault \
  -f values_cert.yaml_bak \
  --version 0.25.0

# 대기 및 확인
sleep 30
kubectl get all -n vault

# Ingress 설정
cp -Rf ingress-vault.yaml ingress-vault.yaml_bak
sed -i "s/eks_project/${eks_project}/g" ingress-vault.yaml_bak
sed -i "s/eks_domain/${eks_domain}/g" ingress-vault.yaml_bak
sed -i "s|NS|${NS}|g" ingress-vault.yaml_bak
kubectl apply -f ingress-vault.yaml_bak -n vault

# Vault 초기화
sleep 30
export VAULT_ADDR="http://vault.default.${eks_project}.${eks_domain}"
kubectl -n vault exec -ti vault-0 -- vault operator init \
  -key-shares=3 -key-threshold=2 | sed 's/\x1b\[[0-9;]*m//g' > /topzone/resources/unseal.txt
```

**핵심 포인트:**
- `--version 0.25.0`: 특정 버전 고정 (안정성)
- AWS KMS를 통한 자동 Unseal 설정
- TLS 인증서 사전 생성
- Vault 초기화 자동화

---

### 3. Prometheus & Grafana 스택 설치

**파일**: `tz-eks-main/tz-local/resource/monitoring/install.sh`

```bash
#!/usr/bin/env bash

# 변수 로드
eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
admin_password=$(prop 'project' 'admin_password')
smtp_password=$(prop 'project' 'smtp_password')
STACK_VERSION=44.3.0
NS=monitoring

# 네임스페이스 생성
kubectl create ns ${NS}

# Values 파일 준비
cp -Rf values.yaml values.yaml_bak
sed -i "s/admin_password/${admin_password}/g" values.yaml_bak
sed -i "s/eks_project/${eks_project}/g" values.yaml_bak
sed -i "s/eks_domain/${eks_domain}/g" values.yaml_bak
sed -i "s/smtp_password/${smtp_password}/g" values.yaml_bak

# Repository 추가
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 초기 설치 (Storage Class 설정)
helm upgrade --debug --install prometheus prometheus-community/kube-prometheus-stack \
  -n ${NS} \
  --version ${STACK_VERSION} \
  --set alertmanager.persistentVolume.storageClass="gp3" \
  --set server.persistentVolume.storageClass="gp3"

# Values 파일 적용 (업그레이드)
helm upgrade --debug --install --reuse-values prometheus prometheus-community/kube-prometheus-stack \
  -n ${NS} \
  --version ${STACK_VERSION} \
  -f values.yaml_bak \
  --set alertmanager.baseURL=https://alertmanager.default.${eks_project}.${eks_domain}

# 추가 패치 (ImagePullSecrets)
kubectl patch deployment/prometheus-kube-state-metrics \
  -p '{"spec": {"template": {"spec": {"imagePullSecrets": [{"name": "registry-creds"}]}}}}' \
  -n ${NS}

# Blackbox Exporter 설치
helm uninstall tz-blackbox-exporter -n ${NS}
helm upgrade --debug --install -n ${NS} tz-blackbox-exporter \
  prometheus-community/prometheus-blackbox-exporter
```

**핵심 포인트:**
- **2단계 설치**: 먼저 Storage Class 설정, 그다음 Values 적용
- `--reuse-values`: 첫 번째 설치의 설정 유지
- `--set`: Command line에서 특정 값 오버라이드
- 복잡한 스택 (Prometheus + Grafana + AlertManager)

---

### 4. Ingress NGINX 설치

**파일**: `tz-eks-main/tz-local/resource/ingress_nginx/install.sh`

```bash
#!/usr/bin/env bash

# 인자 처리
NS=$1
if [[ "${NS}" == "" ]]; then
  NS=default
fi
eks_project=$2
eks_domain=$3

# 네임스페이스 생성
kubectl create ns ${NS}

# Repository 추가
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Ingress NGINX 설치
APP_VERSION=4.0.13
helm uninstall ingress-nginx -n ${NS}
helm upgrade --debug --install --reuse-values ingress-nginx ingress-nginx/ingress-nginx \
  -f values.yaml \
  --version ${APP_VERSION} \
  -n ${NS}

# Validation Webhook 제거 (필요시)
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission

# ELB 주소 확인
sleep 60
DEVOPS_ELB=$(kubectl get svc | grep ingress-nginx-controller | grep LoadBalancer | head -n 1 | awk '{print $4}')
if [[ "${DEVOPS_ELB}" == "" ]]; then
  echo "No elb! check nginx-ingress-controller with LoadBalancer type!"
  exit 1
fi

# Route53 레코드 업데이트
HOSTZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name == '${eks_domain}.']" | grep '"Id"' | awk '{print $2}' | sed 's/\"//g;s/,//' | cut -d'/' -f3)
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTZONE_ID} \
  --change-batch '{ "Comment": "'"${eks_project}"' utils", "Changes": [{"Action": "CREATE", "ResourceRecordSet": { "Name": "*.'"${NS}"'.'"${eks_project}"'.'"${eks_domain}"'", "Type": "CNAME", "TTL": 120, "ResourceRecords": [{"Value": "'"${DEVOPS_ELB}"'"}]}}]}'

# Cert-Manager 설치
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm uninstall cert-manager -n cert-manager
kubectl create namespace cert-manager
kubectl apply --validate=false -f https://github.com/cert-manager/cert-manager/releases/download/v1.10.0/cert-manager.crds.yaml
```

**핵심 포인트:**
- 인자로 네임스페이스 동적 처리
- ELB 주소 자동 추출 후 Route53 업데이트
- Cert-Manager CRD 사전 설치

---

### 5. ArgoCD 설치

**파일**: `tz-eks-main/tz-local/resource/argocd/helm/install.sh`

```bash
#!/usr/bin/env bash

# 변수 로드
eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
admin_password=$(prop 'project' 'admin_password')

# 네임스페이스 생성
kubectl create namespace argocd

# Repository 추가
helm repo add argo https://argoproj.github.io/argo-helm

# Vault Plugin Credentials 설정
kubectl -n argocd delete -f argocd-installation/argocd-vault-plugin-credentials.yaml
kubectl -n argocd apply -f argocd-installation/argocd-vault-plugin-credentials.yaml

# ArgoCD 설치
helm upgrade --debug --install argocd argo/argo-cd \
  -n argocd \
  -f argocd-installation/argocd-helm-values.yaml \
  --version 5.20.4

# Vault Plugin ConfigMap 적용
kubectl -n argocd delete -f argocd-installation/argocd-vault-plugin-cmp.yaml
kubectl -n argocd apply -f argocd-installation/argocd-vault-plugin-cmp.yaml

# Service LoadBalancer로 변경
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# 초기 비밀번호 추출
sleep 120
TMP_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# ArgoCD CLI로 비밀번호 변경
argocd login `kubectl get service -n argocd | grep -w "argocd-server " | awk '{print $4}'` \
  --username admin --password ${TMP_PASSWORD} --insecure
argocd account update-password --account admin \
  --current-password ${TMP_PASSWORD} --new-password ${admin_password}

# Ingress 설정
cp -Rf ingress-argocd.yaml ingress-argocd.yaml_bak
sed -i "s/eks_project/${eks_project}/g" ingress-argocd.yaml_bak
sed -i "s/eks_domain/${eks_domain}/g" ingress-argocd.yaml_bak
kubectl apply -f ingress-argocd.yaml_bak -n argocd
```

**핵심 포인트:**
- Vault Plugin 통합
- 초기 비밀번호 자동 변경
- LoadBalancer Service 패치

---

### 6. AWS Load Balancer Controller 설치

**파일**: `tz-eks-main/tz-local/resource/elb-controller/install.sh`

```bash
#!/usr/bin/env bash

# Repository 추가
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# 기존 설치 제거
helm uninstall aws-load-balancer-controller -n kube-system

# 설치
helm upgrade --debug --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=${eks_project} \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=${AWS_REGION} \
  --set vpcId=${VPC_ID}
```

**핵심 포인트:**
- kube-system 네임스페이스에 설치
- ServiceAccount는 Terraform으로 사전 생성
- VPC ID 동적 전달

---

### 7. Harbor (Container Registry) 설치

**파일**: `tz-eks-main/tz-local/resource/harbor/install.sh`

```bash
#!/usr/bin/env bash

# 변수 로드
eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
NS=default

# Repository 추가
helm repo add harbor https://helm.goharbor.io

# 기존 설치 제거
helm uninstall harbor-release

# Values 파일 커스터마이징
cp -Rf values.yaml values.yaml_bak
sed -i "s/eks_project/${eks_project}/g" values.yaml_bak
sed -i "s/eks_domain/${eks_domain}/g" values.yaml_bak
sed -i "s|NS|devops|g" values.yaml_bak

# Harbor 설치
helm upgrade --debug --install --reuse-values harbor-release harbor/harbor \
  -f values.yaml_bak

echo https://harbor.devops.${eks_project}.${eks_domain}
echo admin / Harbor12345
```

**핵심 포인트:**
- Container Registry 구축
- 기본 관리자 계정 자동 설정

---

### 8. Nexus Repository 설치

**파일**: `tz-eks-main/tz-local/resource/nexus/helm/install.sh`

```bash
#!/usr/bin/env bash

# 변수 로드
eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
admin_password=$(prop 'project' 'admin_password')
NS=devops

# Repository 추가
helm repo add oteemocharts https://oteemo.github.io/charts
helm search repo oteemocharts/sonatype-nexus
helm repo update

# 기존 설치 제거
helm delete sonatype-nexus -n ${NS}

# Values 파일 커스터마이징
cp values.yaml values.yaml_bak
sed -i "s/admin_password/${admin_password}/g" values.yaml_bak
sed -i "s/eks_project/${eks_project}/g" values.yaml_bak
sed -i "s/eks_domain/${eks_domain}/g" values.yaml_bak

# Nexus 설치
helm upgrade --debug --install --reuse-values sonatype-nexus \
  -n ${NS} \
  oteemocharts/sonatype-nexus \
  -f values.yaml_bak \
  --values="values.yaml_bak"

# Ingress 설정
cp -Rf ingress-nexus.yaml ingress-nexus.yaml_bak
sed -i "s/eks_project/${eks_project}/g" ingress-nexus.yaml_bak
sed -i "s/eks_domain/${eks_domain}/g" ingress-nexus.yaml_bak
kubectl apply -f ingress-nexus.yaml_bak -n ${NS}

# Release 확인
helm list --all-namespaces -a
```

**핵심 포인트:**
- Artifact Repository (Maven, NPM, Docker 등)
- 관리자 비밀번호 커스터마이징

---

## 고급 패턴

### 1. 다단계 설치 패턴

일부 복잡한 Chart는 여러 단계로 나누어 설치:

```bash
# 1단계: 기본 설치 (필수 설정만)
helm upgrade --debug --install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --version 44.3.0 \
  --set alertmanager.persistentVolume.storageClass="gp3" \
  --set server.persistentVolume.storageClass="gp3"

# 2단계: 세부 설정 적용
helm upgrade --debug --install --reuse-values prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --version 44.3.0 \
  -f values.yaml_bak \
  --set alertmanager.baseURL=https://alertmanager.default.${eks_project}.${eks_domain}
```

**이유:**
- PersistentVolume 생성 후 추가 설정 적용
- 기본 리소스 생성 대기 시간 확보

---

### 2. 조건부 설치 패턴

```bash
# Release 존재 여부 확인
if helm list -n jenkins | grep -q jenkins; then
  echo "Jenkins already installed, upgrading..."
  helm upgrade jenkins jenkins/jenkins -f values.yaml -n jenkins
else
  echo "Installing Jenkins..."
  helm install jenkins jenkins/jenkins -f values.yaml -n jenkins
fi
```

**간단한 방법: `--install` 플래그 사용**
```bash
# 자동으로 판단하여 install 또는 upgrade 수행
helm upgrade --install jenkins jenkins/jenkins -f values.yaml -n jenkins
```

---

### 3. CRD 사전 설치 패턴

일부 Chart는 CRD(Custom Resource Definition)를 별도로 설치해야 함:

```bash
# Cert-Manager 예시
kubectl apply --validate=false -f https://github.com/cert-manager/cert-manager/releases/download/v1.10.0/cert-manager.crds.yaml

# 그 다음 Helm Chart 설치
helm upgrade --install cert-manager jetstack/cert-manager -n cert-manager
```

**Prometheus Operator CRD 삭제 예시 (주석 처리됨):**
```bash
kubectl -n monitoring delete -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.45.0/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
kubectl -n monitoring delete -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.45.0/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
# ... 기타 CRD
```

---

### 4. 버전 고정 패턴

프로덕션 환경에서는 버전을 명시적으로 고정:

```bash
# Jenkins
APP_VERSION=4.3.27
helm upgrade --install jenkins jenkins/jenkins --version ${APP_VERSION} -n jenkins

# Vault
helm upgrade --install vault hashicorp/vault --version 0.25.0 -n vault

# Ingress NGINX
APP_VERSION=4.0.13
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --version ${APP_VERSION} -n default

# Prometheus Stack
STACK_VERSION=44.3.0
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --version ${STACK_VERSION} -n monitoring
```

**이유:**
- 예상치 못한 업데이트 방지
- 환경 간 일관성 유지
- 롤백 시 명확한 버전 관리

---

### 5. 설치 후 대기 및 확인 패턴

```bash
# 설치 후 대기
helm upgrade --install jenkins jenkins/jenkins -n jenkins
sleep 60

# Pod 상태 확인
kubectl get pods -n jenkins

# Service 확인
kubectl get svc -n jenkins

# Release 상태 확인
helm status jenkins -n jenkins

# 특정 리소스 대기
kubectl wait --for=condition=ready pod -l app=jenkins -n jenkins --timeout=300s
```

---

### 6. Values 파일 병합 패턴

여러 Values 파일을 병합하여 환경별 설정 관리:

```bash
# 공통 설정 + 환경별 설정
helm upgrade --install myapp myrepo/myapp \
  -f values.yaml \
  -f values-prod.yaml \
  -f secrets.yaml

# 우선순위: secrets.yaml > values-prod.yaml > values.yaml
```

---

### 7. Helm Template 미리보기

실제 설치 전에 생성될 매니페스트 확인:

```bash
# 템플릿 렌더링 (설치하지 않음)
helm template jenkins jenkins/jenkins -f values.yaml -n jenkins

# 특정 리소스만 확인
helm template jenkins jenkins/jenkins -f values.yaml -n jenkins | grep -A 20 "kind: Deployment"

# 파일로 저장
helm template jenkins jenkins/jenkins -f values.yaml -n jenkins > jenkins-manifests.yaml
```

---

### 8. Helm Diff 플러그인 (선택적)

변경사항 미리 확인:

```bash
# Helm Diff 플러그인 설치
helm plugin install https://github.com/databus23/helm-diff

# 변경사항 확인
helm diff upgrade jenkins jenkins/jenkins -f values.yaml -n jenkins
```

---

## 트러블슈팅

### 1. Release가 실패 상태일 때

```bash
# Release 상태 확인
helm list -n jenkins -a

# 상세 상태 확인
helm status jenkins -n jenkins

# 실패한 Release 삭제
helm uninstall jenkins -n jenkins

# 강제 삭제
helm uninstall jenkins -n jenkins --no-hooks
```

---

### 2. CRD 충돌 문제

```bash
# 기존 CRD 확인
kubectl get crd | grep cert-manager

# CRD 삭제
kubectl get customresourcedefinition | grep cert-manager | awk '{print $1}' | xargs -I {} kubectl delete customresourcedefinition {}

# 또는 일괄 삭제
kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.crds.yaml
```

---

### 3. Repository 업데이트 오류

```bash
# Repository 제거 후 재추가
helm repo remove prometheus-community
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 캐시 정리
rm -rf ~/.cache/helm
```

---

### 4. Values 파일 문법 오류

```bash
# YAML 문법 검증
yamllint values.yaml

# 또는 온라인 도구
# http://www.yamllint.com/

# 렌더링 테스트
helm template myapp myrepo/myapp -f values.yaml --debug
```

---

### 5. Release가 Pending 상태

```bash
# Pod 이벤트 확인
kubectl get events -n jenkins --sort-by='.lastTimestamp'

# Pod 상세 정보
kubectl describe pod jenkins-0 -n jenkins

# Helm Release 히스토리
helm history jenkins -n jenkins

# 강제 재시작
kubectl rollout restart deployment jenkins -n jenkins
```

---

### 6. 이전 버전으로 롤백

```bash
# 히스토리 확인
helm history jenkins -n jenkins

# 특정 리비전으로 롤백
helm rollback jenkins 2 -n jenkins

# 바로 이전 버전으로 롤백
helm rollback jenkins -n jenkins
```

---

### 7. Webhook Validation 오류

```bash
# 프로젝트에서 발견된 패턴
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission

# 또는 특정 Webhook 삭제
kubectl delete validatingwebhookconfiguration <webhook-name>
```

---

### 8. 네임스페이스 삭제가 안 될 때

```bash
# Helm Release 먼저 삭제
helm uninstall jenkins -n jenkins

# 네임스페이스의 finalizer 제거
kubectl get namespace jenkins -o json \
  | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
  | kubectl replace --raw /api/v1/namespaces/jenkins/finalize -f -

# 강제 삭제
kubectl delete namespace jenkins --force --grace-period=0
```

---

## Helm 명령어 치트시트

### Repository 관리
```bash
helm repo add <name> <url>          # Repository 추가
helm repo list                       # Repository 목록
helm repo update                     # Repository 업데이트
helm repo remove <name>              # Repository 삭제
```

### Chart 검색 및 정보
```bash
helm search repo <keyword>           # Chart 검색
helm search repo <chart> --versions  # 모든 버전 보기
helm show chart <chart>              # Chart 정보
helm show values <chart>             # 기본 Values
helm show all <chart>                # 모든 정보
```

### Release 관리
```bash
helm install <name> <chart>          # 설치
helm upgrade <name> <chart>          # 업그레이드
helm upgrade --install <name> <chart> # 설치 또는 업그레이드
helm uninstall <name>                # 삭제
helm list                            # Release 목록
helm list -n <namespace>             # 네임스페이스별 목록
helm list --all-namespaces           # 모든 네임스페이스
helm list -a                         # 삭제된 것 포함
```

### Release 상태
```bash
helm status <name>                   # Release 상태
helm history <name>                  # 히스토리
helm get values <name>               # 현재 Values
helm get manifest <name>             # 매니페스트
```

### 롤백
```bash
helm rollback <name>                 # 이전 버전으로
helm rollback <name> <revision>      # 특정 리비전으로
```

### 옵션
```bash
-n, --namespace <ns>                 # 네임스페이스 지정
-f, --values <file>                  # Values 파일
--set key=value                      # 값 설정
--version <version>                  # Chart 버전
--install                            # 없으면 설치
--reuse-values                       # 기존 값 재사용
--debug                              # 디버그 출력
--dry-run                            # 시뮬레이션
--wait                               # Ready 대기
--timeout <duration>                 # 타임아웃
```

---

## 프로젝트의 Helm 사용 통계

### 설치된 주요 컴포넌트

| 컴포넌트 | Chart | Repository | 버전 | 네임스페이스 |
|---------|-------|-----------|------|------------|
| **Jenkins** | jenkins/jenkins | charts.jenkins.io | 4.3.27 | jenkins |
| **Vault** | hashicorp/vault | helm.releases.hashicorp.com | 0.25.0 | vault |
| **Prometheus Stack** | prometheus-community/kube-prometheus-stack | prometheus-community.github.io | 44.3.0 | monitoring |
| **Ingress NGINX** | ingress-nginx/ingress-nginx | kubernetes.github.io | 4.0.13 | default |
| **ArgoCD** | argo/argo-cd | argoproj.github.io | 5.20.4 | argocd |
| **Harbor** | harbor/harbor | helm.goharbor.io | latest | default |
| **Nexus** | oteemocharts/sonatype-nexus | oteemo.github.io | latest | devops |
| **AWS LB Controller** | eks/aws-load-balancer-controller | aws.github.io | latest | kube-system |
| **Cert-Manager** | jetstack/cert-manager | charts.jetstack.io | latest | cert-manager |
| **Blackbox Exporter** | prometheus-community/prometheus-blackbox-exporter | prometheus-community.github.io | latest | monitoring |

### Repository 요약

```bash
# 프로젝트에서 사용하는 Repository 일괄 추가
helm repo add stable https://charts.helm.sh/stable
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jenkins https://charts.jenkins.io
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo add argo https://argoproj.github.io/argo-helm
helm repo add eks https://aws.github.io/eks-charts
helm repo add harbor https://helm.goharbor.io
helm repo add oteemocharts https://oteemo.github.io/charts
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

---

## 모범 사례 (Best Practices)

### 1. 버전 관리
✅ 프로덕션 환경에서는 항상 `--version` 지정  
✅ Values 파일을 Git으로 버전 관리  
✅ 중요한 변경 전 `helm history` 확인  

### 2. Values 파일 관리
✅ 민감한 정보는 Secret으로 분리  
✅ 환경별 Values 파일 준비 (dev, staging, prod)  
✅ Values 파일에 주석으로 설정 의도 기록  

### 3. 네임스페이스 전략
✅ 용도별로 네임스페이스 분리  
✅ Release 이름은 네임스페이스 내에서 고유  
✅ RBAC으로 네임스페이스별 접근 제어  

### 4. 설치 스크립트 작성
✅ 멱등성 확보 (`--install` 플래그 활용)  
✅ 에러 처리 (`if [[ $? != 0 ]]; then exit 1; fi`)  
✅ 설치 후 확인 단계 포함  
✅ 충분한 대기 시간 (`sleep`) 설정  

### 5. 디버깅
✅ `--debug` 플래그로 상세 출력  
✅ `helm template`으로 매니페스트 미리 확인  
✅ `--dry-run`으로 시뮬레이션  

### 6. 롤백 계획
✅ 주요 변경 전 현재 상태 백업  
✅ 롤백 시나리오 사전 테스트  
✅ `helm history`로 이전 버전 확인 가능  

---

## 참고 자료

### 공식 문서
- [Helm 공식 문서](https://helm.sh/docs/)
- [Artifact Hub](https://artifacthub.io/) - Helm Chart 저장소
- [Helm Chart 개발 가이드](https://helm.sh/docs/chart_template_guide/)

### 프로젝트 스크립트 위치
```
tz-eks-main/tz-local/resource/
├── argocd/helm/install.sh
├── jenkins/helm/install.sh
├── vault/helm/install.sh
├── monitoring/install.sh
├── ingress_nginx/install.sh
├── harbor/install.sh
├── nexus/helm/install.sh
└── elb-controller/install.sh
```

---

**작성일**: 2025-11-14  
**프로젝트**: KUBE (tz-eks-main)  
**Helm 버전**: 3.x  
**분석 대상**: 프로젝트 전체 Helm 사용 패턴

