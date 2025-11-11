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

kubectl get cronjobs -A -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,ACTIVE_DEADLINE_SECONDS:.spec.jobTemplate.spec.activeDeadlineSeconds'

apiVersion: batch/v1
kind: CronJob
metadata:
  name: cron01
  labels:
    app: cronjob
spec:
  schedule: "*/2 * * * *"
  # concurrencyPolicy: Allow / Forbid / Replace
  startingDeadlineSeconds: 100
  successfulJobsHistoryLimit: 5
  failedJobsHistoryLimit: 5
  #suspend: true
  suspend: false
  jobTemplate:
    spec:
      activeDeadlineSeconds: 50
      template:
        spec:
          containers:
          - name: busybox
            image: busybox:1.28
            imagePullPolicy: Always
            #command: ["/bin/sh",  "-c", "sleep 120 ; echo test"]
            command: ["/bin/sh",  "-c"]
            args:
            - |
              i=1
              while [ "$i" -le 80 ]; do
                echo "Count: $i"
                i=$((i + 1))
                sleep 1
              done
          #serviceAccountName: cron-sa
          restartPolicy: Never
~~~
