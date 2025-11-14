#!/bin/bash

echo "=========================================="
echo "AWS Credentials 자동 설정"
echo "=========================================="
echo ""

PROJECT_DIR="/Users/codesonic/Documents/Workspace/KUBE/tz-eks-main"
CRED_FILE="${PROJECT_DIR}/resources/credentials"

# 파일 백업
if [ -f "$CRED_FILE" ]; then
  BACKUP_FILE="${CRED_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
  cp "$CRED_FILE" "$BACKUP_FILE"
  echo "✅ 기존 파일 백업: $BACKUP_FILE"
  echo ""
fi

echo "AWS Access Key를 입력하세요."
echo "IAM User의 Security credentials에서 생성할 수 있습니다."
echo ""
echo "📝 Access Key 생성 방법:"
echo "  1. AWS Console → IAM → Users"
echo "  2. 사용자 선택 → Security credentials 탭"
echo "  3. Create access key 클릭"
echo ""

# 단일 계정 사용 여부
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "모든 프로파일에 동일한 Access Key를 사용하시겠습니까?"
echo "  (y) 동일한 Key 사용 (간단)"
echo "  (n) 프로파일별 개별 설정 (보안 강화)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -p "선택 (y/n): " USE_SINGLE

if [[ "$USE_SINGLE" == "y" ]]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Access Key 정보 입력"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  read -p "AWS Access Key ID (AKIA...): " SINGLE_KEY_ID
  read -sp "AWS Secret Access Key: " SINGLE_SECRET_KEY
  echo ""
  echo ""

  # 입력 검증
  if [[ -z "$SINGLE_KEY_ID" || -z "$SINGLE_SECRET_KEY" ]]; then
    echo "❌ Access Key를 모두 입력해야 합니다."
    exit 1
  fi

  # 파일 생성
  cat > "$CRED_FILE" <<EOF
[default]
aws_access_key_id = $SINGLE_KEY_ID
aws_secret_access_key = $SINGLE_SECRET_KEY

[topzone-k8s]
aws_access_key_id = $SINGLE_KEY_ID
aws_secret_access_key = $SINGLE_SECRET_KEY

[topzone-k8s-admin]
aws_access_key_id = $SINGLE_KEY_ID
aws_secret_access_key = $SINGLE_SECRET_KEY

[topzone-k8s-dev]
aws_access_key_id = $SINGLE_KEY_ID
aws_secret_access_key = $SINGLE_SECRET_KEY

EOF

  echo "✅ 모든 프로파일에 동일한 Access Key 설정 완료"

else
  # 프로파일별 개별 설정
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "프로파일별 개별 설정"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  > "$CRED_FILE"

  # default 프로파일
  echo ""
  echo "[1/4] default - 기본 프로파일"
  read -p "  AWS Access Key ID: " DEFAULT_KEY_ID
  read -sp "  AWS Secret Access Key: " DEFAULT_SECRET_KEY
  echo ""

  cat >> "$CRED_FILE" <<EOF
[default]
aws_access_key_id = $DEFAULT_KEY_ID
aws_secret_access_key = $DEFAULT_SECRET_KEY

EOF

  # topzone-k8s 프로파일
  echo ""
  echo "[2/4] topzone-k8s - 클러스터 관리용"
  echo "  default와 동일한 Key를 사용하시겠습니까? (y/n)"
  read -p "  선택: " USE_DEFAULT_K8S

  if [[ "$USE_DEFAULT_K8S" == "y" ]]; then
    K8S_KEY_ID="$DEFAULT_KEY_ID"
    K8S_SECRET_KEY="$DEFAULT_SECRET_KEY"
  else
    read -p "  AWS Access Key ID: " K8S_KEY_ID
    read -sp "  AWS Secret Access Key: " K8S_SECRET_KEY
    echo ""
  fi

  cat >> "$CRED_FILE" <<EOF
[topzone-k8s]
aws_access_key_id = $K8S_KEY_ID
aws_secret_access_key = $K8S_SECRET_KEY

