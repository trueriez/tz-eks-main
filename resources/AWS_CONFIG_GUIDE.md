# AWS Config 파일 구성 요소 가이드

## 📋 목차
1. [파일 개요](#파일-개요)
2. [config 파일 구조](#config-파일-구조)
3. [credentials 파일 구조](#credentials-파일-구조)
4. [프로파일 설정](#프로파일-설정)
5. [프로젝트에서의 사용](#프로젝트에서의-사용)
6. [설정 방법](#설정-방법)
7. [트러블슈팅](#트러블슈팅)

---

## 파일 개요

### 파일 위치
```
tz-eks-main/resources/
├── config          # AWS CLI 설정 파일 (리전, 출력 형식, Role 등)
├── credentials     # AWS 인증 정보 (Access Key, Secret Key)
└── project         # 프로젝트 설정 (도메인, 비밀번호 등)
```

### 역할
- **config**: AWS CLI의 동작 방식 설정 (리전, 출력 형식, 역할 등)
- **credentials**: AWS 인증 정보 (Access Key ID, Secret Access Key)

---

## config 파일 구조

### 현재 설정

```ini
[default]
region = ap-northeast-2
output = json

[profile topzone-k8s]
region = ap-northeast-2
output = json

[profile default_admin_role]
source_profile=default
role_arn=arn:aws:iam::0:role/AdminRole
```

---

### 구성 요소 상세 설명

#### 1. [default] 프로파일

```ini
[default]
region = ap-northeast-2
output = json
```

| 항목 | 값 | 설명 |
|------|-----|------|
| **[default]** | - | 기본 프로파일 (프로파일 지정 없이 AWS CLI 사용 시 적용) |
| **region** | `ap-northeast-2` | AWS 리전 (서울) |
| **output** | `json` | AWS CLI 출력 형식 (json, text, table 중 선택) |

**사용 예시:**
```bash
# default 프로파일 사용 (자동)
aws s3 ls

# 명시적 프로파일 지정
aws s3 ls --profile default
```

**리전 코드:**
- `ap-northeast-2`: 서울 (Seoul)
- `ap-northeast-1`: 도쿄 (Tokyo)
- `us-east-1`: 버지니아 북부 (N. Virginia)
- `us-west-2`: 오레곤 (Oregon)

---

#### 2. [profile topzone-k8s] 프로파일

```ini
[profile topzone-k8s]
region = ap-northeast-2
output = json
```

| 항목 | 값 | 설명 |
|------|-----|------|
| **[profile topzone-k8s]** | - | 사용자 정의 프로파일 (프로젝트 전용) |
| **region** | `ap-northeast-2` | AWS 리전 (서울) |
| **output** | `json` | 출력 형식 |

**사용 예시:**
```bash
# topzone-k8s 프로파일 사용
aws s3 ls --profile topzone-k8s

# 환경 변수로 프로파일 설정
export AWS_PROFILE=topzone-k8s
aws s3 ls
```

**용도:**
- EKS 클러스터 관리
- 프로젝트별 리소스 격리
- 권한 분리

---

#### 3. [profile default_admin_role] 프로파일 (Role Assumption)

```ini
[profile default_admin_role]
source_profile=default
role_arn=arn:aws:iam::0:role/AdminRole
```

| 항목 | 값 | 설명 |
|------|-----|------|
| **[profile default_admin_role]** | - | IAM Role을 사용하는 프로파일 |
| **source_profile** | `default` | 인증에 사용할 기본 프로파일 |
| **role_arn** | `arn:aws:iam::0:role/AdminRole` | 전환할 IAM Role의 ARN |

**⚠️ 주의**: 
- `role_arn`의 `0`은 실제 AWS Account ID로 변경해야 합니다!
- 예: `arn:aws:iam::192496985564:role/AdminRole`

**사용 예시:**
```bash
# AdminRole로 전환하여 명령 실행
aws s3 ls --profile default_admin_role

# STS로 Role 전환 확인
aws sts get-caller-identity --profile default_admin_role
```

**Role Assumption이란?**
- IAM 사용자가 임시로 다른 Role의 권한을 사용하는 것
- MFA (Multi-Factor Authentication) 요구 가능
- 시간 제한이 있는 임시 자격 증명 사용

---

## credentials 파일 구조

### 현재 설정

```ini
[default]
aws_access_key_id = xxxxxxxxxxx
aws_secret_access_key = xxxxxxxxxxx

[topzone-k8s]
aws_access_key_id = xxxxxxxxxxx
aws_secret_access_key = xxxxxxxxxxx

[topzone-k8s-admin]
aws_access_key_id = xxxxxxxxxxx
aws_secret_access_key = xxxxxxxxxxx

[topzone-k8s-dev]
aws_access_key_id = xxxxxxxxxxx
aws_secret_access_key = xxxxxxxxxxx
```

---

### 구성 요소 상세 설명

#### 1. [default] 자격 증명

```ini
[default]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

| 항목 | 형식 | 설명 |
|------|------|------|
| **aws_access_key_id** | AKIA... (20자) | AWS Access Key ID |
| **aws_secret_access_key** | (40자) | AWS Secret Access Key |

**생성 방법:**
1. AWS Console → IAM → Users → 사용자 선택
2. Security credentials 탭
3. "Create access key" 클릭
4. Access Key ID와 Secret Key 복사

---

#### 2. [topzone-k8s] 자격 증명

```ini
[topzone-k8s]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**용도:**
- EKS 클러스터 생성 및 관리
- Kubernetes 리소스 접근
- Terraform 실행

---

#### 3. [topzone-k8s-admin] 자격 증명

```ini
[topzone-k8s-admin]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**용도:**
- 관리자 권한이 필요한 작업
- IAM 정책 변경
- 민감한 리소스 관리

---

#### 4. [topzone-k8s-dev] 자격 증명

```ini
[topzone-k8s-dev]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**용도:**
- 개발자 계정
- 제한된 권한
- 개발/테스트 환경

---

## 프로파일 설정

### 프로파일과 자격 증명의 관계

```
config 파일                     credentials 파일
-------------------------------------------------
[default]                  ←→  [default]
├─ region                       ├─ aws_access_key_id
└─ output                       └─ aws_secret_access_key

[profile topzone-k8s]      ←→  [topzone-k8s]
├─ region                       ├─ aws_access_key_id
└─ output                       └─ aws_secret_access_key

[profile default_admin_role]    [default] 사용
├─ source_profile=default       (Role 전환)
└─ role_arn=...
```

---

### 프로파일 선택 우선순위

1. **명령줄 옵션**: `--profile` 플래그
2. **환경 변수**: `AWS_PROFILE`
3. **기본값**: `default` 프로파일

**예시:**
```bash
# 1. 명령줄 옵션 (최우선)
aws s3 ls --profile topzone-k8s

# 2. 환경 변수
export AWS_PROFILE=topzone-k8s
aws s3 ls

# 3. 기본값 (default)
aws s3 ls
```

---

## 프로젝트에서의 사용

### 1. Docker 컨테이너로 복사

```bash
# tz-local/docker/init2.sh
sudo mkdir -p /home/topzone/.aws
sudo cp -Rf /topzone/resources/config /home/topzone/.aws/config
sudo cp -Rf /topzone/resources/credentials /home/topzone/.aws/credentials
sudo cp -Rf /topzone/resources/project /home/topzone/.aws/project
sudo chown -Rf topzone:topzone /home/topzone/.aws

sudo rm -Rf /root/.aws
sudo cp -Rf /home/topzone/.aws /root/.aws
```

**경로:**
- 호스트: `tz-eks-main/resources/config`
- 컨테이너: `/root/.aws/config`
- 컨테이너: `/home/topzone/.aws/config`

---

### 2. 스크립트에서 프로파일 읽기

```bash
# prop 함수로 설정 읽기
function prop {
  key="${2}="
  file="/root/.aws/${1}"
  rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g')
  echo "$rslt"
}

# config 파일에서 리전 읽기
aws_region=$(prop 'config' 'region')
# → "ap-northeast-2"

# credentials 파일에서 Access Key 읽기
aws_access_key_id=$(prop 'credentials' 'aws_access_key_id')
# → "AKIAXXXXXXXXXXXXXXXX"
```

---

### 3. Terraform에서 프로파일 사용

```hcl
# provider.tf
provider "aws" {
  region  = "ap-northeast-2"
  profile = "topzone-k8s"
}
```

---

### 4. kubectl 설정

```yaml
# kubeconfig 파일
apiVersion: v1
kind: Config
users:
- name: topzone-k8s
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
        - eks
        - get-token
        - --cluster-name
        - topzone-k8s
        - --region
        - ap-northeast-2
      env:
        - name: AWS_PROFILE
          value: topzone-k8s
```

---

## 설정 방법

### 1. AWS CLI로 자동 설정

```bash
# 대화형 설정
aws configure

# 입력 항목:
# AWS Access Key ID [None]: AKIAXXXXXXXXXXXXXXXX
# AWS Secret Access Key [None]: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# Default region name [None]: ap-northeast-2
# Default output format [None]: json

# 특정 프로파일 설정
aws configure --profile topzone-k8s
```

---

### 2. 수동으로 파일 편집

#### config 파일 생성

```bash
cat > ~/.aws/config <<EOF
[default]
region = ap-northeast-2
output = json

[profile topzone-k8s]
region = ap-northeast-2
output = json
EOF
```

#### credentials 파일 생성

```bash
cat > ~/.aws/credentials <<EOF
[default]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

[topzone-k8s]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF

# 파일 권한 설정 (보안)
chmod 600 ~/.aws/credentials
```

---

### 3. 프로젝트 파일 업데이트

#### config 파일 수정

```bash
cd /Users/codesonic/Documents/Workspace/KUBE/tz-eks-main

# Account ID로 Role ARN 수정
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

sed -i.bak "s|role_arn=arn:aws:iam::0:role/AdminRole|role_arn=arn:aws:iam::${ACCOUNT_ID}:role/AdminRole|" resources/config

cat resources/config
```

#### credentials 파일 수정

```bash
# 실제 Access Key로 변경
vi resources/credentials

# 또는 AWS CLI로 생성한 것 복사
cp ~/.aws/credentials resources/credentials
```

---

## 출력 형식 (output)

### 지원되는 형식

#### 1. JSON (기본값)

```bash
output = json
```

**출력 예시:**
```json
{
    "Buckets": [
        {
            "Name": "my-bucket",
            "CreationDate": "2024-01-01T00:00:00+00:00"
        }
    ]
}
```

**장점:**
- 프로그래밍 방식 파싱 용이
- jq 도구와 함께 사용 가능
- 구조화된 데이터

---

#### 2. Table

```bash
output = table
```

**출력 예시:**
```
----------------------------------------------------------
|                       ListBuckets                      |
+---------------------------+----------------------------+
|  CreationDate             |  Name                      |
+---------------------------+----------------------------+
|  2024-01-01T00:00:00+00:00|  my-bucket                |
+---------------------------+----------------------------+
```

**장점:**
- 사람이 읽기 쉬움
- 빠른 확인

---

#### 3. Text

```bash
output = text
```

**출력 예시:**
```
my-bucket       2024-01-01T00:00:00+00:00
```

**장점:**
- grep, awk와 함께 사용 용이
- 스크립트 처리

---

## 환경 변수

### AWS CLI가 인식하는 환경 변수

```bash
# 프로파일 지정
export AWS_PROFILE=topzone-k8s

# 직접 인증 정보 지정
export AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
export AWS_DEFAULT_REGION=ap-northeast-2

# Session Token (임시 자격 증명)
export AWS_SESSION_TOKEN=xxxxx...

# Config/Credentials 파일 위치 변경
export AWS_CONFIG_FILE=/custom/path/config
export AWS_SHARED_CREDENTIALS_FILE=/custom/path/credentials
```

---

### 우선순위

1. **환경 변수** (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
2. **credentials 파일** (~/.aws/credentials)
3. **ECS Task Role** (ECS 컨테이너)
4. **EC2 Instance Profile** (EC2 인스턴스)

---

## 프로파일 확인

### 현재 프로파일 확인

```bash
# 현재 사용 중인 프로파일 확인
echo $AWS_PROFILE

# 현재 인증 정보로 Identity 확인
aws sts get-caller-identity

# 출력:
# {
#     "UserId": "AIDAXXXXXXXXXXXXXXXX",
#     "Account": "192496985564",
#     "Arn": "arn:aws:iam::192496985564:user/username"
# }
```

---

### 모든 프로파일 목록

```bash
# config 파일의 프로파일 목록
grep '\[profile' ~/.aws/config | sed 's/\[profile //' | sed 's/\]//'

# credentials 파일의 프로파일 목록
grep '\[' ~/.aws/credentials | tr -d '[]'
```

---

### 특정 프로파일로 명령 실행

```bash
# topzone-k8s 프로파일 사용
aws s3 ls --profile topzone-k8s
aws ec2 describe-instances --profile topzone-k8s
aws eks list-clusters --profile topzone-k8s --region ap-northeast-2

# 여러 명령에 프로파일 적용
export AWS_PROFILE=topzone-k8s
aws s3 ls
aws ec2 describe-instances
unset AWS_PROFILE  # 해제
```

---

## 트러블슈팅

### 문제 1: Profile not found

**증상:**
```
The config profile (topzone-k8s) could not be found
```

**해결:**
```bash
# config 파일 확인
cat ~/.aws/config

# 프로파일 형식 확인 ([profile xxx] vs [xxx])
# config: [profile topzone-k8s]
# credentials: [topzone-k8s]
```

---

### 문제 2: Invalid credentials

**증상:**
```
An error occurred (InvalidClientTokenId) when calling the GetCallerIdentity operation
```

**해결:**
```bash
# Access Key 재생성
# AWS Console → IAM → Users → Security credentials → Create access key

# credentials 파일 업데이트
aws configure --profile topzone-k8s
```

---

### 문제 3: Region not set

**증상:**
```
You must specify a region
```

**해결:**
```bash
# config 파일에 region 추가
aws configure set region ap-northeast-2 --profile topzone-k8s

# 또는 환경 변수 설정
export AWS_DEFAULT_REGION=ap-northeast-2
```

---

### 문제 4: Permission denied (파일 권한)

**증상:**
```
WARNING: Your credentials file is publicly accessible
```

**해결:**
```bash
# 파일 권한 수정
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config
```

---

### 문제 5: Role cannot be assumed

**증상:**
```
An error occurred (AccessDenied) when calling the AssumeRole operation
```

**해결:**
1. **Role ARN 확인**:
   ```bash
   # 0을 실제 Account ID로 변경
   role_arn=arn:aws:iam::192496985564:role/AdminRole
   ```

2. **Trust Relationship 확인** (AWS Console → IAM → Roles → Trust relationships)
3. **source_profile의 권한 확인**

---

## 보안 모범 사례

### 1. 파일 권한

```bash
# AWS 설정 파일 권한 설정
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config
chmod 700 ~/.aws
```

---

### 2. Access Key 로테이션

```bash
# 정기적으로 Access Key 변경 (90일마다 권장)
# 1. 새 Access Key 생성
# 2. 새 Key로 테스트
# 3. 기존 Key 비활성화
# 4. 기존 Key 삭제
```

---

### 3. .gitignore 설정

```bash
# .gitignore에 추가 (Git에 커밋하지 않기)
resources/credentials
resources/config
**/.aws/
*.pem
*.key
```

---

### 4. MFA 사용

```bash
# MFA가 필요한 Role 설정
[profile mfa-role]
source_profile = default
role_arn = arn:aws:iam::192496985564:role/AdminRole
mfa_serial = arn:aws:iam::192496985564:mfa/username
```

---

## 빠른 참조

### 필수 명령어

```bash
# 설정 확인
aws configure list

# 현재 Identity 확인
aws sts get-caller-identity

# 프로파일 지정
aws s3 ls --profile topzone-k8s

# 환경 변수 설정
export AWS_PROFILE=topzone-k8s

# 설정 파일 위치
~/.aws/config
~/.aws/credentials
```

---

### 파일 구조 요약

```
~/.aws/
├── config              # 프로파일 설정 (region, output, role)
├── credentials         # 인증 정보 (access key, secret key)
└── cli/                # AWS CLI 캐시

프로젝트:
tz-eks-main/resources/
├── config              # 프로젝트용 config
├── credentials         # 프로젝트용 credentials
└── project             # 프로젝트 메타데이터
```

---

## 체크리스트

설정 전 확인:

- [ ] AWS Account 생성 완료
- [ ] IAM 사용자 생성 완료
- [ ] Access Key 생성 완료
- [ ] 적절한 IAM 권한 부여 완료
- [ ] config 파일 생성 완료
- [ ] credentials 파일 생성 완료
- [ ] 파일 권한 설정 완료 (600)
- [ ] `aws sts get-caller-identity` 테스트 성공

---

## 참고 자료

### AWS 공식 문서
- [AWS CLI Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [Named Profiles](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html)
- [Assume Role](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html)

### 관련 파일
```
tz-eks-main/
├── resources/
│   ├── config          ← 이 파일
│   ├── credentials     ← 인증 정보
│   └── project         ← 프로젝트 설정
└── tz-local/
    └── docker/
        └── init2.sh    ← AWS 설정 복사 스크립트
```

---

**작성일**: 2025년 11월 14일  
**프로젝트**: KUBE (tz-eks-main)  
**파일**: resources/config, resources/credentials

