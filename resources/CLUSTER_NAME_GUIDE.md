# cluster_name 설정 가이드

## 📌 요약

**`cluster_name`은 사용자가 임의로 설정하는 값입니다.**

하지만 이 값은 프로젝트 전체에서 **일관되게 사용**되므로 신중하게 선택해야 합니다.

---

## cluster_name의 역할

### 1. **EKS 클러스터 이름**
AWS에서 실제로 생성되는 Kubernetes 클러스터의 이름으로 사용됩니다.

```bash
# AWS Console에서 보이는 이름
EKS Cluster Name: topzone-k8s

# eksctl 명령어
eksctl get nodegroup --cluster=topzone-k8s
```

### 2. **리소스 네이밍 규칙**
모든 AWS 리소스의 이름에 포함됩니다:

```
VPC: topzone-k8s-vpc
Security Group: topzone-k8s-eks_cluster_sg
IAM Role: topzone-k8s-eks-cluster-role
CloudWatch Log Group: /aws/eks/topzone-k8s/cluster
S3 Bucket: jenkins-topzone-k8s
ECR Repository: devops-jenkins-topzone-k8s
KMS Key Alias: topzone-k8s-vault-kms-unseal_01
```

### 3. **도메인 구성**
Ingress 도메인 생성 시 사용됩니다:

```
기본 패턴: *.${namespace}.${cluster_name}.${domain}

예시:
- https://jenkins.default.topzone-k8s.topzone.me
- https://grafana.default.topzone-k8s.topzone.me
- https://argocd.default.topzone-k8s.topzone.me
- https://vault.default.topzone-k8s.topzone.me
- https://test.default.topzone-k8s.topzone.me
```

### 4. **Kubernetes 리소스 태그**
모든 Kubernetes 관련 리소스에 태그로 추가됩니다:

```hcl
tags = {
  "application" = "topzone-k8s"
  "environment" = "prod"
  "kubernetes.io/cluster/topzone-k8s" = "owned"
}
```

### 5. **kubeconfig 파일 이름**
생성되는 kubeconfig 파일의 이름:

```bash
kubeconfig_topzone-k8s
```

---

## 현재 프로젝트 설정

### .auto.tfvars 파일
```terraform
cluster_name = "topzone-k8s"
```

### project 파일 (스크립트에서 사용)
```bash
project=topzone-k8s
```

**⚠️ 중요**: 이 두 값은 **반드시 동일**해야 합니다!

---

## 네이밍 권장 사항

### ✅ 좋은 예시
```
topzone-k8s          # 조직명-용도
company-prod         # 회사명-환경
myapp-eks            # 앱명-플랫폼
project-dev          # 프로젝트명-환경
team-cluster         # 팀명-클러스터
```

### ❌ 피해야 할 예시
```
cluster1             # 의미 없는 이름
my-cluster           # 너무 일반적
k8s                  # 너무 짧음
production_cluster   # 언더스코어 사용 (하이픈 권장)
TOPZONE-K8S          # 대문자 (소문자 권장)
```

### 네이밍 규칙
1. **소문자와 하이픈(-) 사용** (언더스코어 피하기)
2. **최대 63자 제한** (DNS 레이블 규칙)
3. **의미 있는 이름** 사용
4. **환경 구분** (dev, staging, prod 등)
5. **조직/프로젝트 식별 가능**

---

## 설정 방법

### 1. .auto.tfvars 파일 수정

**파일 위치**: `tz-eks-main/resources/.auto.tfvars`

```terraform
# 현재 설정
cluster_name = "topzone-k8s"

# 변경 예시
cluster_name = "mycompany-prod"
```

### 2. project 파일 수정

**파일 위치**: `tz-eks-main/resources/project`

```bash
# 현재 설정
project=topzone-k8s

# .auto.tfvars와 동일한 값으로 변경
project=mycompany-prod
```

### 3. 자동 업데이트 스크립트

