#!/bin/bash
set -e

echo "=========================================="
echo "Route53 도메인 설정 자동화"
echo "codesonic.online"
echo "=========================================="
echo ""

# 변수 설정
DOMAIN="codesonic.online"
PROJECT_DIR="/Users/codesonic/Documents/Workspace/KUBE/tz-eks-main"
CLUSTER_NAME="topzone-k8s"

# 프로젝트 디렉토리 확인
if [ ! -d "$PROJECT_DIR" ]; then
  echo "❌ Error: Project directory not found: $PROJECT_DIR"
  exit 1
fi

cd $PROJECT_DIR

# AWS CLI 확인
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI가 설치되어 있지 않습니다."
    exit 1
fi

# AWS 인증 확인
echo "🔍 AWS 인증 확인 중..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS 인증이 설정되어 있지 않습니다."
    echo "다음 명령어로 설정하세요: aws configure"
    exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "✅ AWS Account ID: $AWS_ACCOUNT_ID"
echo ""

# Hosted Zone 확인 또는 생성
echo "🔍 Hosted Zone 확인 중..."
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones \
  --query "HostedZones[?Name == '${DOMAIN}.'].Id" \
  --output text 2>/dev/null | cut -d'/' -f3)

if [[ -z "$HOSTED_ZONE_ID" ]]; then
  echo "📝 Hosted Zone이 없습니다. 새로 생성합니다..."
  echo ""

  ZONE_OUTPUT=$(aws route53 create-hosted-zone \
    --name ${DOMAIN} \
    --caller-reference $(date +%s) \
    --hosted-zone-config Comment="Created for ${CLUSTER_NAME} cluster" \
    --output json)

  HOSTED_ZONE_ID=$(echo $ZONE_OUTPUT | jq -r '.HostedZone.Id' | cut -d'/' -f3)
  echo "✅ Hosted Zone 생성 완료: $HOSTED_ZONE_ID"
  echo ""

  # 네임서버 출력
  echo "=========================================="
  echo "📋 Name Servers"
  echo "=========================================="
  echo ""
  echo "외부 도메인 등록업체(GoDaddy, Gabia 등)에서"
  echo "다음 네임서버로 변경해주세요:"
  echo ""
  aws route53 get-hosted-zone --id $HOSTED_ZONE_ID \
    --query "DelegationSet.NameServers[]" \
    --output text | tr '\t' '\n' | nl
  echo ""
  echo "⏱️  DNS 전파까지 1-2시간 소요됩니다."
  echo "=========================================="
  echo ""

  read -p "계속하시겠습니까? (y/n): " CONTINUE
  if [[ "$CONTINUE" != "y" ]]; then
    echo "중단되었습니다."
    exit 0
  fi
else
  echo "✅ Hosted Zone 발견: $HOSTED_ZONE_ID"
fi

echo ""

# 파일 백업
echo "💾 설정 파일 백업 중..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p backups

if [ -f "resources/.auto.tfvars" ]; then
  cp resources/.auto.tfvars backups/.auto.tfvars.${TIMESTAMP}
fi

if [ -f "resources/project" ]; then
  cp resources/project backups/project.${TIMESTAMP}
fi

echo "✅ 백업 완료: backups/ 디렉토리"
echo ""

# .auto.tfvars 업데이트
echo "📝 .auto.tfvars 파일 업데이트 중..."
if [ -f "resources/.auto.tfvars" ]; then
  # tzcorp_zone_id 업데이트
  if grep -q "tzcorp_zone_id" resources/.auto.tfvars; then
    sed -i.bak "s|tzcorp_zone_id = \"[^\"]*\".*|tzcorp_zone_id = \"${HOSTED_ZONE_ID}\"  # ${DOMAIN}|" resources/.auto.tfvars
  else
    echo "tzcorp_zone_id = \"${HOSTED_ZONE_ID}\"  # ${DOMAIN}" >> resources/.auto.tfvars
  fi

  # account_id 업데이트
  if grep -q "account_id" resources/.auto.tfvars; then
    sed -i.bak "s|account_id = \"[^\"]*\".*|account_id = \"${AWS_ACCOUNT_ID}\"|" resources/.auto.tfvars
  fi

  rm -f resources/.auto.tfvars.bak
  echo "✅ .auto.tfvars 업데이트 완료"
else
  echo "⚠️  .auto.tfvars 파일이 없습니다."
fi

echo ""

