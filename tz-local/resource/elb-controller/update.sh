#https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/docs/deploy/installation.md

cd /topzone/tz-local/resource/elb-controller

# bash /topzone/tz-local/resource/elb-controller/update.sh tzcorp.com

AWS_REGION=$(prop 'config' 'region')
eks_domain=$(prop 'project' 'domain')
eks_project=$(prop 'project' 'project')
aws_account_id=$(aws sts get-caller-identity --query Account --output text)

NS=default

##### test #####
HOSTZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name == '${eks_domain}.']" | grep '"Id"'  | awk '{print $2}' | sed 's/\"//g;s/,//' | cut -d'/' -f3)
echo $HOSTZONE_ID

DEVOPS_ELB=$(kubectl get svc | grep ingress-nginx-controller | head -n 1 | awk '{print $4}')
if [[ "${DEVOPS_ELB}" == "" ]]; then
  echo "No elb! check nginx-ingress-controller with LoadBalancer type!"
  exit 1
fi
echo "DEVOPS_ELB: $DEVOPS_ELB"
# Creates route 53 records based on DEVOPS_ELB
CUR_ELB=$(aws route53 list-resource-record-sets --hosted-zone-id ${HOSTZONE_ID} --query "ResourceRecordSets[?Name == '\\052.${NS}.${eks_project}.${eks_domain}.']" | grep 'Value' | awk '{print $2}' | sed 's/"//g')
echo "CUR_ELB: $CUR_ELB"
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTZONE_ID} \
 --change-batch '{ "Comment": "'"${eks_project}"' utils", "Changes": [{"Action": "DELETE", "ResourceRecordSet": {"Name": "*.'"${NS}"'.'"${eks_project}"'.'"${eks_domain}"'", "Type": "CNAME", "TTL": 120, "ResourceRecords": [{"Value": "'"${CUR_ELB}"'"}]}}]}'
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTZONE_ID} \
 --change-batch '{ "Comment": "'"${eks_project}"' utils", "Changes": [{"Action": "CREATE", "ResourceRecordSet": { "Name": "*.'"${NS}"'.'"${eks_project}"'.'"${eks_domain}"'", "Type": "CNAME", "TTL": 120, "ResourceRecords": [{"Value": "'"${DEVOPS_ELB}"'"}]}}]}'

CM_ARN=$(aws acm list-certificates --query CertificateSummaryList[].[CertificateArn,DomainName] \
  --certificate-statuses ISSUED --output text | grep "*.${eks_domain}" | cut -f1 | head -n 1)
echo "CM_ARN: $CM_ARN"

cp test2.yaml test2.yaml_bak
sed -i "s|AWS_REGION|${AWS_REGION}|g" test2.yaml_bak
sed -i "s|CM_ARN|${CM_ARN}|g" test2.yaml_bak
sed -i "s|aws_account_id|${aws_account_id}|g" test2.yaml_bak

kubectl delete -f test2.yaml_bak
kubectl delete -f test.yaml

kubectl apply -f test.yaml
kubectl apply -f test2.yaml_bak

sleep 60

kubectl get ingress
kubectl get svc | grep ingress-external

echo "curl http://test1.${eks_domain}"
curl -v http://test1.${eks_domain}

kubectl delete -f test2.yaml_bak
kubectl delete -f test.yaml







