~~~
helm install logs-agent --dry-run oci://icr.io/ibm-observe/logs-agent-helm \
--version 1.6.3 --values logs-values.yaml -n ibm-observe --create-namespace

helm install logs-agent oci://icr.io/ibm-observe/logs-agent-helm \
--version 1.6.3 --values logs-values.yaml -n ibm-observe --create-namespace

ibmcloud ks cluster get -c test-cluster --output json | jq '{name: .name, crn: .crn}'

ibmcloud resource service-instances --service-name logs -g test -o json | jq '.[] | {name: .name, guid: .guid}'

ibmcloud iam trusted-profile-create test --description "test"

ibmcloud iam trusted-profile-policy-create test \
    --roles Sender \
    --service-name logs \
    --service-instance xxxxxxxxx

ibmcloud iam trusted-profile-rule-create test \
  --name iks-logs-agent \
  --type Profile-CR \
  --cr-type ROKS_SA \
  --conditions claim:crn,operator:EQUALS,value:xxxxxxxxxx \
  --conditions claim:namespace,operator:EQUALS,value:ibm-observe \
  --conditions claim:name,operator:EQUALS,value:logs-agent

ibmcloud iam trusted-profiles -o json | jq '.[] | {name: .name, id: .id}'
~~~