# project 파일 업데이트
echo "📝 project 파일 업데이트 중..."
if [ -f "resources/project" ]; then
  # domain 업데이트
  if grep -q "^domain=" resources/project; then
    sed -i.bak "s|^domain=.*|domain=${DOMAIN}|" resources/project
  else
    echo "domain=${DOMAIN}" >> resources/project
  fi

  # aws_account_id 업데이트
  if grep -q "^aws_account_id=" resources/project; then
    sed -i.bak "s|^aws_account_id=.*|aws_account_id=${AWS_ACCOUNT_ID}|" resources/project
  else
    echo "aws_account_id=${AWS_ACCOUNT_ID}" >> resources/project
  fi

  rm -f resources/project.bak
  echo "✅ project 파일 업데이트 완료"
else
  echo "⚠️  project 파일이 없습니다."
fi

echo ""

# DNS 설정 파일 생성
cat > dns_info.txt <<EOF
========================================
Route53 DNS 설정 정보
========================================
생성일: $(date)

도메인: ${DOMAIN}
Hosted Zone ID: ${HOSTED_ZONE_ID}
AWS Account ID: ${AWS_ACCOUNT_ID}
Cluster Name: ${CLUSTER_NAME}

Name Servers:
$(aws route53 get-hosted-zone --id $HOSTED_ZONE_ID --query "DelegationSet.NameServers[]" --output text | tr '\t' '\n')

========================================
설치 후 접속 가능한 서비스 URL
========================================

Jenkins:       https://jenkins.default.${CLUSTER_NAME}.${DOMAIN}
ArgoCD:        https://argocd.default.${CLUSTER_NAME}.${DOMAIN}
Grafana:       https://grafana.default.${CLUSTER_NAME}.${DOMAIN}
Prometheus:    https://prometheus.default.${CLUSTER_NAME}.${DOMAIN}
AlertManager:  https://alertmanager.default.${CLUSTER_NAME}.${DOMAIN}
Vault:         https://vault.default.${CLUSTER_NAME}.${DOMAIN}
Harbor:        https://harbor.devops.${CLUSTER_NAME}.${DOMAIN}
Nexus:         https://nexus.default.${CLUSTER_NAME}.${DOMAIN}

========================================
다음 단계
========================================
1. DNS 전파 확인 (1-2시간 소요):
   dig NS ${DOMAIN}

2. 전파 완료 후 클러스터 생성:
   bash bootstrap.sh

3. 설치 진행 상황 모니터링:
   kubectl get pods --all-namespaces

========================================
EOF

echo "✅ DNS 정보 저장: dns_info.txt"
echo ""

# 결과 출력
echo "=========================================="
echo "✅ 설정 완료!"
echo "=========================================="
echo ""
echo "📋 현재 설정:"
echo "  - AWS Account ID: ${AWS_ACCOUNT_ID}"
echo "  - Domain: ${DOMAIN}"
echo "  - Hosted Zone ID: ${HOSTED_ZONE_ID}"
echo "  - Cluster Name: ${CLUSTER_NAME}"
echo ""
echo "📁 업데이트된 파일:"
echo "  - resources/.auto.tfvars"
echo "  - resources/project"
echo ""
echo "💾 백업 위치:"
echo "  - backups/.auto.tfvars.${TIMESTAMP}"
echo "  - backups/project.${TIMESTAMP}"
echo ""
echo "📄 추가 정보:"
echo "  - dns_info.txt (DNS 설정 및 서비스 URL)"
echo ""

# DNS 전파 확인
echo "🔍 DNS 전파 확인 중..."
CURRENT_NS=$(dig NS ${DOMAIN} +short 2>/dev/null | head -n 1)
if [[ -n "$CURRENT_NS" ]]; then
  if [[ "$CURRENT_NS" == *"awsdns"* ]]; then
    echo "✅ DNS 전파 완료! Route53 네임서버 적용됨."
    echo ""
    echo "🚀 다음 명령어로 클러스터를 생성하세요:"
    echo "   bash bootstrap.sh"
  else
    echo "⏱️  DNS가 아직 전파되지 않았습니다."
    echo "   현재 네임서버: $CURRENT_NS"
    echo "   1-2시간 후에 다시 확인하세요."
    echo ""
    echo "   확인 명령어: dig NS ${DOMAIN}"
  fi
else
  echo "⏱️  DNS 전파 대기 중..."
  echo "   1-2시간 후에 확인하세요."
  echo ""
  echo "   확인 명령어: dig NS ${DOMAIN}"
fi

echo ""
echo "=========================================="
echo "완료!"
echo "=========================================="

