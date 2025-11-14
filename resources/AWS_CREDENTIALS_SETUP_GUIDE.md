# AWS Credentials 설정 가이드

## 📋 목차
1. [credentials 파일이란?](#credentials-파일이란)
2. [Access Key 생성 방법](#access-key-생성-방법)
3. [credentials 파일 설정](#credentials-파일-설정)
4. [프로파일별 설정 전략](#프로파일별-설정-전략)
5. [자동 설정 스크립트](#자동-설정-스크립트)
6. [보안 권장 사항](#보안-권장-사항)
7. [테스트 및 검증](#테스트-및-검증)

---

## credentials 파일이란?

### 파일 구조
```ini
[default]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

[topzone-k8s]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

[topzone-k8s-admin]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

[topzone-k8s-dev]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 역할
- **인증 정보 저장**: AWS API 호출 시 사용할 자격 증명
- **프로파일별 관리**: 환경별, 역할별 계정 분리
- **보안**: 하드코딩 대신 파일로 관리

---

## Access Key 생성 방법

### Step 1: AWS Console 로그인

```
https://console.aws.amazon.com/
```

1. AWS 계정으로 로그인
2. 우측 상단 계정 이름 클릭
3. **Security credentials** 선택

또는 직접 IAM으로 이동:
```
https://console.aws.amazon.com/iam/
```

---

### Step 2: IAM User 선택

#### 방법 A: 본인 계정 (Root 사용자)

⚠️ **권장하지 않음**: Root 사용자는 모든 권한을 가지므로 위험

**대신 IAM 사용자 생성:**

1. **IAM Dashboard** → **Users** → **Add users**

2. **User name 입력**:
   ```
   topzone-k8s-admin
   ```

3. **Access type 선택**:
   - ✅ **Programmatic access** (Access Key ID/Secret Access Key)
   - ⬜ AWS Management Console access (선택 사항)

4. **Next: Permissions** 클릭

---

#### 방법 B: 기존 IAM User 사용

1. **IAM** → **Users**
2. 사용할 사용자 선택 (예: `topzone-k8s-admin`)
3. **Security credentials** 탭 클릭

---

### Step 3: 권한 설정

#### 관리자 권한 (topzone-k8s-admin)

**정책 연결:**
- ✅ **AdministratorAccess** (전체 권한)

또는 최소 권한 원칙:
- AmazonEKSClusterPolicy
- AmazonEKSWorkerNodePolicy
- AmazonEKS_CNI_Policy
- AmazonEC2ContainerRegistryPowerUser
- AmazonVPCFullAccess

---

#### 개발자 권한 (topzone-k8s-dev)

**제한된 권한:**
- AmazonEKSViewPolicy
- AmazonEC2ReadOnlyAccess
- AmazonS3ReadOnlyAccess

---

### Step 4: Access Key 생성

1. **Security credentials** 탭에서
2. **Access keys** 섹션
3. **Create access key** 버튼 클릭

4. **Use case 선택**:
   - ✅ Command Line Interface (CLI)
   - Other 선택 후 "I understand..." 체크

5. **Next** 클릭

6. **Description tag** (선택):
   ```
   kubernetes-cluster-management
   ```

7. **Create access key** 클릭

---

### Step 5: Access Key 복사

⚠️ **중요**: Secret Access Key는 생성 시 한 번만 표시됩니다!

**표시되는 정보:**
```
Access key ID: AKIAIOSFODNN7EXAMPLE
Secret access key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

**즉시 안전한 곳에 저장:**
```bash
# 임시 메모장에 저장
Access Key ID: AKIAIOSFODNN7EXAMPLE
Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Created: 2025-11-14
User: topzone-k8s-admin
Purpose: EKS Cluster Management
```

**CSV 다운로드**: "Download .csv file" 버튼 클릭 (권장)

---

## credentials 파일 설정

### 방법 1: AWS CLI로 자동 설정 (가장 쉬움)

```bash
# default 프로파일 설정
aws configure
# AWS Access Key ID [None]: AKIAXXXXXXXXXXXXXXXX
# AWS Secret Access Key [None]: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# Default region name [None]: ap-northeast-2
# Default output format [None]: json

# topzone-k8s 프로파일 설정
aws configure --profile topzone-k8s
# AWS Access Key ID [None]: AKIAXXXXXXXXXXXXXXXX
# AWS Secret Access Key [None]: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# Default region name [None]: ap-northeast-2
# Default output format [None]: json

# topzone-k8s-admin 프로파일 설정
aws configure --profile topzone-k8s-admin

# topzone-k8s-dev 프로파일 설정
aws configure --profile topzone-k8s-dev
```

---

### 방법 2: 파일 직접 편집

```bash
# credentials 파일 열기
vi ~/.aws/credentials

# 또는 프로젝트 파일
vi /Users/codesonic/Documents/Workspace/KUBE/tz-eks-main/resources/credentials
```

**내용 입력:**
```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[topzone-k8s]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[topzone-k8s-admin]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[topzone-k8s-dev]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

**저장**: `:wq` (vi) 또는 `Ctrl+X` (nano)

---

### 방법 3: 자동화 스크립트 사용

아래 자동 설정 스크립트 섹션 참조

---

## 프로파일별 설정 전략

### 전략 1: 단일 계정 사용 (간단함)

**모든 프로파일에 동일한 Access Key 사용:**

```ini
[default]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

[topzone-k8s]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX  # ← 동일
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

[topzone-k8s-admin]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX  # ← 동일
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

[topzone-k8s-dev]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX  # ← 동일
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**장점:**
- 설정 간단
- 관리 용이

**단점:**
- 권한 분리 안 됨
- 보안 취약

---

### 전략 2: 역할별 계정 분리 (권장)

**각 프로파일마다 다른 IAM User 사용:**

```ini
[default]
# 기본 사용자 (제한된 권한)
aws_access_key_id = AKIA_DEFAULT_USER
aws_secret_access_key = xxxxxxxxxx_DEFAULT

[topzone-k8s]
# 클러스터 관리 전용
aws_access_key_id = AKIA_CLUSTER_ADMIN
aws_secret_access_key = xxxxxxxxxx_CLUSTER

[topzone-k8s-admin]
# 전체 관리자 권한
aws_access_key_id = AKIA_ADMIN_USER
aws_secret_access_key = xxxxxxxxxx_ADMIN

[topzone-k8s-dev]
# 개발자 제한 권한
aws_access_key_id = AKIA_DEV_USER
aws_secret_access_key = xxxxxxxxxx_DEV
```

**장점:**
- 보안 강화
- 권한 분리
- 감사 추적 용이

**단점:**
- 설정 복잡
- 여러 IAM User 생성 필요

---

### 전략 3: Assume Role 사용 (고급)

**하나의 기본 계정으로 여러 Role 전환:**

```ini
# credentials 파일
[default]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

```ini
# config 파일
[profile topzone-k8s-admin]
source_profile = default
role_arn = arn:aws:iam::192496985564:role/AdminRole

[profile topzone-k8s-dev]
source_profile = default
role_arn = arn:aws:iam::192496985564:role/DeveloperRole
```

---

## 자동 설정 스크립트

### 대화형 설정 스크립트

```bash
#!/bin/bash

echo "=========================================="
echo "AWS Credentials 자동 설정"
echo "=========================================="
echo ""

PROJECT_DIR="/Users/codesonic/Documents/Workspace/KUBE/tz-eks-main"
CRED_FILE="${PROJECT_DIR}/resources/credentials"

# 파일 백업
if [ -f "$CRED_FILE" ]; then
  cp "$CRED_FILE" "${CRED_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
  echo "✅ 기존 파일 백업 완료"
fi

echo ""
echo "AWS Access Key를 입력하세요."
echo "IAM User의 Security credentials에서 생성할 수 있습니다."
echo ""

# 프로파일별 설정
declare -A profiles
profiles[default]="기본 프로파일"
profiles[topzone-k8s]="클러스터 관리용"
profiles[topzone-k8s-admin]="관리자 권한"
profiles[topzone-k8s-dev]="개발자 권한"

# 단일 계정 사용 여부
echo "모든 프로파일에 동일한 Access Key를 사용하시겠습니까?"
read -p "(y/n): " USE_SINGLE

if [[ "$USE_SINGLE" == "y" ]]; then
  echo ""
  read -p "AWS Access Key ID: " SINGLE_KEY_ID
  read -sp "AWS Secret Access Key: " SINGLE_SECRET_KEY
  echo ""
  
  # 파일 생성
  > "$CRED_FILE"
  
  for profile in "${!profiles[@]}"; do
    cat >> "$CRED_FILE" <<EOF
[$profile]
aws_access_key_id = $SINGLE_KEY_ID
aws_secret_access_key = $SINGLE_SECRET_KEY

EOF
  done
  
  echo "✅ 모든 프로파일에 동일한 Access Key 설정 완료"
  
else
  # 프로파일별 개별 설정
  > "$CRED_FILE"
  
  for profile in default topzone-k8s topzone-k8s-admin topzone-k8s-dev; do
    echo ""
    echo "[$profile] - ${profiles[$profile]}"
    read -p "  AWS Access Key ID: " KEY_ID
    read -sp "  AWS Secret Access Key: " SECRET_KEY
    echo ""
    
    cat >> "$CRED_FILE" <<EOF
[$profile]
aws_access_key_id = $KEY_ID
aws_secret_access_key = $SECRET_KEY

EOF
  done
  
  echo "✅ 프로파일별 개별 설정 완료"
fi

# 파일 권한 설정
chmod 600 "$CRED_FILE"
echo "✅ 파일 권한 설정 완료 (600)"

echo ""
echo "=========================================="
echo "설정 완료!"
echo "=========================================="
echo ""
echo "📁 파일 위치: $CRED_FILE"
echo ""
echo "🔍 확인:"
cat "$CRED_FILE" | sed 's/aws_secret_access_key = .*/aws_secret_access_key = ********/' 
echo ""
echo "✅ 테스트:"
echo "  aws sts get-caller-identity"
echo "  aws sts get-caller-identity --profile topzone-k8s"
echo ""
```

**저장 및 실행:**
```bash
cd /Users/codesonic/Documents/Workspace/KUBE/tz-eks-main

# 스크립트 저장
cat > setup_credentials.sh <<'EOF'
[위 스크립트 내용]
EOF

# 실행 권한 부여
chmod +x setup_credentials.sh

# 실행
./setup_credentials.sh
```

---

### 간단 버전 스크립트

```bash
#!/bin/bash

echo "AWS Credentials 빠른 설정"
echo ""

CRED_FILE="/Users/codesonic/Documents/Workspace/KUBE/tz-eks-main/resources/credentials"

read -p "AWS Access Key ID: " KEY_ID
read -sp "AWS Secret Access Key: " SECRET_KEY
echo ""

cat > "$CRED_FILE" <<EOF
[default]
aws_access_key_id = $KEY_ID
aws_secret_access_key = $SECRET_KEY

[topzone-k8s]
aws_access_key_id = $KEY_ID
aws_secret_access_key = $SECRET_KEY

[topzone-k8s-admin]
aws_access_key_id = $KEY_ID
aws_secret_access_key = $SECRET_KEY

[topzone-k8s-dev]
aws_access_key_id = $KEY_ID
aws_secret_access_key = $SECRET_KEY
EOF

chmod 600 "$CRED_FILE"

echo "✅ 설정 완료!"
echo "테스트: aws sts get-caller-identity"
```

---

## 보안 권장 사항

### 1. 파일 권한 설정

```bash
# credentials 파일은 소유자만 읽기/쓰기 가능
chmod 600 ~/.aws/credentials
chmod 600 /Users/codesonic/Documents/Workspace/KUBE/tz-eks-main/resources/credentials

# 디렉토리 권한
chmod 700 ~/.aws
```

---

### 2. .gitignore에 추가

```bash
# .gitignore 파일에 추가
echo "resources/credentials" >> .gitignore
echo "resources/config" >> .gitignore
echo "**/.aws/" >> .gitignore
```

---

### 3. Access Key 로테이션

```bash
# 정기적으로 Access Key 교체 (90일마다 권장)

# 1. 새 Access Key 생성
# 2. credentials 파일 업데이트
# 3. 테스트
# 4. 기존 Access Key 비활성화
# 5. 확인 후 기존 Key 삭제
```

---

### 4. MFA 활성화

**IAM User에 MFA 설정:**
1. IAM → Users → Security credentials
2. Assigned MFA device → Manage
3. Virtual MFA device 선택
4. Google Authenticator 등 앱으로 QR 스캔

---

### 5. 최소 권한 원칙

**필요한 권한만 부여:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*",
        "ec2:Describe*",
        "iam:ListRoles"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 테스트 및 검증

### 1. 기본 테스트

```bash
# Identity 확인
aws sts get-caller-identity

# 출력 예시:
# {
#     "UserId": "AIDAXXXXXXXXXXXXXXXX",
#     "Account": "192496985564",
#     "Arn": "arn:aws:iam::192496985564:user/topzone-k8s-admin"
# }
```

---

### 2. 프로파일별 테스트

```bash
# default 프로파일
aws sts get-caller-identity

# topzone-k8s 프로파일
aws sts get-caller-identity --profile topzone-k8s

# topzone-k8s-admin 프로파일
aws sts get-caller-identity --profile topzone-k8s-admin

# topzone-k8s-dev 프로파일
aws sts get-caller-identity --profile topzone-k8s-dev
```

---

### 3. 권한 테스트

```bash
# EKS 클러스터 목록 조회
aws eks list-clusters --region ap-northeast-2

# S3 버킷 목록
aws s3 ls

# EC2 인스턴스 목록
aws ec2 describe-instances --region ap-northeast-2
```

---

### 4. 설정 확인

```bash
# 현재 설정 확인
aws configure list

# 특정 프로파일 설정 확인
aws configure list --profile topzone-k8s

# credentials 파일 확인 (Secret Key는 숨김 처리)
cat ~/.aws/credentials | sed 's/aws_secret_access_key = .*/aws_secret_access_key = ********/'
```

---

## 트러블슈팅

### 문제 1: Access Key가 작동하지 않음

**증상:**
```
An error occurred (InvalidClientTokenId) when calling the GetCallerIdentity operation
```

**해결:**
1. Access Key ID 확인 (공백, 오타)
2. Secret Access Key 확인
3. IAM User가 활성화되어 있는지 확인
4. AWS Console에서 Access Key 상태 확인

---

### 문제 2: 권한 부족

**증상:**
```
An error occurred (AccessDenied) when calling the ListClusters operation
```

**해결:**
1. IAM User의 정책 확인
2. 필요한 권한 추가
3. 정책 적용까지 몇 분 대기

---

### 문제 3: 파일을 찾을 수 없음

**증상:**
```
Unable to locate credentials
```

**해결:**
```bash
# 파일 존재 확인
ls -la ~/.aws/credentials

# 파일 생성
mkdir -p ~/.aws
touch ~/.aws/credentials
chmod 600 ~/.aws/credentials
```

---

### 문제 4: Profile not found

**증상:**
```
The config profile (topzone-k8s) could not be found
```

**해결:**
```bash
# credentials 파일 확인
cat ~/.aws/credentials

# 프로파일 이름 확인 (대소문자 구분)
# [topzone-k8s] (O)
# [topzone-K8s] (X)
```

---

## 빠른 참조

### 필수 명령어

```bash
# 설정
aws configure
aws configure --profile topzone-k8s

# 확인
aws sts get-caller-identity
aws configure list

# 프로파일 사용
aws s3 ls --profile topzone-k8s
export AWS_PROFILE=topzone-k8s

# 파일 위치
~/.aws/credentials
/Users/codesonic/Documents/Workspace/KUBE/tz-eks-main/resources/credentials
```

---

### Access Key 형식

```
Access Key ID 형식:
- 20자리
- AKIA로 시작 (일반적)
- 예: AKIAIOSFODNN7EXAMPLE

Secret Access Key 형식:
- 40자리
- 대소문자, 숫자, 특수문자 혼합
- 예: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

---

## 체크리스트

설정 전:
- [ ] AWS 계정 생성 완료
- [ ] IAM User 생성 완료
- [ ] 적절한 권한 부여 완료
- [ ] Access Key 생성 완료
- [ ] Access Key 안전하게 저장 완료

설정 후:
- [ ] credentials 파일 생성 완료
- [ ] 파일 권한 설정 (600) 완료
- [ ] `aws sts get-caller-identity` 테스트 성공
- [ ] 프로파일별 테스트 성공
- [ ] .gitignore에 추가 완료

---

## 참고 자료

### AWS 공식 문서
- [IAM Users](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html)
- [Access Keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)
- [AWS CLI Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)

### 프로젝트 파일
```
tz-eks-main/resources/
├── credentials         # ← 이 파일 설정
├── config             # AWS CLI 설정
└── project            # 프로젝트 메타데이터
```

---

**작성일**: 2025년 11월 14일  
**프로젝트**: KUBE (tz-eks-main)  
**파일**: resources/credentials

