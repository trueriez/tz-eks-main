# AWS Account ID 및 Hosted Zone ID 확인 가이드

## 📋 목차
1. [AWS Account ID 확인 방법](#aws-account-id-확인-방법)
2. [Route53 Hosted Zone ID 확인 방법](#route53-hosted-zone-id-확인-방법)
3. [프로젝트 설정 파일 업데이트](#프로젝트-설정-파일-업데이트)
4. [자동화 스크립트](#자동화-스크립트)
5. [트러블슈팅](#트러블슈팅)

---

## AWS Account ID 확인 방법

### 1. AWS CLI로 확인 (권장)

가장 빠르고 정확한 방법입니다.

```bash
# Account ID만 출력
aws sts get-caller-identity --query Account --output text

# 전체 정보 확인 (JSON)
aws sts get-caller-identity

# 출력 예시:
# {
#     "UserId": "AIDXXXXXXXXXXXXXXXXX",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/username"
# }
```

**환경 변수로 저장:**
```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Your AWS Account ID: $AWS_ACCOUNT_ID"
```

**여러 프로파일이 있는 경우:**
```bash
# 특정 프로파일 지정
aws sts get-caller-identity --profile myprofile --query Account --output text

# 기본 프로파일
aws sts get-caller-identity --profile default --query Account --output text
```

---

### 2. AWS Management Console에서 확인

#### 방법 A: 우측 상단 계정 메뉴 (가장 쉬움)
1. AWS Console 로그인 (https://console.aws.amazon.com)
2. 우측 상단의 **계정 이름** 클릭
3. 드롭다운 메뉴에서 **계정 ID** 확인 (12자리 숫자)
   - 형식: `1234-5678-9012` 또는 `123456789012`

#### 방법 B: IAM 대시보드
1. AWS Console → 검색창에 **IAM** 입력
2. IAM 대시보드 이동
3. 좌측 상단 또는 우측에 **AWS Account ID** 표시됨

#### 방법 C: Billing Dashboard
1. AWS Console → **Billing and Cost Management**
2. 대시보드 우측 상단에 Account ID 표시

#### 방법 D: Support Center
1. AWS Console → 상단 메뉴의 **Support** → **Support Center**
2. 페이지 상단에 Account ID 표시

---

### 3. Terraform으로 자동 확인

Terraform 코드에서 자동으로 가져올 수 있습니다:

```hcl
# data.tf
data "aws_caller_identity" "current" {}

# outputs.tf
output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "AWS Account ID"
}

output "caller_arn" {
  value       = data.aws_caller_identity.current.arn
  description = "ARN of the caller"
}

# 사용 예시
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket-${data.aws_caller_identity.current.account_id}"
}
```

**Terraform 실행 후 확인:**
```bash
terraform output account_id
```

---

## Route53 Hosted Zone ID 확인 방법

### 1. AWS CLI로 확인 (권장)

```bash
# 모든 Hosted Zone 목록 조회
aws route53 list-hosted-zones

# 특정 도메인의 Hosted Zone ID만 조회
aws route53 list-hosted-zones --query "HostedZones[?Name == 'topzone.me.'].Id" --output text

# 도메인 이름 끝에 점(.)을 붙여야 함!
# 예시: 'example.com.' (O)  'example.com' (X)

# 결과 예시:
# /hostedzone/Z1234567890ABC

# Zone ID만 추출 (맨 앞 '/hostedzone/' 제거)
aws route53 list-hosted-zones --query "HostedZones[?Name == 'topzone.me.'].Id" --output text | cut -d'/' -f3
```

**환경 변수로 저장:**
```bash
export HOSTED_ZONE_ID=$(aws route53 list-hosted-zones \
  --query "HostedZones[?Name == 'topzone.me.'].Id" \
  --output text | cut -d'/' -f3)
echo "Hosted Zone ID: $HOSTED_ZONE_ID"
```

**여러 도메인 한 번에 확인:**
```bash
# 모든 Hosted Zone의 이름과 ID 출력
aws route53 list-hosted-zones --query "HostedZones[].[Name,Id]" --output table

# 출력 예시:
# --------------------------------
# |     ListHostedZones          |
# +------------------+-----------+
# |  topzone.me.     | /hosted...+
# |  example.com.    | /hosted...+
# +------------------+-----------+
```

---

### 2. AWS Management Console에서 확인

1. AWS Console → 검색창에 **Route 53** 입력
2. 좌측 메뉴에서 **Hosted zones** 클릭
3. 도메인 목록에서 **Hosted zone ID** 컬럼 확인
   - 형식: `Z1234567890ABC` (Z로 시작하는 13자리 문자열)

---

### 3. 프로젝트 스크립트에서 자동 확인

이 프로젝트의 스크립트에서 사용하는 방법:

```bash
# ingress_nginx/install.sh 예시
eks_domain="topzone.me"

HOSTZONE_ID=$(aws route53 list-hosted-zones \
  --query "HostedZones[?Name == '${eks_domain}.']" \
  | grep '"Id"' \
  | awk '{print $2}' \
  | sed 's/\"//g;s/,//' \
  | cut -d'/' -f3)

echo "Hosted Zone ID: $HOSTZONE_ID"
```

---

## 프로젝트 설정 파일 업데이트

### 1. .auto.tfvars 파일 수동 업데이트

파일 위치: `tz-eks-main/resources/.auto.tfvars`

```terraform
# 1단계: AWS Account ID 확인
# 터미널에서 실행:
# aws sts get-caller-identity --query Account --output text

account_id = "123456789012"  # 여기에 실제 Account ID 입력

cluster_name = "topzone-k8s"
region = "ap-northeast-2"
environment = "prod"

# 2단계: Route53 Hosted Zone ID 확인
# 터미널에서 실행:
# aws route53 list-hosted-zones --query "HostedZones[?Name == 'topzone.me.'].Id" --output text | cut -d'/' -f3

tzcorp_zone_id = "Z1234567890ABC"  # 여기에 실제 Hosted Zone ID 입력

VCP_BCLASS = "10.20"
instance_type = "t3.large"
DB_PSWD = "DevOps!323"
k8s_config_path = "/root/.kube/config"
```

---

### 2. .auto.tfvars 파일 자동 업데이트 스크립트

```bash
#!/bin/bash

# 프로젝트 루트로 이동
cd /Users/codesonic/Documents/Workspace/KUBE/tz-eks-main

# AWS Account ID 가져오기
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $ACCOUNT_ID"

# 도메인 설정
DOMAIN="topzone.me"

# Route53 Hosted Zone ID 가져오기
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones \
  --query "HostedZones[?Name == '${DOMAIN}.'].Id" \
  --output text | cut -d'/' -f3)
echo "Hosted Zone ID: $HOSTED_ZONE_ID"

# .auto.tfvars 파일 백업
cp resources/.auto.tfvars resources/.auto.tfvars.backup

# account_id 업데이트
sed -i.bak "s/account_id = \".*\"/account_id = \"${ACCOUNT_ID}\"/" resources/.auto.tfvars

# tzcorp_zone_id 업데이트
sed -i.bak "s/tzcorp_zone_id = \".*\"/tzcorp_zone_id = \"${HOSTED_ZONE_ID}\"/" resources/.auto.tfvars

# 업데이트된 내용 확인
echo ""
echo "=== 업데이트된 .auto.tfvars 내용 ==="
grep -E "account_id|tzcorp_zone_id" resources/.auto.tfvars

echo ""
echo "✅ .auto.tfvars 파일이 업데이트되었습니다!"
echo "📁 백업 파일: resources/.auto.tfvars.backup"
```

**스크립트 실행:**
```bash
# 실행 권한 부여
chmod +x update_tfvars.sh

# 실행
./update_tfvars.sh
```

---

### 3. project 파일 업데이트

파일 위치: `tz-eks-main/resources/project`

```bash
# resources/project 파일 예시
aws_account_id=123456789012
project=topzone-k8s
domain=topzone.me
region=ap-northeast-2
admin_password=YourSecurePassword
github_id=your_github_id
github_token=ghp_xxxxxxxxxxxx
dockerhub_id=your_dockerhub_id
dockerhub_password=your_dockerhub_password
vault=hvs.xxxxxxxxxxxx
smtp_password=your_smtp_password
basic_password=your_basic_password
grafana_goauth2_client_id=xxxxx
grafana_goauth2_client_secret=xxxxx
```

**project 파일 자동 업데이트:**
```bash
#!/bin/bash

cd /Users/codesonic/Documents/Workspace/KUBE/tz-eks-main

# AWS Account ID 가져오기
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# project 파일 백업
cp resources/project resources/project.backup

# aws_account_id 라인이 있으면 업데이트, 없으면 추가
if grep -q "^aws_account_id=" resources/project; then
  sed -i.bak "s/^aws_account_id=.*/aws_account_id=${ACCOUNT_ID}/" resources/project
else
  echo "aws_account_id=${ACCOUNT_ID}" >> resources/project
fi

echo "✅ project 파일이 업데이트되었습니다!"
grep "aws_account_id" resources/project
```

---

## 자동화 스크립트

### 완전 자동화 스크립트

파일명: `setup_aws_config.sh`

```bash
#!/bin/bash

set -e  # 에러 발생 시 중단

echo "=========================================="
echo "AWS 설정 자동화 스크립트"
echo "=========================================="
echo ""

# 프로젝트 루트 디렉토리
PROJECT_ROOT="/Users/codesonic/Documents/Workspace/KUBE/tz-eks-main"
cd ${PROJECT_ROOT}

# AWS CLI 설치 확인
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI가 설치되어 있지 않습니다."
    echo "설치 방법: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# AWS 인증 확인
echo "🔍 AWS 인증 확인 중..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS 인증이 설정되어 있지 않습니다."
    echo "다음 명령어로 설정하세요: aws configure"
    exit 1
fi

# 1. AWS Account ID 가져오기
echo "📝 AWS Account ID 조회 중..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [[ -z "$ACCOUNT_ID" ]]; then
    echo "❌ Account ID를 가져올 수 없습니다."
    exit 1
fi
echo "✅ Account ID: $ACCOUNT_ID"

# 2. 도메인 입력 받기
read -p "📝 도메인 이름을 입력하세요 (예: topzone.me): " DOMAIN
if [[ -z "$DOMAIN" ]]; then
    echo "❌ 도메인 이름이 필요합니다."
    exit 1
fi

# 3. Route53 Hosted Zone ID 가져오기
echo "🔍 Route53 Hosted Zone ID 조회 중..."
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones \
  --query "HostedZones[?Name == '${DOMAIN}.'].Id" \
  --output text 2>/dev/null | cut -d'/' -f3)

if [[ -z "$HOSTED_ZONE_ID" ]]; then
    echo "⚠️  경고: 도메인 '${DOMAIN}'에 대한 Hosted Zone을 찾을 수 없습니다."
    echo "Route53에서 Hosted Zone을 먼저 생성하거나 수동으로 입력하세요."
    read -p "Hosted Zone ID를 수동으로 입력하시겠습니까? (y/n): " MANUAL_INPUT
    if [[ "$MANUAL_INPUT" == "y" ]]; then
        read -p "Hosted Zone ID: " HOSTED_ZONE_ID
    else
        HOSTED_ZONE_ID="XXXXXXXXXX"
    fi
fi
echo "✅ Hosted Zone ID: $HOSTED_ZONE_ID"

# 4. 파일 백업
echo ""
echo "💾 기존 파일 백업 중..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p backups
cp resources/.auto.tfvars backups/.auto.tfvars.${TIMESTAMP}
cp resources/project backups/project.${TIMESTAMP}
echo "✅ 백업 완료: backups/ 디렉토리"

# 5. .auto.tfvars 파일 업데이트
echo ""
echo "📝 .auto.tfvars 파일 업데이트 중..."
sed -i.bak "s/account_id = \"[^\"]*\"/account_id = \"${ACCOUNT_ID}\"/" resources/.auto.tfvars
sed -i.bak "s/tzcorp_zone_id = \"[^\"]*\"/tzcorp_zone_id = \"${HOSTED_ZONE_ID}\"/" resources/.auto.tfvars
rm -f resources/.auto.tfvars.bak
echo "✅ .auto.tfvars 업데이트 완료"

# 6. project 파일 업데이트
echo ""
echo "📝 project 파일 업데이트 중..."
if grep -q "^aws_account_id=" resources/project; then
  sed -i.bak "s/^aws_account_id=.*/aws_account_id=${ACCOUNT_ID}/" resources/project
else
  echo "aws_account_id=${ACCOUNT_ID}" >> resources/project
fi

if grep -q "^domain=" resources/project; then
  sed -i.bak "s/^domain=.*/domain=${DOMAIN}/" resources/project
else
  echo "domain=${DOMAIN}" >> resources/project
fi
rm -f resources/project.bak
echo "✅ project 파일 업데이트 완료"

# 7. 결과 확인
echo ""
echo "=========================================="
echo "✅ 설정 완료!"
echo "=========================================="
echo ""
echo "📋 업데이트된 내용:"
echo "  - AWS Account ID: ${ACCOUNT_ID}"
echo "  - Domain: ${DOMAIN}"
echo "  - Hosted Zone ID: ${HOSTED_ZONE_ID}"
echo ""
echo "📁 업데이트된 파일:"
echo "  - resources/.auto.tfvars"
echo "  - resources/project"
echo ""
echo "💾 백업 위치:"
echo "  - backups/.auto.tfvars.${TIMESTAMP}"
echo "  - backups/project.${TIMESTAMP}"
echo ""
echo "🚀 다음 단계:"
echo "  1. resources/.auto.tfvars 파일 확인"
echo "  2. resources/project 파일의 다른 설정 확인"
echo "  3. bash bootstrap.sh 실행"
echo ""
```

**사용 방법:**
```bash
# 스크립트 저장 및 실행 권한 부여
cd /Users/codesonic/Documents/Workspace/KUBE/tz-eks-main
chmod +x setup_aws_config.sh

# 실행
./setup_aws_config.sh
```

---

## 트러블슈팅

### 1. AWS CLI 명령어가 작동하지 않음

**증상:**
```
bash: aws: command not found
```

**해결 방법:**
```bash
# AWS CLI 설치 (macOS)
brew install awscli

# 또는 공식 설치 방법
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# 설치 확인
aws --version
```

---

### 2. 인증 오류

**증상:**
```
An error occurred (InvalidClientTokenId) when calling the GetCallerIdentity operation
```

**해결 방법:**
```bash
# AWS 인증 설정
aws configure

# 입력 항목:
# AWS Access Key ID: AKIAXXXXXXXXXXXXXXXX
# AWS Secret Access Key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# Default region name: ap-northeast-2
# Default output format: json

# 인증 확인
aws sts get-caller-identity
```

---

### 3. Hosted Zone을 찾을 수 없음

**증상:**
```
Hosted Zone ID가 빈 값으로 나옴
```

**원인:**
- Route53에 Hosted Zone이 없음
- 도메인 이름 형식이 잘못됨 (끝에 점(.) 필요)

**해결 방법:**
```bash
# 1. 모든 Hosted Zone 확인
aws route53 list-hosted-zones

# 2. 도메인 이름 끝에 점(.) 추가
aws route53 list-hosted-zones --query "HostedZones[?Name == 'topzone.me.'].Id" --output text

# 3. Route53에 Hosted Zone 생성 (없는 경우)
aws route53 create-hosted-zone \
  --name topzone.me \
  --caller-reference $(date +%s)
```

---

### 4. 여러 AWS 프로파일 사용

**증상:**
- 여러 AWS 계정을 사용하는데 기본 프로파일이 아님

**해결 방법:**
```bash
# 프로파일 목록 확인
cat ~/.aws/credentials

# 특정 프로파일 사용
export AWS_PROFILE=myprofile
aws sts get-caller-identity

# 또는 명령어마다 지정
aws sts get-caller-identity --profile myprofile
aws route53 list-hosted-zones --profile myprofile
```

---

### 5. 권한 부족 오류

**증상:**
```
An error occurred (AccessDenied) when calling the ListHostedZones operation
```

**해결 방법:**
- IAM 사용자에게 Route53 읽기 권한 부여 필요
- 필요한 권한: `route53:ListHostedZones`

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:GetHostedZone"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 참고 자료

### AWS 공식 문서
- [AWS CLI 설치 가이드](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [AWS CLI 설정](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)
- [Route53 API Reference](https://docs.aws.amazon.com/Route53/latest/APIReference/Welcome.html)

### 프로젝트 관련 파일
```
tz-eks-main/
├── resources/
│   ├── .auto.tfvars          # Terraform 변수 파일
│   ├── project               # 프로젝트 설정 파일
│   ├── config                # AWS CLI 설정
│   └── credentials           # AWS 인증 정보
├── bootstrap.sh              # 메인 부트스트랩 스크립트
└── terraform-aws-eks/        # EKS Terraform 코드
```

### 빠른 참조 명령어

```bash
# AWS Account ID
aws sts get-caller-identity --query Account --output text

# Hosted Zone ID
aws route53 list-hosted-zones --query "HostedZones[?Name == 'topzone.me.'].Id" --output text | cut -d'/' -f3

# 현재 AWS 사용자 정보
aws sts get-caller-identity

# 모든 Hosted Zone 목록
aws route53 list-hosted-zones --output table

# AWS 설정 확인
aws configure list

# 프로파일 목록
cat ~/.aws/credentials | grep '\[' | tr -d '[]'
```

---

**작성일**: 2025-11-14  
**프로젝트**: KUBE (tz-eks-main)  
**대상 파일**: 
- `resources/.auto.tfvars`
- `resources/project`

