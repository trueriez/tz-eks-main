# IAM 권한 및 정책 설정 가이드

## 📋 목차
1. [IAM 개요](#iam-개요)
2. [IAM User 생성 방법](#iam-user-생성-방법)
3. [IAM 정책 유형](#iam-정책-유형)
4. [권한 부여 방법](#권한-부여-방법)
5. [프로젝트 필수 권한](#프로젝트-필수-권한)
6. [IAM Role 설정](#iam-role-설정)
7. [보안 모범 사례](#보안-모범-사례)
8. [자동화 스크립트](#자동화-스크립트)

---

## IAM 개요

### IAM (Identity and Access Management)이란?

**AWS IAM**은 AWS 리소스에 대한 접근을 안전하게 제어하는 서비스입니다.

### 주요 구성 요소

```
IAM
├── Users (사용자)
│   ├── Access Keys (프로그래밍 방식 접근)
│   └── Passwords (Console 접근)
├── Groups (그룹)
│   └── Multiple Users
├── Roles (역할)
│   ├── EC2 Instance Profile
│   ├── EKS Service Role
│   └── Cross-Account Access
└── Policies (정책)
    ├── Managed Policies (AWS/Customer)
    └── Inline Policies
```

---

## IAM User 생성 방법

### 방법 1: AWS Console (GUI) ⭐ 가장 쉬움

#### Step 1: IAM Dashboard 접속

1. AWS Console 로그인: https://console.aws.amazon.com/
2. 검색창에 "IAM" 입력
3. IAM 서비스 클릭

#### Step 2: Users 메뉴 선택

1. 좌측 메뉴에서 **"Users"** 클릭
2. **"Add users"** 버튼 클릭

#### Step 3: User 기본 정보 입력

**User name:**
```
topzone-k8s-admin
```

**Access type 선택:**
- ✅ **Programmatic access** (CLI/SDK/API용)
  - Access key ID & Secret access key 생성
  - EKS 클러스터 관리에 필요
  
- ⬜ **AWS Management Console access** (선택 사항)
  - Web Console 로그인용
  - 비밀번호 설정 필요

#### Step 4: 권한 설정

##### 옵션 A: 관리자 권한 (간단함)

1. **"Attach existing policies directly"** 선택
2. **AdministratorAccess** 검색 및 선택
3. Next 클릭

##### 옵션 B: EKS 관리 권한 (최소 권한)

다음 정책들을 선택:
- AmazonEKSClusterPolicy
- AmazonEKSWorkerNodePolicy
- AmazonEKS_CNI_Policy
- AmazonEC2FullAccess
- AmazonVPCFullAccess
- IAMFullAccess

#### Step 5: Tags 추가 (선택 사항)

```
Key: Environment    Value: production
Key: Project        Value: topzone-k8s
```

#### Step 6: 검토 및 생성

1. 설정 검토
2. **"Create user"** 클릭

#### Step 7: Access Key 저장

⚠️ **중요**: Secret access key는 이 화면에서만 확인 가능!

```
Access key ID: AKIAIOSFODNN7EXAMPLE
Secret access key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

**저장 방법:**
1. **Download .csv** 클릭 (권장)
2. 또는 복사하여 안전한 곳에 저장

---

### 방법 2: AWS CLI

```bash
# 1. User 생성
aws iam create-user --user-name topzone-k8s-admin

# 2. Access Key 생성
aws iam create-access-key --user-name topzone-k8s-admin

# 3. 관리자 정책 연결
aws iam attach-user-policy \
  --user-name topzone-k8s-admin \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# 4. User 확인
aws iam get-user --user-name topzone-k8s-admin

# 5. 정책 확인
aws iam list-attached-user-policies --user-name topzone-k8s-admin
```

---

### 방법 3: Terraform (IaC)

```hcl
# iam_users.tf

resource "aws_iam_user" "eks_admin" {
  name = "topzone-k8s-admin"
  path = "/system/"

  tags = {
    Environment = "production"
    Project     = "topzone-k8s"
  }
}

resource "aws_iam_access_key" "eks_admin_key" {
  user = aws_iam_user.eks_admin.name
}

resource "aws_iam_user_policy_attachment" "eks_admin_policy" {
  user       = aws_iam_user.eks_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "access_key_id" {
  value = aws_iam_access_key.eks_admin_key.id
}

output "secret_access_key" {
  value     = aws_iam_access_key.eks_admin_key.secret
  sensitive = true
}
```

---

## IAM 정책 유형

### 1. AWS Managed Policies (AWS 관리형)

AWS가 생성하고 관리하는 재사용 가능한 정책

#### 전체 관리자 권한
```
AdministratorAccess
- 모든 AWS 서비스 전체 권한
- arn:aws:iam::aws:policy/AdministratorAccess
```

#### EKS 관련 정책
```
AmazonEKSClusterPolicy           # EKS 클러스터 관리
AmazonEKSWorkerNodePolicy        # Worker Node 관리
AmazonEKS_CNI_Policy             # VPC CNI Plugin
AmazonEKSServicePolicy           # EKS 서비스 권한
```

#### EC2 관련 정책
```
AmazonEC2FullAccess              # EC2 완전 제어
AmazonEC2ReadOnlyAccess          # EC2 읽기 전용
```

#### VPC 관련 정책
```
AmazonVPCFullAccess              # VPC 완전 제어
```

#### IAM 관련 정책
```
IAMFullAccess                    # IAM 완전 제어
IAMReadOnlyAccess                # IAM 읽기 전용
```

---

### 2. Customer Managed Policies (고객 관리형)

사용자가 직접 생성하는 정책 - 세밀한 권한 제어 가능

#### JSON 예시
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "eks:CreateCluster",
        "eks:DeleteCluster"
      ],
      "Resource": "*"
    }
  ]
}
```

---

### 3. Inline Policies (인라인 정책)

특정 User/Role/Group에만 직접 연결 - 일회성 권한 부여

---

## 권한 부여 방법

### 방법 1: AWS Console에서 정책 연결

1. IAM → Users → 사용자 선택
2. **Permissions** 탭
3. **Add permissions** 버튼
4. **Attach existing policies directly** 선택
5. 정책 검색 및 선택
6. **Add permissions** 클릭

---

### 방법 2: AWS CLI로 정책 연결

```bash
# AWS Managed Policy 연결
aws iam attach-user-policy \
  --user-name topzone-k8s-admin \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# 여러 정책 연결
aws iam attach-user-policy \
  --user-name topzone-k8s-admin \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

aws iam attach-user-policy \
  --user-name topzone-k8s-admin \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess
```

---

### 방법 3: 그룹을 통한 권한 관리 (권장 ⭐)

```bash
# 1. 그룹 생성
aws iam create-group --group-name EKS-Administrators

# 2. 그룹에 정책 연결
aws iam attach-group-policy \
  --group-name EKS-Administrators \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# 3. User를 그룹에 추가
aws iam add-user-to-group \
  --group-name EKS-Administrators \
  --user-name topzone-k8s-admin
```

**장점:**
- 여러 사용자에게 동일 권한 부여 용이
- 중앙 집중식 권한 관리
- 사용자 추가/제거 간편

---

## 프로젝트 필수 권한

### EKS 클러스터 생성/관리에 필요한 권한

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*",
        "ec2:*",
        "iam:*",
        "elasticloadbalancing:*",
        "autoscaling:*",
        "cloudformation:*",
        "route53:*",
        "s3:*",
        "logs:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### 최소 권한 정책 (프로덕션 권장)

#### EKS 권한
```json
{
  "Effect": "Allow",
  "Action": [
    "eks:CreateCluster",
    "eks:DescribeCluster",
    "eks:ListClusters",
    "eks:UpdateClusterConfig",
    "eks:UpdateClusterVersion",
    "eks:DeleteCluster",
    "eks:CreateNodegroup",
    "eks:DescribeNodegroup",
    "eks:DeleteNodegroup"
  ],
  "Resource": "*"
}
```

#### EC2 및 VPC 권한
```json
{
  "Effect": "Allow",
  "Action": [
    "ec2:CreateVpc",
    "ec2:DescribeVpcs",
    "ec2:CreateSubnet",
    "ec2:DescribeSubnets",
    "ec2:CreateSecurityGroup",
    "ec2:DescribeSecurityGroups",
    "ec2:CreateInternetGateway",
    "ec2:CreateNatGateway",
    "ec2:AllocateAddress",
    "ec2:CreateRouteTable",
    "ec2:DescribeInstances",
    "ec2:RunInstances",
    "ec2:CreateTags"
  ],
  "Resource": "*"
}
```

#### IAM 권한
```json
{
  "Effect": "Allow",
  "Action": [
    "iam:CreateRole",
    "iam:GetRole",
    "iam:AttachRolePolicy",
    "iam:CreateInstanceProfile",
    "iam:AddRoleToInstanceProfile",
    "iam:PassRole"
  ],
  "Resource": "*"
}
```

---

## IAM Role 설정

### EKS Cluster Role

**Trust Relationship (신뢰 관계):**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**필요한 Policies:**
- AmazonEKSClusterPolicy
- AmazonEKSVPCResourceController

**생성 명령어:**
```bash
# Role 생성
aws iam create-role \
  --role-name topzone-k8s-cluster-role \
  --assume-role-policy-document file://eks-trust-policy.json

# 정책 연결
aws iam attach-role-policy \
  --role-name topzone-k8s-cluster-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
```

---

### EKS Node Group Role

**Trust Relationship:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**필요한 Policies:**
- AmazonEKSWorkerNodePolicy
- AmazonEKS_CNI_Policy
- AmazonEC2ContainerRegistryReadOnly

---

## 보안 모범 사례

### 1. 최소 권한 원칙 (Least Privilege)

❌ **나쁜 예:**
```json
{
  "Effect": "Allow",
  "Action": "*",
  "Resource": "*"
}
```

✅ **좋은 예:**
```json
{
  "Effect": "Allow",
  "Action": [
    "eks:DescribeCluster",
    "eks:ListClusters"
  ],
  "Resource": "arn:aws:eks:ap-northeast-2:192496985564:cluster/topzone-k8s"
}
```

---

### 2. MFA (Multi-Factor Authentication) 활성화

1. IAM → Users → Security credentials
2. **Assigned MFA device** → Manage
3. Virtual MFA device 선택
4. Google Authenticator 앱으로 QR 스캔

---

### 3. Access Key 로테이션 (90일마다)

```bash
# 1. 새 Access Key 생성
aws iam create-access-key --user-name topzone-k8s-admin

# 2. 새 Key 테스트

# 3. 기존 Key 비활성화
aws iam update-access-key \
  --user-name topzone-k8s-admin \
  --access-key-id AKIAOLDKEY \
  --status Inactive

# 4. 확인 후 삭제
aws iam delete-access-key \
  --user-name topzone-k8s-admin \
  --access-key-id AKIAOLDKEY
```

---

### 4. 그룹 기반 권한 관리

```
✅ 권장 구조:
Group-Admin → AdministratorAccess
  ├─ user1
  └─ user2

Group-Dev → DeveloperAccess
  └─ user3

❌ 비권장:
user1 → Policy A, B, C
user2 → Policy A, B, D (관리 복잡)
```

---

### 5. CloudTrail 활성화

IAM 활동 모니터링 및 감사 로그 기록

```bash
aws cloudtrail create-trail \
  --name iam-activity-trail \
  --s3-bucket-name my-cloudtrail-bucket
```

---

## 자동화 스크립트

### IAM User 자동 생성 스크립트

```bash
#!/bin/bash

USER_NAME="topzone-k8s-admin"
POLICY_ARN="arn:aws:iam::aws:policy/AdministratorAccess"

echo "IAM User 생성 중: $USER_NAME"

# User 생성
aws iam create-user --user-name $USER_NAME

# Access Key 생성
ACCESS_KEY=$(aws iam create-access-key --user-name $USER_NAME)
ACCESS_KEY_ID=$(echo $ACCESS_KEY | jq -r '.AccessKey.AccessKeyId')
SECRET_KEY=$(echo $ACCESS_KEY | jq -r '.AccessKey.SecretAccessKey')

# 정책 연결
aws iam attach-user-policy \
  --user-name $USER_NAME \
  --policy-arn $POLICY_ARN

# CSV 파일로 저장
cat > ${USER_NAME}_credentials.csv <<EOF
User Name,Access Key ID,Secret Access Key
$USER_NAME,$ACCESS_KEY_ID,$SECRET_KEY
EOF

echo "✅ 완료!"
echo "Access Key ID: $ACCESS_KEY_ID"
echo "Secret Access Key: $SECRET_KEY"
echo "CSV 파일: ${USER_NAME}_credentials.csv"
```

---

## 빠른 시작 가이드

### 5분 완성

1. **AWS Console 로그인**
   ```
   https://console.aws.amazon.com/iam/
   ```

2. **Users → Add users**
   - User name: `topzone-k8s-admin`
   - Access type: ✅ Programmatic access

3. **Permissions**
   - Attach existing policies: `AdministratorAccess`

4. **Create user**

5. **Download .csv**

6. **credentials 파일 업데이트**
   ```bash
   vi ~/KUBE/tz-eks-main/resources/credentials
   ```

7. **테스트**
   ```bash
   aws sts get-caller-identity
   ```

8. **완료!** ✅

---

## 트러블슈팅

### 문제 1: AccessDenied 오류

```bash
# 연결된 정책 확인
aws iam list-attached-user-policies --user-name topzone-k8s-admin

# 필요한 정책 추가
aws iam attach-user-policy \
  --user-name topzone-k8s-admin \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

### 문제 2: PassRole 권한 없음

```json
{
  "Effect": "Allow",
  "Action": "iam:PassRole",
  "Resource": "*"
}
```

---

## 체크리스트

IAM 설정 전:
- [ ] AWS 계정 준비
- [ ] Root 계정 MFA 활성화

User 생성 후:
- [ ] Access Key 안전하게 저장
- [ ] 적절한 정책 연결
- [ ] `aws sts get-caller-identity` 테스트 성공
- [ ] credentials 파일 업데이트

---

## 참고 자료

- [IAM User Guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/)
- [EKS IAM Roles](https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

---

**작성일**: 2025년 11월 14일  
**프로젝트**: KUBE (tz-eks-main)  
**목적**: EKS 클러스터 관리를 위한 IAM 설정

