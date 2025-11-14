# tzcorp_zone_id 설정 완료

## ✅ 업데이트 완료

**날짜**: 2025년 11월 14일

---

## 📋 업데이트 내용

### 1. `.auto.tfvars` 파일
**파일 위치**: `tz-eks-main/resources/.auto.tfvars`

```terraform
tzcorp_zone_id = "Z0718218378910OO3Y646"  # humaxcharging.com
```

### 2. `project` 파일
**파일 위치**: `tz-eks-main/resources/project`

```bash
aws_account_id=192496985564
domain=humaxcharging.com
```

---

## 🎯 tzcorp_zone_id란?

### 정의
**Route53 Hosted Zone ID**는 AWS Route53에서 도메인을 관리하기 위한 고유 식별자입니다.

### 용도
- DNS 레코드 생성 및 관리
- Ingress 도메인 자동 설정
- 서비스 도메인 매핑
- SSL/TLS 인증서 검증

---

## 🌐 사용 가능한 Route53 Hosted Zone

현재 AWS 계정에 등록된 Hosted Zone:

| 도메인 | Hosted Zone ID | 상태 | 용도 |
|--------|---------------|------|------|
| **humaxcharging.com** | Z0718218378910OO3Y646 | ✅ 선택됨 | 메인 도메인 |
| uhc-server-dev.humaxcharging.com | Z094923129I253JZOPRG2 | Available | 개발 환경 |
| uhc-server-dev.humaxcharging.com | Z05180602FM5OWUOK4CRP | Available | 개발 환경 (중복) |
| ecord-test.com | Z0209046GN3TRG3D7RUI | Available | 테스트 환경 |
| internal. | Z10040782R2C5J5BS0Q20 | Available | 내부 전용 |

---

## 🔧 자동 생성될 도메인

프로젝트 설치 후 다음 도메인들이 자동으로 생성됩니다:

### 패턴
```
*.${namespace}.${cluster_name}.${domain}
```

### 실제 도메인 예시
**선택된 설정:**
- **cluster_name**: `topzone-k8s`
- **domain**: `humaxcharging.com`

**생성될 서비스 도메인:**

#### 기본 네임스페이스 (default)
- **Jenkins**: https://jenkins.default.topzone-k8s.humaxcharging.com
- **ArgoCD**: https://argocd.default.topzone-k8s.humaxcharging.com
- **Grafana**: https://grafana.default.topzone-k8s.humaxcharging.com
- **Prometheus**: https://prometheus.default.topzone-k8s.humaxcharging.com
- **AlertManager**: https://alertmanager.default.topzone-k8s.humaxcharging.com
- **Vault**: https://vault.default.topzone-k8s.humaxcharging.com
- **Nexus**: https://nexus.default.topzone-k8s.humaxcharging.com

#### DevOps 네임스페이스
- **Harbor**: https://harbor.devops.topzone-k8s.humaxcharging.com

#### Vault 네임스페이스
- **Vault UI**: https://vault.vault.topzone-k8s.humaxcharging.com

---

## 📝 Route53 확인 명령어

### 모든 Hosted Zone 조회
```bash
aws route53 list-hosted-zones
```

### 테이블 형식으로 보기
```bash
aws route53 list-hosted-zones --query "HostedZones[].[Name,Id]" --output table
```

**출력 예시:**
```
----------------------------------------------------------------------------
                              ListHostedZones                             
+------------------------------------+-------------------------------------+
| humaxcharging.com.                 | /hostedzone/Z0718218378910OO3Y646  |
| uhc-server-dev.humaxcharging.com.  | /hostedzone/Z094923129I253JZOPRG2  |
| ecord-test.com.                    | /hostedzone/Z0209046GN3TRG3D7RUI   |
+------------------------------------+-------------------------------------+
```

### 특정 도메인의 Hosted Zone ID 조회
```bash
# humaxcharging.com의 Hosted Zone ID 추출
aws route53 list-hosted-zones \
  --query "HostedZones[?Name == 'humaxcharging.com.'].Id" \
  --output text | cut -d'/' -f3
```

**결과:**
```
Z0718218378910OO3Y646
```

### 특정 Hosted Zone의 레코드 조회
```bash
aws route53 list-resource-record-sets \
  --hosted-zone-id Z0718218378910OO3Y646 \
  --output table
```

---

## 🚀 다음 단계

### 1. 설정 확인
```bash
cd /Users/codesonic/Documents/Workspace/KUBE/tz-eks-main

# .auto.tfvars 확인
cat resources/.auto.tfvars | grep -E "tzcorp_zone_id|account_id|cluster_name"

# project 파일 확인
cat resources/project | grep -E "domain|aws_account_id|project"
```

### 2. DNS 설정 확인
```bash
# 도메인 네임서버 확인
dig NS humaxcharging.com

# 또는 AWS CLI로 확인
aws route53 get-hosted-zone --id Z0718218378910OO3Y646
```

### 3. Bootstrap 실행
```bash
# 프로젝트 초기화 (Docker 컨테이너 생성 및 EKS 클러스터 프로비저닝)
bash bootstrap.sh
```

---