EOF

  # topzone-k8s-admin 프로파일
  echo ""
  echo "[3/4] topzone-k8s-admin - 관리자 권한"
  echo "  default와 동일한 Key를 사용하시겠습니까? (y/n)"
  read -p "  선택: " USE_DEFAULT_ADMIN

  if [[ "$USE_DEFAULT_ADMIN" == "y" ]]; then
    ADMIN_KEY_ID="$DEFAULT_KEY_ID"
    ADMIN_SECRET_KEY="$DEFAULT_SECRET_KEY"
  else
    read -p "  AWS Access Key ID: " ADMIN_KEY_ID
    read -sp "  AWS Secret Access Key: " ADMIN_SECRET_KEY
    echo ""
  fi

  cat >> "$CRED_FILE" <<EOF
[topzone-k8s-admin]
aws_access_key_id = $ADMIN_KEY_ID
aws_secret_access_key = $ADMIN_SECRET_KEY

EOF

  # topzone-k8s-dev 프로파일
  echo ""
  echo "[4/4] topzone-k8s-dev - 개발자 권한"
  echo "  default와 동일한 Key를 사용하시겠습니까? (y/n)"
  read -p "  선택: " USE_DEFAULT_DEV

  if [[ "$USE_DEFAULT_DEV" == "y" ]]; then
    DEV_KEY_ID="$DEFAULT_KEY_ID"
    DEV_SECRET_KEY="$DEFAULT_SECRET_KEY"
  else
    read -p "  AWS Access Key ID: " DEV_KEY_ID
    read -sp "  AWS Secret Access Key: " DEV_SECRET_KEY
    echo ""
  fi

  cat >> "$CRED_FILE" <<EOF
[topzone-k8s-dev]
aws_access_key_id = $DEV_KEY_ID
aws_secret_access_key = $DEV_SECRET_KEY

EOF

  echo ""
  echo "✅ 프로파일별 개별 설정 완료"
fi

# 파일 권한 설정
chmod 600 "$CRED_FILE"
echo "✅ 파일 권한 설정 완료 (600)"

echo ""
echo "=========================================="
echo "✅ 설정 완료!"
echo "=========================================="
echo ""
echo "📁 파일 위치: $CRED_FILE"
echo ""
echo "🔍 설정된 프로파일:"
cat "$CRED_FILE" | grep '^\['
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 테스트 명령어:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  # Identity 확인"
echo "  aws sts get-caller-identity"
echo ""
echo "  # 프로파일별 확인"
echo "  aws sts get-caller-identity --profile topzone-k8s"
echo "  aws sts get-caller-identity --profile topzone-k8s-admin"
echo "  aws sts get-caller-identity --profile topzone-k8s-dev"
echo ""
echo "  # EKS 클러스터 목록"
echo "  aws eks list-clusters --region ap-northeast-2"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 자동 테스트 여부
read -p "지금 바로 테스트하시겠습니까? (y/n): " RUN_TEST

if [[ "$RUN_TEST" == "y" ]]; then
  echo ""
  echo "🔍 테스트 중..."
  echo ""

  if aws sts get-caller-identity 2>/dev/null; then
    echo ""
    echo "✅ 인증 성공!"
    echo ""

    # Account ID 추출
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
    if [[ -n "$ACCOUNT_ID" ]]; then
      echo "📋 AWS Account ID: $ACCOUNT_ID"

      # project 파일에 Account ID 업데이트
      PROJECT_FILE="${PROJECT_DIR}/resources/project"
      if [ -f "$PROJECT_FILE" ]; then
        if grep -q "^aws_account_id=" "$PROJECT_FILE"; then
          sed -i.bak "s/^aws_account_id=.*/aws_account_id=${ACCOUNT_ID}/" "$PROJECT_FILE"
          rm -f "${PROJECT_FILE}.bak"
          echo "✅ project 파일의 aws_account_id도 자동 업데이트되었습니다."
        fi
      fi
    fi
  else
    echo ""
    echo "❌ 인증 실패!"
    echo ""
    echo "다음을 확인하세요:"
    echo "  1. Access Key ID가 올바른지 확인"
    echo "  2. Secret Access Key가 올바른지 확인"
    echo "  3. IAM User가 활성화되어 있는지 확인"
    echo "  4. 인터넷 연결 확인"
  fi
fi

echo ""
echo "🚀 다음 단계: bash bootstrap.sh"
echo ""