```bash
#!/bin/bash

# 새로운 클러스터 이름 설정
NEW_CLUSTER_NAME="mycompany-prod"

# .auto.tfvars 업데이트
sed -i.bak "s/cluster_name = \".*\"/cluster_name = \"${NEW_CLUSTER_NAME}\"/" resources/.auto.tfvars

# project 파일 업데이트
sed -i.bak "s/^project=.*/project=${NEW_CLUSTER_NAME}/" resources/project

# 확인
echo "=== .auto.tfvars ==="
grep "cluster_name" resources/.auto.tfvars

echo ""
echo "=== project ==="
grep "^project=" resources/project
```

---

## 프로젝트에서 사용되는 위치

### Terraform 파일

```terraform
# terraform-aws-eks/cluster.tf
resource "aws_eks_cluster" "this" {
  name = var.cluster_name  # ← 여기서 사용
  # ...
}

# terraform-aws-eks/workspace/base/vpc.tf
resource "aws_vpc" "vpc" {
  name = "${local.cluster_name}-vpc"  # ← 여기서 사용
  # ...
}

# terraform-aws-eks/workspace/base/locals.tf
locals {
  cluster_name = var.cluster_name  # ← 여기서 사용
  name         = local.cluster_name
  # ...
}
```

### 쉘 스크립트

```bash
# tz-local/docker/install.sh
eks_project=$(prop 'project' 'project')  # project 파일에서 읽음

# tz-local/resource/*/install.sh
eks_project=$(prop 'project' 'project')
echo "https://jenkins.default.${eks_project}.${eks_domain}"
```

### 도메인 사용 예시

모든 설치 스크립트에서 도메인 생성 시 사용:

```bash
# Jenkins
https://jenkins.default.topzone-k8s.topzone.me

# Grafana
https://grafana.default.topzone-k8s.topzone.me

# Prometheus
https://prometheus.default.topzone-k8s.topzone.me

# ArgoCD
https://argocd.default.topzone-k8s.topzone.me

# Vault
https://vault.default.topzone-k8s.topzone.me

# Harbor
https://harbor.devops.topzone-k8s.topzone.me

# Nexus
https://nexus.default.topzone-k8s.topzone.me
```

---

## 변경 시 주의사항

### ⚠️ 클러스터 이름 변경 시 영향

클러스터 이름을 변경하면 **완전히 새로운 인프라**가 생성됩니다:

1. **새로운 EKS 클러스터 생성**
2. **새로운 VPC 및 네트워크 생성**
3. **새로운 IAM Role 및 정책 생성**
4. **새로운 도메인 레코드 생성**
5. **모든 애플리케이션 재설치 필요**

### 기존 클러스터 유지하려면

기존 클러스터를 유지하고 싶다면 **cluster_name을 변경하지 마세요**!

### 변경이 필요한 경우

1. **기존 리소스 백업**
   ```bash
   # kubeconfig 백업
   cp ~/.kube/config ~/.kube/config.backup
   
   # Terraform state 백업
   cd terraform-aws-eks/workspace/base
   terraform state pull > terraform.tfstate.backup
   ```

2. **기존 리소스 삭제**
   ```bash
   bash bootstrap.sh remove
   ```

3. **cluster_name 변경**
   - `.auto.tfvars` 수정
   - `project` 파일 수정

4. **새 클러스터 생성**
   ```bash
   bash bootstrap.sh
   ```

---

## 환경별 cluster_name 예시

### 개발 환경
```terraform
cluster_name = "mycompany-dev"
environment  = "dev"
```

### 스테이징 환경
```terraform
cluster_name = "mycompany-staging"
environment  = "staging"
```

### 프로덕션 환경
```terraform
cluster_name = "mycompany-prod"
environment  = "prod"
```

