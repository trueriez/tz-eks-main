# Route53에서 도메인 등록 가이드 (codesonic.online)

## 📋 목차
1. [Route53 도메인 등록 방법](#route53-도메인-등록-방법)
2. [Hosted Zone 생성](#hosted-zone-생성)
3. [도메인 연결 (외부 도메인인 경우)](#도메인-연결-외부-도메인인-경우)
4. [프로젝트 설정 업데이트](#프로젝트-설정-업데이트)
5. [DNS 설정 확인](#dns-설정-확인)
6. [트러블슈팅](#트러블슈팅)

---

## Route53 도메인 등록 방법

### 옵션 1: AWS Route53에서 직접 도메인 구매 (권장)

#### 1-1. AWS Console에서 도메인 구매

**단계:**

1. **AWS Console 로그인**
   - https://console.aws.amazon.com
   - Route53 서비스로 이동

2. **도메인 등록 페이지 이동**
   ```
   Route53 → Dashboard → Register domain
   ```

3. **도메인 검색**
   - 검색창에 `codesonic.online` 입력
   - "Check" 버튼 클릭
   - 사용 가능 여부 확인

4. **도메인 구매**
   - 가격 확인 (보통 $12-15/년)
   - "Add to cart" 클릭
   - "Continue" 클릭

5. **연락처 정보 입력**
   - 등록자 정보 입력
   - 개인정보 보호 옵션 선택 (권장)
   - 약관 동의

6. **결제**
   - 신용카드 정보 확인
   - "Complete Order" 클릭

7. **이메일 확인**
   - 등록한 이메일로 확인 메일 수신
   - 15일 이내에 이메일 인증 완료 필요

**⏱️ 소요 시간**: 구매 완료 후 최대 3일 (보통 몇 시간 이내)

---

#### 1-2. AWS CLI로 도메인 구매

```bash
# 도메인 사용 가능 여부 확인
aws route53domains check-domain-availability \
  --domain-name codesonic.online \
  --region us-east-1

# 도메인 가격 확인
aws route53domains get-domain-suggestions \
  --domain-name codesonic \
  --suggestion-count 5 \
  --only-available \
  --region us-east-1

# 도메인 등록 (JSON 파일 필요)
aws route53domains register-domain \
  --domain-name codesonic.online \
  --duration-in-years 1 \
  --admin-contact file://contact.json \
  --registrant-contact file://contact.json \
  --tech-contact file://contact.json \
  --privacy-protect-admin-contact \
  --privacy-protect-registrant-contact \
  --privacy-protect-tech-contact \
  --region us-east-1
```

**contact.json 예시:**
```json
{
  "FirstName": "John",
  "LastName": "Doe",
  "ContactType": "PERSON",
  "OrganizationName": "Your Company",
  "AddressLine1": "123 Main St",
  "City": "Seoul",
  "State": "Seoul",
  "CountryCode": "KR",
  "ZipCode": "12345",
  "PhoneNumber": "+82.1012345678",
  "Email": "admin@codesonic.online"
}
```

---

### 옵션 2: 외부에서 구매한 도메인 연결

만약 GoDaddy, Namecheap, Gabia 등에서 이미 도메인을 구매했다면:

#### 2-1. Route53 Hosted Zone 생성

**AWS Console 방법:**

1. **Route53 → Hosted zones** 이동
2. **"Create hosted zone"** 클릭
3. 설정 입력:
   ```
   Domain name: codesonic.online
   Description: Main domain for codesonic project
   Type: Public hosted zone
   ```
4. **"Create hosted zone"** 클릭

5. **네임서버 확인**
   - 생성된 Hosted Zone 클릭
   - NS (Name Server) 레코드 확인
   ```
   ns-123.awsdns-12.com
   ns-456.awsdns-45.net
   ns-789.awsdns-78.org
   ns-012.awsdns-01.co.uk
   ```

**AWS CLI 방법:**

```bash
# Hosted Zone 생성
aws route53 create-hosted-zone \
  --name codesonic.online \
  --caller-reference $(date +%s) \
  --hosted-zone-config Comment="Main domain for codesonic project"

# Hosted Zone ID 확인
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones \
  --query "HostedZones[?Name == 'codesonic.online.'].Id" \
  --output text | cut -d'/' -f3)

echo "Hosted Zone ID: $HOSTED_ZONE_ID"

# 네임서버 확인
aws route53 get-hosted-zone --id $HOSTED_ZONE_ID \
  --query "DelegationSet.NameServers" \
  --output table
```

---

#### 2-2. 도메인 등록업체에서 네임서버 변경

**GoDaddy 예시:**
1. GoDaddy 로그인
2. My Products → Domains
3. `codesonic.online` 선택
4. DNS → Nameservers → Change
5. Custom nameservers 선택
6. Route53 네임서버 4개 입력:
   ```
   ns-123.awsdns-12.com
   ns-456.awsdns-45.net
   ns-789.awsdns-78.org
   ns-012.awsdns-01.co.uk
   ```
7. Save

**Gabia (가비아) 예시:**
1. 가비아 로그인
2. My가비아 → 도메인 관리
3. `codesonic.online` 선택
4. 네임서버 설정
5. 1차~4차 네임서버에 Route53 네임서버 입력
6. 적용

**⏱️ 전파 시간**: 최대 48시간 (보통 1-2시간)

---

## Hosted Zone 생성

### AWS Console 방법 (상세)

1. **Route53 서비스 접속**
   ```
   AWS Console → Services → Route 53
   ```

2. **Hosted zones 메뉴 클릭**
   - 좌측 메뉴에서 "Hosted zones" 선택

3. **Create hosted zone 클릭**

4. **설정 입력**
   ```
   Domain name: codesonic.online
   Description: Kubernetes cluster domain for DevOps platform
   Type: Public hosted zone (인터넷에서 접근 가능)
   Tags (선택):
     - Key: Project, Value: topzone-k8s
     - Key: Environment, Value: prod
   ```

5. **Create hosted zone 클릭**

6. **생성 확인**
   - Hosted zone이 생성되면 자동으로 NS 및 SOA 레코드 생성됨
   - Hosted zone ID 복사 (예: Z0123456789ABCDEFGHIJ)

---

### AWS CLI 스크립트 (자동화)

```bash
#!/bin/bash

# 변수 설정
DOMAIN="codesonic.online"
PROJECT="topzone-k8s"
ENVIRONMENT="prod"

# Hosted Zone 생성
echo "Creating Hosted Zone for ${DOMAIN}..."
HOSTED_ZONE_OUTPUT=$(aws route53 create-hosted-zone \
  --name ${DOMAIN} \
  --caller-reference $(date +%s) \
  --hosted-zone-config Comment="Kubernetes cluster domain for ${PROJECT}" \
  --output json)

# Hosted Zone ID 추출
HOSTED_ZONE_ID=$(echo $HOSTED_ZONE_OUTPUT | jq -r '.HostedZone.Id' | cut -d'/' -f3)
echo "✅ Hosted Zone ID: $HOSTED_ZONE_ID"

# 네임서버 확인
echo ""
echo "📋 Name Servers:"
aws route53 get-hosted-zone --id $HOSTED_ZONE_ID \
  --query "DelegationSet.NameServers" \
  --output table

# 설정 파일 업데이트 준비
echo ""
echo "🔧 Update your configuration files:"
echo "  - tzcorp_zone_id = \"${HOSTED_ZONE_ID}\""
echo "  - domain = \"${DOMAIN}\""

# Hosted Zone 정보 저장
cat > hosted_zone_info.txt <<EOF
Domain: ${DOMAIN}
Hosted Zone ID: ${HOSTED_ZONE_ID}
Created: $(date)

Name Servers (외부 도메인 등록업체에 설정):
$(aws route53 get-hosted-zone --id $HOSTED_ZONE_ID --query "DelegationSet.NameServers" --output text)

Next Steps:
1. Update .auto.tfvars: tzcorp_zone_id = "${HOSTED_ZONE_ID}"
2. Update project file: domain=${DOMAIN}
3. If using external registrar, update nameservers
4. Wait 1-2 hours for DNS propagation
5. Run: bash bootstrap.sh
EOF

echo ""
echo "✅ Hosted Zone information saved to: hosted_zone_info.txt"
```

**실행:**
```bash
chmod +x create_hosted_zone.sh
./create_hosted_zone.sh
```

---

## 도메인 연결 (외부 도메인인 경우)

### DNS 전파 확인

```bash
# 네임서버 확인
dig NS codesonic.online

# 또는
nslookup -type=NS codesonic.online

# 결과 예시 (Route53 네임서버가 보이면 성공):
# codesonic.online    nameserver = ns-123.awsdns-12.com.
# codesonic.online    nameserver = ns-456.awsdns-45.net.
```

### 온라인 도구로 확인

- https://dnschecker.org/
  - 도메인 입력: `codesonic.online`
  - Record Type: `NS`
  - 전 세계 각 지역에서 전파 상태 확인

- https://www.whatsmydns.net/
  - 실시간 DNS 전파 상태 모니터링

---

## 프로젝트 설정 업데이트

### 1. Hosted Zone ID 확인

```bash
# AWS CLI로 확인
aws route53 list-hosted-zones \
  --query "HostedZones[?Name == 'codesonic.online.'].Id" \
  --output text | cut -d'/' -f3
```

### 2. .auto.tfvars 파일 업데이트

**수동 업데이트:**

```terraform
# /Users/codesonic/Documents/Workspace/KUBE/tz-eks-main/resources/.auto.tfvars

account_id = "192496985564"
cluster_name = "topzone-k8s"
region = "ap-northeast-2"
environment = "prod"

# codesonic.online 도메인으로 변경
tzcorp_zone_id = "Z새로받은Hosted Zone ID"  # codesonic.online

VCP_BCLASS = "10.20"
instance_type = "t3.large"
DB_PSWD = "DevOps!323"
k8s_config_path = "/root/.kube/config"
```

**자동 업데이트 스크립트:**

```bash
#!/bin/bash

# 프로젝트 디렉토리로 이동
cd /Users/codesonic/Documents/Workspace/KUBE/tz-eks-main

# 새 도메인 설정
NEW_DOMAIN="codesonic.online"

# Hosted Zone ID 자동 조회
NEW_ZONE_ID=$(aws route53 list-hosted-zones \
  --query "HostedZones[?Name == '${NEW_DOMAIN}.'].Id" \
  --output text | cut -d'/' -f3)

if [[ -z "$NEW_ZONE_ID" ]]; then
  echo "❌ Error: Hosted Zone for ${NEW_DOMAIN} not found!"
  echo "Please create Hosted Zone first."
  exit 1
fi

echo "✅ Found Hosted Zone ID: $NEW_ZONE_ID"

# 파일 백업
cp resources/.auto.tfvars resources/.auto.tfvars.backup
cp resources/project resources/project.backup

# .auto.tfvars 업데이트
sed -i.bak "s/tzcorp_zone_id = \".*\"/tzcorp_zone_id = \"${NEW_ZONE_ID}\"  # ${NEW_DOMAIN}/" resources/.auto.tfvars

# project 파일 업데이트
if grep -q "^domain=" resources/project; then
  sed -i.bak "s/^domain=.*/domain=${NEW_DOMAIN}/" resources/project
else
  echo "domain=${NEW_DOMAIN}" >> resources/project
fi

# 정리
rm -f resources/.auto.tfvars.bak resources/project.bak

# 결과 확인
echo ""
echo "=== Updated .auto.tfvars ==="
grep "tzcorp_zone_id" resources/.auto.tfvars

echo ""
echo "=== Updated project ==="
grep "domain" resources/project

echo ""
echo "✅ Configuration files updated successfully!"
echo ""
echo "📋 New Configuration:"
echo "  Domain: ${NEW_DOMAIN}"
echo "  Hosted Zone ID: ${NEW_ZONE_ID}"
echo ""
echo "🚀 Next step: bash bootstrap.sh"
```

### 3. project 파일 업데이트

```bash
# /Users/codesonic/Documents/Workspace/KUBE/tz-eks-main/resources/project

project=topzone-k8s
aws_account_id=192496985564
domain=codesonic.online  # 새 도메인으로 변경
argocd_id=admin
admin_password=DevOps!323
# ... 나머지 설정
```

---

## DNS 설정 확인

### 1. Hosted Zone 레코드 확인

```bash
# Hosted Zone ID 설정
HOSTED_ZONE_ID="Z새로받은ID"

# 모든 레코드 조회
aws route53 list-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --output table
```

### 2. DNS 쿼리 테스트

```bash
# 도메인 네임서버 확인
dig NS codesonic.online +short

# A 레코드 확인 (설정 후)
dig codesonic.online +short

# 특정 서브도메인 확인
dig jenkins.default.topzone-k8s.codesonic.online +short
```

### 3. WHOIS 정보 확인 (Route53에서 구매한 경우)

```bash
whois codesonic.online
```

---

## 생성될 서비스 도메인

프로젝트 설치 완료 후 다음 도메인으로 접속 가능:

```
기본 패턴: service.namespace.cluster-name.domain

Jenkins:
https://jenkins.default.topzone-k8s.codesonic.online

ArgoCD:
https://argocd.default.topzone-k8s.codesonic.online

Grafana:
https://grafana.default.topzone-k8s.codesonic.online

Prometheus:
https://prometheus.default.topzone-k8s.codesonic.online

AlertManager:
https://alertmanager.default.topzone-k8s.codesonic.online

Vault:
https://vault.default.topzone-k8s.codesonic.online

Harbor:
https://harbor.devops.topzone-k8s.codesonic.online

Nexus:
https://nexus.default.topzone-k8s.codesonic.online
```

---

## 트러블슈팅

### 문제 1: 도메인을 찾을 수 없음

**증상:**
```bash
aws route53 list-hosted-zones
# codesonic.online이 목록에 없음
```

**해결 방법:**
```bash
# Hosted Zone 생성
aws route53 create-hosted-zone \
  --name codesonic.online \
  --caller-reference $(date +%s)
```

---

### 문제 2: DNS 전파가 안 됨

**증상:**
```bash
dig NS codesonic.online
# 여전히 이전 네임서버가 보임
```

**해결 방법:**
1. 도메인 등록업체에서 네임서버 설정 확인
2. 캐시 플러시:
   ```bash
   # macOS
   sudo dscacheutil -flushcache
   sudo killall -HUP mDNSResponder
   
   # Linux
   sudo systemd-resolve --flush-caches
   ```
3. 최대 48시간 대기 (보통 1-2시간)

---

### 문제 3: 권한 오류

**증상:**
```
AccessDenied: User is not authorized to perform: route53:CreateHostedZone
```

**해결 방법:**
IAM 정책 추가:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:CreateHostedZone",
        "route53:ListHostedZones",
        "route53:GetHostedZone",
        "route53:ListResourceRecordSets",
        "route53:ChangeResourceRecordSets",
        "route53:GetChange"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53domains:*"
      ],
      "Resource": "*"
    }
  ]
}
```

---

### 문제 4: 이메일 인증이 안 됨 (Route53 구매)

**증상:**
도메인 구매 후 이메일 확인 링크를 못 받음

**해결 방법:**
1. 스팸 메일함 확인
2. AWS Console → Route53 → Domains → Pending requests
3. "Resend confirmation email" 클릭
4. 15일 이내에 반드시 확인 (미확인 시 도메인 정지)

---

## 빠른 시작 가이드

### 전체 프로세스 (자동화 스크립트)

```bash
#!/bin/bash
set -e

echo "=========================================="
echo "Route53 도메인 설정 자동화"
echo "=========================================="

# 1. 도메인 설정
DOMAIN="codesonic.online"
PROJECT_DIR="/Users/codesonic/Documents/Workspace/KUBE/tz-eks-main"

cd $PROJECT_DIR

# 2. Hosted Zone 확인
echo "🔍 Checking Hosted Zone..."
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones \
  --query "HostedZones[?Name == '${DOMAIN}.'].Id" \
  --output text 2>/dev/null | cut -d'/' -f3)

if [[ -z "$HOSTED_ZONE_ID" ]]; then
  echo "📝 Creating Hosted Zone for ${DOMAIN}..."
  ZONE_OUTPUT=$(aws route53 create-hosted-zone \
    --name ${DOMAIN} \
    --caller-reference $(date +%s) \
    --hosted-zone-config Comment="Created by automation script" \
    --output json)
  
  HOSTED_ZONE_ID=$(echo $ZONE_OUTPUT | jq -r '.HostedZone.Id' | cut -d'/' -f3)
  echo "✅ Hosted Zone Created: $HOSTED_ZONE_ID"
  
  # 네임서버 출력
  echo ""
  echo "📋 Name Servers (외부 도메인인 경우 등록업체에 설정):"
  aws route53 get-hosted-zone --id $HOSTED_ZONE_ID \
    --query "DelegationSet.NameServers[]" \
    --output text | tr '\t' '\n'
  echo ""
else
  echo "✅ Hosted Zone Found: $HOSTED_ZONE_ID"
fi

# 3. 파일 백업
echo "💾 Backing up configuration files..."
mkdir -p backups
cp resources/.auto.tfvars backups/.auto.tfvars.$(date +%Y%m%d_%H%M%S)
cp resources/project backups/project.$(date +%Y%m%d_%H%M%S)

# 4. .auto.tfvars 업데이트
echo "📝 Updating .auto.tfvars..."
sed -i.bak "s/tzcorp_zone_id = \"[^\"]*\"/tzcorp_zone_id = \"${HOSTED_ZONE_ID}\"  # ${DOMAIN}/" resources/.auto.tfvars
rm -f resources/.auto.tfvars.bak

# 5. project 파일 업데이트
echo "📝 Updating project file..."
if grep -q "^domain=" resources/project; then
  sed -i.bak "s/^domain=.*/domain=${DOMAIN}/" resources/project
else
  echo "domain=${DOMAIN}" >> resources/project
fi
rm -f resources/project.bak

# 6. 확인
echo ""
echo "=========================================="
echo "✅ Configuration Updated!"
echo "=========================================="
echo ""
echo "📋 Current Settings:"
grep -E "tzcorp_zone_id|account_id|cluster_name" resources/.auto.tfvars
echo ""
grep -E "domain|aws_account_id|project" resources/project
echo ""
echo "🌐 Service URLs (after installation):"
echo "  Jenkins:   https://jenkins.default.topzone-k8s.${DOMAIN}"
echo "  ArgoCD:    https://argocd.default.topzone-k8s.${DOMAIN}"
echo "  Grafana:   https://grafana.default.topzone-k8s.${DOMAIN}"
echo "  Vault:     https://vault.default.topzone-k8s.${DOMAIN}"
echo ""
echo "🚀 Next Steps:"
echo "  1. DNS 전파 확인 (1-2시간): dig NS ${DOMAIN}"
echo "  2. 클러스터 생성: bash bootstrap.sh"
echo ""
```

**저장 및 실행:**
```bash
# 스크립트 저장
cat > setup_codesonic_domain.sh << 'EOF'
[위 스크립트 내용]
EOF

# 실행 권한 부여
chmod +x setup_codesonic_domain.sh

# 실행
./setup_codesonic_domain.sh
```

---

## 체크리스트

### 도메인 설정 전
- [ ] AWS CLI 설치 및 인증 완료
- [ ] Route53 권한 확인 (IAM)
- [ ] 도메인 사용 가능 여부 확인
- [ ] 예산 확인 (약 $12-15/년)

### 도메인 설정 후
- [ ] Hosted Zone 생성 확인
- [ ] Hosted Zone ID 복사
- [ ] 네임서버 확인 (4개)
- [ ] 외부 도메인인 경우 네임서버 변경 완료

### 프로젝트 설정 업데이트
- [ ] `.auto.tfvars` 파일의 `tzcorp_zone_id` 업데이트
- [ ] `project` 파일의 `domain` 업데이트
- [ ] 파일 백업 완료

### 설치 준비
- [ ] DNS 전파 확인 (dig NS codesonic.online)
- [ ] AWS Account ID 설정 확인
- [ ] Cluster Name 확인
- [ ] 기타 설정 확인 (region, instance_type 등)

---

## 참고 자료

### AWS 공식 문서
- [Route53 도메인 등록](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-register.html)
- [Hosted Zone 생성](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingHostedZone.html)
- [네임서버 변경](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-name-servers-glue-records.html)

### 유용한 도구
- [DNS Checker](https://dnschecker.org/) - DNS 전파 확인
- [What's My DNS](https://www.whatsmydns.net/) - 글로벌 DNS 상태
- [MX Toolbox](https://mxtoolbox.com/) - DNS 레코드 조회

### 비용
- **.online 도메인**: 약 $12-15/년
- **Hosted Zone**: $0.50/월 + 쿼리당 요금
- **DNS 쿼리**: 처음 1백만 건까지 $0.40/백만 건

---

**작성일**: 2025년 11월 14일  
**대상 도메인**: codesonic.online  
**프로젝트**: KUBE (tz-eks-main)  
**현재 클러스터**: topzone-k8s