## ⚠️ 주의사항

### 1. 도메인 변경의 영향

도메인을 변경하면 다음 항목들이 영향을 받습니다:

- **모든 Ingress 리소스의 도메인**
- **SSL/TLS 인증서 (Let's Encrypt)**
- **외부 접근 URL**
- **ArgoCD Repository 설정**
- **Vault 주소 설정**

### 2. 기존 도메인과의 불일치

`project` 파일의 원래 도메인: `topzone.me`  
**Route53에 없는 도메인이므로 변경됨**: `humaxcharging.com`

만약 `topzone.me` 도메인을 사용하려면:
```bash
# Route53에 Hosted Zone 생성
aws route53 create-hosted-zone \
  --name topzone.me \
  --caller-reference $(date +%s) \
  --hosted-zone-config Comment="Main domain for topzone project"
```

### 3. 환경별 도메인 전략

**권장 구성:**

#### 프로덕션
```terraform
domain = "humaxcharging.com"
tzcorp_zone_id = "Z0718218378910OO3Y646"
```

#### 개발/테스트
```terraform
domain = "uhc-server-dev.humaxcharging.com"
tzcorp_zone_id = "Z094923129I253JZOPRG2"
```

또는

```terraform
domain = "ecord-test.com"
tzcorp_zone_id = "Z0209046GN3TRG3D7RUI"
```

---

## 🔍 트러블슈팅

### 문제 1: Hosted Zone을 찾을 수 없음

**증상:**
```
Error: No hosted zone found for domain
```

**해결 방법:**
```bash
# 1. Route53 Hosted Zone 존재 확인
aws route53 list-hosted-zones

# 2. 도메인 이름 끝에 점(.) 추가 확인
aws route53 list-hosted-zones \
  --query "HostedZones[?Name == 'humaxcharging.com.'].Id"
```

### 문제 2: DNS 레코드 생성 실패

**증상:**
```
Error creating Route53 record: AccessDenied
```

**해결 방법:**
IAM 사용자에게 Route53 권한 부여:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:GetHostedZone",
        "route53:ListResourceRecordSets",
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": "*"
    }
  ]
}
```

### 문제 3: 도메인이 전파되지 않음

**증상:**
웹 브라우저에서 도메인에 접속할 수 없음

**해결 방법:**
```bash
# 1. DNS 전파 확인 (최대 48시간 소요)
dig jenkins.default.topzone-k8s.humaxcharging.com

# 2. Route53 레코드 확인
aws route53 list-resource-record-sets \
  --hosted-zone-id Z0718218378910OO3Y646 \
  --query "ResourceRecordSets[?contains(Name, 'topzone-k8s')]"

# 3. Load Balancer DNS 확인
kubectl get svc -n default | grep LoadBalancer
```

---

## 📚 참고 자료

### AWS Route53 문서
- [Route53 Getting Started](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/getting-started.html)
- [Working with Hosted Zones](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-working-with.html)
- [DNS Record Types](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/ResourceRecordTypes.html)

### 프로젝트 스크립트
Route53을 사용하는 주요 스크립트:

```
tz-eks-main/tz-local/resource/
├── ingress_nginx/install.sh       # *.namespace.cluster.domain CNAME 생성
├── argocd/install.sh              # ArgoCD 도메인 설정
├── jenkins/helm/install.sh        # Jenkins 도메인 설정
├── monitoring/install.sh          # Grafana, Prometheus 도메인 설정
└── vault/helm/install.sh          # Vault 도메인 설정
```

### DNS 전파 확인 도구
- https://dnschecker.org/
- https://www.whatsmydns.net/

---

## ✅ 체크리스트

설치 전 확인사항:

- [x] AWS Account ID 설정됨: `192496985564`
- [x] Route53 Hosted Zone ID 설정됨: `Z0718218378910OO3Y646`
- [x] 도메인 설정됨: `humaxcharging.com`
- [x] Cluster Name 설정됨: `topzone-k8s`
- [ ] DNS 네임서버가 AWS Route53으로 설정되어 있는가?
- [ ] IAM 사용자가 Route53 권한을 가지고 있는가?
- [ ] SSL/TLS 인증서 발급 준비가 되었는가? (Let's Encrypt)

---

## 🎯 요약

### 현재 설정
```
AWS Account ID    : 192496985564
Cluster Name      : topzone-k8s
Domain            : humaxcharging.com
Hosted Zone ID    : Z0718218378910OO3Y646
Region            : ap-northeast-2
Environment       : prod
```

### 접속 예정 URL
설치 완료 후 다음 URL로 접속 가능합니다:

```
Jenkins   : https://jenkins.default.topzone-k8s.humaxcharging.com
ArgoCD    : https://argocd.default.topzone-k8s.humaxcharging.com
Grafana   : https://grafana.default.topzone-k8s.humaxcharging.com
Vault     : https://vault.default.topzone-k8s.humaxcharging.com
```

---

**작성일**: 2025년 11월 14일  
**프로젝트**: KUBE (tz-eks-main)  
**설정 파일**: 
- `resources/.auto.tfvars` ✅
- `resources/project` ✅

