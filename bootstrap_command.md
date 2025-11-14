# bootstrap.sh 파일의 쉘스크립트 명령어 정리

## 1. 환경 변수 설정
```bash
export MSYS_NO_PATHCONV=1        # Windows Git Bash에서 경로 변환 비활성화
export tz_project=devops-utils   # 프로젝트 이름 변수 설정
```

## 2. 함수 정의
```bash
function cleanTfFiles() {        # Terraform 관련 파일 정리 함수
  rm -Rf [파일/디렉토리]         # -R: 재귀적 삭제, -f: 강제 삭제
}
```

## 3. Docker 명령어

### docker ps
```bash
docker ps                        # 실행 중인 컨테이너 목록 조회
```
**출력 예시:**
```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS   PORTS   NAMES
```

### docker exec
```bash
docker exec -it ${DOCKER_NAME} bash [스크립트]
# -i: interactive 모드 (표준 입력 유지)
# -t: tty 할당 (터미널 에뮬레이션)
# bash: 실행할 명령어
```

### docker container (주석 처리됨)
```bash
docker container stop $(docker container ls -a -q)  # 모든 컨테이너 중지
# -a: 모든 컨테이너
# -q: 컨테이너 ID만 출력

docker system prune -a -f --volumes                 # 시스템 정리
# -a: 사용하지 않는 모든 이미지 삭제
# -f: 확인 없이 강제 실행
# --volumes: 볼륨도 함께 삭제
```

## 4. 파이프라인 명령어

### grep
```bash
grep docker-${tz_project}        # 특정 문자열이 포함된 라인 필터링
```

### awk
```bash
awk '{print $1}'                 # 첫 번째 필드(컬럼) 출력
# $1: 첫 번째 필드 (여기서는 컨테이너 ID)
# $2: 두 번째 필드
# $0: 전체 라인
```

### 백틱 명령 치환
```bash
DOCKER_NAME=`docker ps | grep docker-${tz_project} | awk '{print $1}'`
# 백틱(`) 또는 $()를 사용하여 명령어 실행 결과를 변수에 저장
```

**파이프라인 흐름:**
```
docker ps → grep 필터링 → awk로 첫 컬럼 추출 → 변수 저장
```

## 5. 조건문

### if 문
```bash
if [[ 조건 ]]; then
  명령어
fi

# 조건 연산자:
# == : 같음
# != : 다름
# -z : 문자열이 비어있음
# && : AND 연산
# || : OR 연산
```

### 종료 상태 확인
```bash
if [[ $? != 0 ]]; then           # $?: 직전 명령어의 종료 상태 코드
  echo "failed to remove resources!"
  exit 1                          # 0이 아닌 값으로 종료 (오류)
fi
```

## 6. 디렉토리 관리

### pushd / popd
```bash
pushd `pwd`                      # 현재 디렉토리를 스택에 저장하고 이동
cd terraform-aws-eks/workspace/base
cleanTfFiles
popd                             # 스택에서 이전 디렉토리로 복귀
```

### cd
```bash
cd terraform-aws-iam/workspace/base   # 디렉토리 변경
```

## 7. 스크립트 실행

### bash
```bash
bash tz-local/docker/install.sh       # bash로 스크립트 실행
bash /topzone/scripts/eks_remove_all.sh
```

### 스크립트 인자
```bash
"$1"                             # 첫 번째 명령줄 인자
# 예: bash bootstrap.sh remove
#     → $1 = "remove"
```

## 8. 출력

### echo
```bash
echo "======= DOCKER_NAME: ${DOCKER_NAME}"   # 문자열 출력
echo docker exec -it ${DOCKER_NAME} bash ... # 명령어 표시용
```

## 9. 종료

### exit
```bash
exit 0                           # 성공적으로 종료 (상태 코드 0)
exit 1                           # 오류로 종료 (상태 코드 1)
```

## 10. 파일/디렉토리 삭제

### rm
```bash
rm -Rf kubeconfig_*              # -R: 재귀적, -f: 강제, *: 와일드카드
rm -Rf .terraform                # 숨김 디렉토리 삭제
rm -Rf terraform.tfstate         # 파일 삭제
```

## 스크립트 사용법 요약

### 1. 초기 설치 (인자 없음)
```bash
bash bootstrap.sh
```
→ `install.sh` 실행 → `init2.sh` 실행

### 2. 리소스 삭제
```bash
bash bootstrap.sh remove
```
→ 컨테이너가 있으면: `eks_remove_all.sh` 실행
→ 컨테이너가 없으면: Terraform 파일 직접 정리

### 3. 컨테이너 접속
```bash
bash bootstrap.sh sh
```
→ 도커 컨테이너 내부 bash 셸 실행

## 핵심 패턴

### 1. 명령 체인
```bash
docker ps | grep docker-${tz_project} | awk '{print $1}'
```
파이프(`|`)로 명령어를 연결하여 데이터 처리

### 2. 변수 참조
```bash
${DOCKER_NAME}                   # 변수 값 참조 (중괄호 사용 권장)
$1                               # 위치 매개변수
$?                               # 종료 상태 코드
```

### 3. 명령 치환
```bash
`명령어`                         # 백틱 (구식)
$(명령어)                        # 권장 방식
```

### 4. 조건부 실행
```bash
명령어1 && 명령어2                # 명령어1 성공 시 명령어2 실행
docker container stop ... && docker system prune ...
```

## 주의사항

1. **백틱 vs $()**: 현대적인 스크립트에서는 `$()`를 권장
2. **에러 처리**: `$?`로 명령 실행 결과 확인
3. **대화형 모드**: `docker exec -it`는 사용자 입력이 필요한 작업용
4. **강제 삭제**: `rm -Rf`는 위험할 수 있으므로 신중히 사용