### 멀티 리전
```terraform
# 서울 리전
cluster_name = "mycompany-kr-prod"
region       = "ap-northeast-2"

# 도쿄 리전
cluster_name = "mycompany-jp-prod"
region       = "ap-northeast-1"

# 버지니아 리전
cluster_name = "mycompany-us-prod"
region       = "us-east-1"
```

---

## 확인 방법

### 1. Terraform 변수 확인

```bash
cd terraform-aws-eks/workspace/base

# 변수 출력
terraform console
> var.cluster_name
"topzone-k8s"
```

### 2. AWS CLI로 확인

```bash
# EKS 클러스터 목록
aws eks list-clusters --region ap-northeast-2

# 특정 클러스터 정보
aws eks describe-cluster --name topzone-k8s --region ap-northeast-2
```

### 3. kubectl로 확인

```bash
# 현재 context 확인
kubectl config current-context

# Cluster 정보
kubectl cluster-info
```

### 4. 스크립트에서 확인

```bash
# project 파일에서 읽기
function prop {
  grep "${2}" "resources/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}

eks_project=$(prop 'project' 'project')
echo "Cluster Name: $eks_project"
```

---

## FAQ

### Q1: cluster_name을 변경해도 되나요?
**A**: 가능하지만, 완전히 새로운 클러스터가 생성됩니다. 기존 클러스터의 데이터는 마이그레이션해야 합니다.

### Q2: 여러 클러스터를 동시에 운영할 수 있나요?
**A**: 가능합니다. `.auto.tfvars` 파일을 환경별로 분리하여 관리하세요:
```
resources/
├── .auto.tfvars.dev
├── .auto.tfvars.staging
└── .auto.tfvars.prod
```

### Q3: cluster_name과 project 값이 달라도 되나요?
**A**: 안 됩니다! 두 값은 반드시 동일해야 합니다. 스크립트들이 이 값을 동일하게 사용합니다.

### Q4: 길이 제한이 있나요?
**A**: DNS 레이블 규칙에 따라 최대 63자까지 가능하지만, 짧고 명확한 이름을 권장합니다 (10-20자).

### Q5: 대문자를 사용할 수 있나요?
**A**: 기술적으로 가능하지만, AWS 리소스 네이밍 관례상 소문자와 하이픈 조합을 권장합니다.

---

## 체크리스트

클러스터를 생성하기 전에 확인하세요:

- [ ] `cluster_name`이 의미 있는 이름인가?
- [ ] `.auto.tfvars`의 `cluster_name`과 `project` 파일의 `project` 값이 동일한가?
- [ ] DNS 규칙을 준수하는가? (소문자, 하이픈, 63자 이하)
- [ ] 환경을 구분할 수 있는 이름인가? (dev/staging/prod)
- [ ] 조직 또는 프로젝트를 식별할 수 있는가?
- [ ] 도메인 형식이 적절한가? (`*.default.${cluster_name}.${domain}`)

---

## 참고 자료

### AWS 네이밍 규칙
- [EKS Cluster Naming](https://docs.aws.amazon.com/eks/latest/userguide/clusters.html)
- [AWS Tagging Best Practices](https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html)

### DNS 규칙
- [RFC 1123 - DNS Label](https://tools.ietf.org/html/rfc1123)
- 최대 63자
- 소문자 알파벳, 숫자, 하이픈만 허용
- 하이픈으로 시작하거나 끝날 수 없음

### 프로젝트 파일 위치
```
tz-eks-main/
├── resources/
│   ├── .auto.tfvars          # ← cluster_name 설정
│   └── project               # ← project 설정 (동일 값)
├── terraform-aws-eks/
│   ├── variables.tf          # ← cluster_name 변수 정의
│   └── workspace/base/
│       └── locals.tf         # ← cluster_name 사용
└── tz-local/
    └── resource/             # ← 모든 스크립트에서 eks_project로 사용
```

---

**작성일**: 2025-11-14  
**프로젝트**: KUBE (tz-eks-main)  
**현재 설정**: cluster_name = "topzone-k8s"

