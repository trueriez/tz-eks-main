# Docker Hub Password 획득 및 설정 가이드

## 📋 목차
1. [Docker Hub Password란?](#docker-hub-password란)
2. [Docker Hub 계정 생성](#docker-hub-계정-생성)
3. [비밀번호 확인/재설정](#비밀번호-확인재설정)
4. [Access Token 생성 (권장)](#access-token-생성-권장)
5. [프로젝트 설정](#프로젝트-설정)
6. [테스트 방법](#테스트-방법)
7. [트러블슈팅](#트러블슈팅)

---

## Docker Hub Password란?

### 개요
**Docker Hub**는 Docker 이미지를 저장하고 공유하는 클라우드 기반 레지스트리 서비스입니다.

### 용도
- **Public/Private 이미지** Pull (다운로드)
- **이미지 Push** (업로드)
- **Rate Limit 회피** (인증 없이는 6시간당 100회 제한)

### 프로젝트에서의 사용
```bash
# 현재 설정
dockerhub_id=trueriez
dockerhub_password=xxxxxxxxxxx  # ← 여기에 실제 비밀번호 필요
```

**사용되는 곳:**
- Jenkins 빌드 시 이미지 Push
- Kubernetes에서 Private 이미지 Pull
- Docker Compose 빌드

---

## Docker Hub 계정 생성

### 1. 회원가입

**웹사이트 방문:**
```
https://hub.docker.com/signup
```

**입력 정보:**
- **Docker ID**: `trueriez` (이미 생성됨)
- **Email**: 본인 이메일 주소
- **Password**: 안전한 비밀번호 생성

**비밀번호 요구사항:**
- 최소 9자 이상
- 대문자, 소문자, 숫자 조합
- 특수문자 포함 권장

---

### 2. 이메일 인증

1. 가입 시 입력한 이메일 확인
2. Docker Hub에서 보낸 인증 메일 열기
3. "Verify email address" 버튼 클릭
4. 인증 완료

---

## 비밀번호 확인/재설정

### 현재 계정이 있는 경우

#### Option A: 비밀번호 기억하는 경우
- 로그인 테스트:
  ```bash
  docker login -u trueriez
  # Password 입력 후 성공하면 OK
  ```

#### Option B: 비밀번호 잊어버린 경우

**비밀번호 재설정:**

1. **Docker Hub 로그인 페이지 접속**
   ```
   https://hub.docker.com/
   ```

2. **"Sign in" 클릭**

3. **"Forgot password?" 클릭**

4. **이메일 주소 입력**
   - Docker ID: `trueriez`와 연결된 이메일 입력

5. **이메일 확인**
   - 받은 편지함에서 "Reset your Docker Hub password" 메일 확인
   - 스팸 메일함도 확인

6. **"Reset password" 링크 클릭**

7. **새 비밀번호 입력**
   - 새 비밀번호 입력
   - 비밀번호 확인
   - "Reset password" 버튼 클릭

8. **로그인 테스트**
   ```bash
   docker login -u trueriez
   Password: [새 비밀번호 입력]
   ```

---

## Access Token 생성 (권장)

### 왜 Access Token을 사용하나?

**비밀번호 대신 Access Token 사용의 장점:**
- ✅ **보안 강화**: 실제 비밀번호 노출 방지
- ✅ **권한 제어**: Token별로 권한 설정 가능
- ✅ **쉬운 폐기**: Token만 삭제하면 접근 차단
- ✅ **만료 관리**: Token에 유효기간 설정 가능

---

### Access Token 생성 단계

#### 1. Docker Hub 로그인
```
https://hub.docker.com/
```
- Docker ID: `trueriez`
- Password: 본인 비밀번호

---

#### 2. Account Settings 접속

**방법 1:**
- 우측 상단 프로필 아이콘 클릭
- "Account Settings" 선택

**방법 2:**
- 직접 URL 접속:
  ```
  https://hub.docker.com/settings/security
  ```

---

#### 3. Security 탭 선택

좌측 메뉴에서 **"Security"** 클릭

---

#### 4. New Access Token 생성

1. **"New Access Token"** 버튼 클릭

2. **Token 정보 입력:**
   ```
   Access Token Description: kubernetes-cluster
   또는
   Access Token Description: topzone-k8s-cluster
   ```

3. **Access permissions 선택:**
   - **Read & Write** (권장) - 이미지 Pull/Push 가능
   - Read only - 이미지 Pull만 가능
   - Admin - 모든 권한

4. **"Generate"** 버튼 클릭

---

#### 5. Token 복사 및 저장

⚠️ **중요**: Token은 생성 직후 한 번만 표시됩니다!

**Token 형식:**
```
dckr_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**즉시 복사하여 안전한 곳에 저장:**

```bash
# 임시 메모
Token: dckr_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxx
Created: 2025-11-14
Purpose: Kubernetes cluster image pull/push
```

---

#### 6. Token 테스트

```bash
# Access Token으로 로그인
docker login -u trueriez
Password: [Token 입력: dckr_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxx]

# 성공 메시지:
# Login Succeeded
```

---

## 프로젝트 설정

### 1. project 파일 업데이트

**파일 위치:**
```
/Users/codesonic/Documents/Workspace/KUBE/tz-eks-main/resources/project
```

**현재 상태:**
```bash
dockerhub_id=trueriez
dockerhub_password=xxxxxxxxxxx  # ← 여기 업데이트 필요
```

---

### 2. 비밀번호/Token 입력

#### Option A: 실제 비밀번호 사용
```bash
dockerhub_id=trueriez
dockerhub_password=YourActualPassword123!
```

#### Option B: Access Token 사용 (권장)
```bash
dockerhub_id=trueriez
dockerhub_password=dckr_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

### 3. 자동 업데이트 스크립트

```bash
#!/bin/bash

cd /Users/codesonic/Documents/Workspace/KUBE/tz-eks-main

# Docker Hub 로그인 테스트
echo "Docker Hub에 로그인하여 자격 증명을 확인합니다..."
echo "Docker ID: trueriez"
echo ""

if docker login -u trueriez; then
  echo ""
  echo "✅ 로그인 성공!"
  echo ""
  read -p "입력한 비밀번호/Token을 project 파일에 저장하시겠습니까? (y/n): " CONFIRM
  
  if [[ "$CONFIRM" == "y" ]]; then
    # 비밀번호 다시 입력
    read -sp "Docker Hub Password/Token 입력: " DOCKERHUB_PASSWORD
    echo ""
    
    # 파일 백업
    cp resources/project resources/project.backup.$(date +%Y%m%d_%H%M%S)
    
    # project 파일 업데이트
    if grep -q "^dockerhub_password=" resources/project; then
      sed -i.bak "s|^dockerhub_password=.*|dockerhub_password=${DOCKERHUB_PASSWORD}|" resources/project
    else
      echo "dockerhub_password=${DOCKERHUB_PASSWORD}" >> resources/project
    fi
    
    rm -f resources/project.bak
    
    echo "✅ project 파일이 업데이트되었습니다."
    echo ""
    grep "dockerhub" resources/project
  fi
else
  echo ""
  echo "❌ 로그인 실패. 비밀번호를 확인하거나 Access Token을 생성하세요."
  echo ""
  echo "Access Token 생성: https://hub.docker.com/settings/security"
fi
```

**실행:**
```bash
chmod +x update_dockerhub.sh
./update_dockerhub.sh
```

---

### 4. 수동 업데이트

```bash
cd /Users/codesonic/Documents/Workspace/KUBE/tz-eks-main

# 1. 파일 백업
cp resources/project resources/project.backup

# 2. 파일 편집
vi resources/project

# 또는
nano resources/project

# 3. dockerhub_password 라인 수정
# dockerhub_password=xxxxxxxxxxx
# →
# dockerhub_password=dckr_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 4. 저장 및 확인
cat resources/project | grep dockerhub
```

---

## 테스트 방법

### 1. Docker CLI 로그인 테스트

```bash
# 비밀번호/Token으로 로그인
docker login -u trueriez
Password: [입력]

# 성공 시:
# Login Succeeded
# Logging in with your password grants your terminal complete access to your account.
# For better security, log in with a limited-privilege personal access token.

# 실패 시:
# Error response from daemon: Get https://registry-1.docker.io/v2/: unauthorized
```

---

### 2. 이미지 Pull 테스트

```bash
# Public 이미지 (인증 없이 가능)
docker pull hello-world

# Private 이미지 (인증 필요)
docker pull trueriez/my-private-image
```

---

### 3. 이미지 Push 테스트

```bash
# 테스트 이미지 생성
docker tag hello-world trueriez/test-image:latest

# Docker Hub에 Push
docker push trueriez/test-image:latest

# 성공 시:
# The push refers to repository [docker.io/trueriez/test-image]
# ...
# latest: digest: sha256:xxxxx size: 1234
```

---

### 4. Kubernetes에서 테스트

```bash
# Docker Hub 자격 증명으로 Secret 생성
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=index.docker.io \
  --docker-username=trueriez \
  --docker-password=[your-password-or-token] \
  --docker-email=your-email@example.com \
  -n default

# Secret 확인
kubectl get secret dockerhub-secret -o yaml
```

---

## 프로젝트에서의 사용

### 1. Docker Compose에서 사용

```bash
# tz-local/docker/install.sh
dockerhub_id=$(prop 'project' 'dockerhub_id')
dockerhub_password=$(prop 'project' 'dockerhub_password')

# Docker 로그인
docker login -u="${dockerhub_id}" -p="${dockerhub_password}"
```

---

### 2. Kubernetes Secret 생성

```bash
# docker-repo/install.sh
kubectl create secret docker-registry registry-creds \
  --docker-server=index.docker.io \
  --docker-username=${dockerhub_id} \
  --docker-password=${dockerhub_password} \
  --docker-email=${dockerhub_email} \
  -n default
```

---

### 3. Jenkins에서 사용

```groovy
// Jenkinsfile
environment {
    DOCKER_REGISTRY = 'index.docker.io'
    DOCKER_CREDENTIALS = credentials('dockerhub-creds')
}

stages {
    stage('Docker Login') {
        steps {
            sh '''
                echo $DOCKER_CREDENTIALS_PSW | docker login -u $DOCKER_CREDENTIALS_USR --password-stdin $DOCKER_REGISTRY
            '''
        }
    }
}
```

---

## 보안 권장 사항

### 1. Access Token 사용 (비밀번호 대신)

**이유:**
- 비밀번호 노출 시 전체 계정 위험
- Token은 권한 제한 가능
- Token은 언제든지 폐기 가능

---

### 2. Token 관리

```bash
# Token 목록 확인
# Docker Hub → Settings → Security → Access Tokens

# 사용하지 않는 Token 삭제
# Token 옆의 휴지통 아이콘 클릭

# Token 만료 일자 설정
# Token 생성 시 유효기간 설정
```

---

### 3. .gitignore 설정

```bash
# .gitignore 파일에 추가
resources/project
resources/credentials
*.password
*.token
```

---

### 4. 환경 변수 사용 (CI/CD)

```bash
# Jenkins/GitHub Actions 등에서
# Secret 변수로 저장
DOCKERHUB_USERNAME=trueriez
DOCKERHUB_PASSWORD=[Token]
```

---

## 트러블슈팅

### 문제 1: 로그인 실패

**증상:**
```
Error response from daemon: Get https://registry-1.docker.io/v2/: unauthorized
```

**해결 방법:**
1. **비밀번호 확인**
   ```bash
   docker login -u trueriez
   ```
2. **대소문자 확인** (비밀번호는 대소문자 구분)
3. **공백 제거** (비밀번호 앞뒤 공백 확인)

---

### 문제 2: Rate Limit 초과

**증상:**
```
ERROR: toomanyrequests: You have reached your pull rate limit
```

**해결 방법:**
1. **로그인하여 Rate Limit 증가**
   ```bash
   docker login
   ```
   - 인증 없이: 6시간당 100회
   - 인증 후: 6시간당 200회
   - Pro 계정: 무제한

2. **다른 Registry 사용**
   - GitHub Container Registry (ghcr.io)
   - AWS ECR
   - Harbor (Self-hosted)

---

### 문제 3: Token이 작동하지 않음

**증상:**
```
Login did not succeed, error: Error response from daemon: Get https://registry-1.docker.io/v2/: unauthorized
```

**해결 방법:**
1. **Token 권한 확인**
   - Read & Write 권한 필요
2. **Token 유효기간 확인**
3. **Token 재생성**

---

### 문제 4: 이메일 인증 안 됨

**증상:**
계정 생성 후 이메일 인증 메일이 오지 않음

**해결 방법:**
1. **스팸 메일함 확인**
2. **이메일 재전송**
   - Docker Hub → Settings → Email → Resend verification email
3. **다른 이메일 주소 사용**

---

## 현재 설정 확인

### project 파일 현재 상태

```bash
cd /Users/codesonic/Documents/Workspace/KUBE/tz-eks-main
cat resources/project | grep dockerhub
```

**출력:**
```
dockerhub_id=trueriez
dockerhub_password=xxxxxxxxxxx  # ← 업데이트 필요
```

---

### 업데이트 후 확인

```bash
# 1. Docker 로그인 테스트
docker login -u trueriez

# 2. 로그인 정보 확인
cat ~/.docker/config.json

# 3. 이미지 Pull 테스트
docker pull nginx:latest
```

---

## 빠른 시작 가이드

### 3분 완성 가이드

1. **Docker Hub 로그인**
   ```
   https://hub.docker.com/
   ```

2. **Access Token 생성**
   - Settings → Security → New Access Token
   - Description: `kubernetes-cluster`
   - Permissions: Read & Write
   - Generate 클릭

3. **Token 복사**
   ```
   dckr_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

4. **project 파일 업데이트**
   ```bash
   vi /Users/codesonic/Documents/Workspace/KUBE/tz-eks-main/resources/project
   
   # 수정:
   dockerhub_password=dckr_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

5. **테스트**
   ```bash
   docker login -u trueriez
   Password: [Token 붙여넣기]
   ```

6. **완료!** ✅

---

## FAQ

### Q1: 비밀번호와 Access Token 중 어느 것을 사용해야 하나요?
**A**: **Access Token 사용을 강력히 권장합니다.** 보안상 더 안전하고 관리가 용이합니다.

### Q2: Access Token은 어디서 확인할 수 있나요?
**A**: Token 생성 시 한 번만 표시됩니다. 분실 시 재생성해야 합니다.

### Q3: 무료 계정으로 충분한가요?
**A**: 네, 무료 계정으로도 충분합니다. Private 레포지토리 1개와 충분한 Rate Limit을 제공합니다.

### Q4: Docker Hub 말고 다른 Registry를 사용할 수 있나요?
**A**: 네, 프로젝트에서 Harbor를 설치하여 Self-hosted Registry를 구축할 수 있습니다.

### Q5: Token의 유효기간은?
**A**: 기본적으로 무기한이지만, 생성 시 유효기간을 설정할 수 있습니다.

---

## 체크리스트

Docker Hub 설정 전:

- [ ] Docker Hub 계정 생성 완료 (`trueriez`)
- [ ] 이메일 인증 완료
- [ ] Access Token 생성 완료
- [ ] Token 안전한 곳에 저장 완료
- [ ] `docker login` 테스트 성공
- [ ] `project` 파일에 Token 입력 완료
- [ ] 파일 백업 완료

---

## 참고 자료

### 공식 문서
- [Docker Hub](https://hub.docker.com/)
- [Docker Hub Access Tokens](https://docs.docker.com/docker-hub/access-tokens/)
- [Docker Login](https://docs.docker.com/engine/reference/commandline/login/)

### 프로젝트 파일
```
tz-eks-main/resources/
├── project                 # ← dockerhub_password 설정
├── config
└── credentials

tz-eks-main/tz-local/docker/
└── install.sh             # ← Docker Hub 로그인 사용
```

### 대안 Registry
- **GitHub Container Registry**: ghcr.io
- **Amazon ECR**: AWS Elastic Container Registry
- **Harbor**: Self-hosted (프로젝트에 포함)
- **Nexus**: Artifact Repository (프로젝트에 포함)

---

**작성일**: 2025년 11월 14일  
**Docker Hub ID**: trueriez  
**프로젝트**: KUBE (tz-eks-main)  
**권장**: Access Token 사용

---

## 다음 단계

1. ✅ **Access Token 생성** → https://hub.docker.com/settings/security
2. ✅ **project 파일 업데이트** → `dockerhub_password=dckr_pat_xxxxx`
3. ✅ **로그인 테스트** → `docker login -u trueriez`
4. 🚀 **클러스터 생성** → `bash bootstrap.sh`

