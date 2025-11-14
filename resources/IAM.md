⏺ AWS의 모든 리소스를 삭제하여 과금을 중지하는 방법을 안내드리겠습니다:

1. 주요 과금 리소스 삭제 순서

컴퓨팅 리소스

# EC2 인스턴스 확인 및 종료 (모든 리전)
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table
aws ec2 terminate-instances --instance-ids <instance-id>

# ECS/EKS 클러스터 삭제
aws ecs list-clusters
aws eks list-clusters

# Lambda 함수 삭제
aws lambda list-functions

데이터베이스

# RDS 인스턴스 삭제 (스냅샷 없이)
aws rds describe-db-instances
aws rds delete-db-instance --db-instance-identifier <id> --skip-final-snapshot

# DynamoDB 테이블 삭제
aws dynamodb list-tables

스토리지

# S3 버킷 비우기 및 삭제
aws s3 ls
aws s3 rm s3://bucket-name --recursive
aws s3 rb s3://bucket-name

# EBS 볼륨 삭제
aws ec2 describe-volumes
aws ec2 delete-volume --volume-id <vol-id>

# EBS 스냅샷 삭제
aws ec2 describe-snapshots --owner-ids self

네트워크

# 로드밸런서 삭제
aws elbv2 describe-load-balancers
aws elb describe-load-balancers

# Elastic IP 해제
aws ec2 describe-addresses
aws ec2 release-address --allocation-id <eip-id>

# NAT Gateway 삭제
aws ec2 describe-nat-gateways

2. 모든 리전 확인 필수

# 모든 리전 목록 확인
aws ec2 describe-regions --query 'Regions[*].RegionName' --output text

# 각 리전별로 리소스 확인
for region in $(aws ec2 describe-regions --query 'Regions[*].RegionName' --output text); do
echo "Checking $region"
aws ec2 describe-instances --region $region
done

3. AWS Nuke 도구 사용 (자동화)

모든 리소스를 한번에 삭제하려면:

# aws-nuke 설치 (주의: 매우 위험)
brew install aws-nuke

# config 파일 생성 후 실행
aws-nuke -c config.yaml --profile your-profile

4. AWS 콘솔에서 확인할 항목

1. Billing Dashboard → Cost Explorer에서 과금 항목 확인
2. Resource Groups & Tag Editor → 모든 리소스 검색
3. CloudFormation → 스택 삭제
4. Route53 → 호스팅 존 삭제 (도메인당 $0.50/월)
5. CloudWatch → 로그 그룹, 알람 삭제

5. 숨겨진 과금 항목

- Elastic IP (사용하지 않는 경우 과금)
- NAT Gateway (시간당 과금)
- RDS 스냅샷
- EBS 스냅샷
- S3 버킷 (데이터 저장)
- Route53 호스팅 존
- CloudWatch Logs 보관


1. 루트 계정 또는 관리자 계정 사용 (권장)

# AWS 프로필 확인
aws configure list

# 다른 프로필 사용 (관리자 권한이 있는 경우)
aws configure --profile admin
aws ec2 describe-instances --profile admin

2. IAM 권한 추가 필요

AWS 콘솔에서 루트 계정으로 로그인하여:

1. IAM Console → Users → codesonic 선택
2. Permissions 탭에서 다음 정책 중 하나 추가:
   - AdministratorAccess (전체 권한)
   - PowerUserAccess (IAM 제외 전체 권한)
   - 또는 커스텀 정책:

{
"Version": "2012-10-17",
"Statement": [
{
"Effect": "Allow",
"Action": [
"ec2:Describe*",
"ec2:TerminateInstances",
"ec2:DeleteVolume",
"s3:*",
"rds:Describe*",
"rds:DeleteDBInstance",
"iam:GetUser"
],
"Resource": "*"
}
]
}

3. AWS 콘솔에서 직접 확인 (권한 불필요)

웹 브라우저로 https://console.aws.amazon.com 접속:

1. EC2 Dashboard → Instances
2. RDS → Databases
3. S3 → Buckets
4. Billing Dashboard → Bill Details (어떤 서비스가 과금되는지 확인)

4. Cost Explorer로 과금 항목 먼저 확인

# 이 명령은 다른 권한을 사용합니다
aws ce get-cost-and-usage \
--time-period Start=2025-11-01,End=2025-11-14 \
--granularity DAILY \
--metrics BlendedCost \
--group-by Type=SERVICE

5. 루트 계정 접속 방법

- 루트 이메일 주소로 로그인
- "Forgot password"로 비밀번호 재설정 가능
- 루트 계정으로 접속 후 IAM 사용자 권한 부여