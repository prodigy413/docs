~~~
ms.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-delpoyment
  labels:
    name: test-delpoyment
    app: deployment
spec:
  selector:
    matchLabels:
      name: test-delpoyment
      app: deployment
  replicas: 2
  template:
    metadata:
      labels:
        name: test-delpoyment
        app: deployment
    spec:
      terminationGracePeriodSeconds: 15
      #serviceAccountName: test
      containers:
      - name: nginx01
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
      - name: nginx02
        image: ubuntu:24.04
        imagePullPolicy: IfNotPresent
        command:
        - sh
        - -c
        - |
          touch /tmp/test.txt
          sleep infinity
        readinessProbe:
          exec:
            command: ["cat", "/tmp/test.txt"]
          initialDelaySeconds: 10
          periodSeconds: 10
          failureThreshold: 2
          timeoutSeconds: 5
          successThreshold: 1
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: test-statefulset
  labels:
    name: test-delpoyment
    app: statefulset
spec:
  selector:
    matchLabels:
      name: test-statefulset
      app: statefulset
  replicas: 2
  template:
    metadata:
      labels:
        name: test-statefulset
        app: statefulset
    spec:
      terminationGracePeriodSeconds: 15
      #serviceAccountName: test
      containers:
      - name: nginx01
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
      - name: nginx02
        image: ubuntu:24.04
        imagePullPolicy: IfNotPresent
        command:
        - sh
        - -c
        - |
          touch /tmp/test.txt
          sleep infinity
        readinessProbe:
          exec:
            command: ["cat", "/tmp/test.txt"]
          initialDelaySeconds: 10
          periodSeconds: 10
          failureThreshold: 2
          timeoutSeconds: 5
          successThreshold: 1





test.sh

#!/bin/bash

#echo "date ; kubectl apply -f ms.yaml ; kubectl get pod -w"
#date ; kubectl apply -f ms.yaml ; kubectl get pod -w

echo -e "\n\n####################"
echo "# Deployment normal"
echo -e "####################\n"

echo "##################################################"
echo "date ; kubectl scale sts test-statefulset --replicas 0"
date ; kubectl scale sts test-statefulset --replicas 0

sleep 60

echo -e "\n##################################################"
echo "date ; kubectl get deploy,sts,pod"
date ; kubectl get deploy,sts,pod

echo -e "\n##################################################"
echo "date ; kubectl scale sts test-statefulset --replicas 2"
date ; kubectl scale sts test-statefulset --replicas 2

sleep 60

echo -e "\n##################################################"
echo "date ; kubectl get deploy,sts,pod"
date ; kubectl get deploy,sts,pod

echo -e "\n\n####################"
echo "# StatefulSet normal"
echo -e "####################\n"

echo "##################################################"
echo "date ; kubectl rollout restart sts test-statefulset"
date ; kubectl rollout restart sts test-statefulset

sleep 60

echo -e "\n##################################################"
echo "date ; kubectl get deploy,sts,pod"
date ; kubectl get deploy,sts,pod

echo -e "\n##################################################"
echo "date ; kubectl scale deploy test-delpoyment --replicas 0"
date ; kubectl scale deploy test-delpoyment --replicas 0

sleep 60

echo -e "\n##################################################"
echo "date ; kubectl get deploy,sts,pod"
date ; kubectl get deploy,sts,pod

echo -e "\n##################################################"
echo "date ; kubectl scale deploy test-delpoyment --replicas 2"
date ; kubectl scale deploy test-delpoyment --replicas 2

sleep 60

echo -e "\n##################################################"
echo "date ; kubectl get deploy,sts,pod"
date ; kubectl get deploy,sts,pod

echo -e "\n##################################################"
echo "date ; kubectl rollout restart deploy test-delpoyment"
date ; kubectl rollout restart deploy test-delpoyment

sleep 60

echo -e "\n##################################################"
echo "date ; kubectl get deploy,sts,pod"
date ; kubectl get deploy,sts,pod

echo -e "\n\n####################"
echo "# Deployment abnormal"
echo -e "####################\n"

echo "##################################################"
echo "date ; PODS=\$(kubectl get pod -l app=deployment -oname) ; echo \${PODS}"
date ; PODS=$(kubectl get pod -l app=deployment -oname) ; echo ${PODS}

echo -e "\n##################################################"
echo "date ; for POD in \${PODS} ; do kubectl exec \${POD} -c nginx02 -- rm -rf /tmp/test.txt ; done"
date ; for POD in ${PODS} ; do kubectl exec ${POD} -c nginx02 -- rm -rf /tmp/test.txt ; done

sleep 30

echo -e "\n##################################################"
echo "date ; kubectl get deploy,sts,pod"
date ; kubectl get deploy,sts,pod

echo -e "\n##################################################"
echo "date ; kubectl scale deploy test-delpoyment --replicas 0"
date ; kubectl scale deploy test-delpoyment --replicas 0

sleep 60

echo -e "\n##################################################"
echo "date ; kubectl get deploy,sts,pod"
date ; kubectl get deploy,sts,pod

echo -e "\n##################################################"
echo "date ; kubectl scale deploy test-delpoyment --replicas 2"
date ; kubectl scale deploy test-delpoyment --replicas 2

sleep 60

echo -e "\n##################################################"
echo "date ; kubectl get deploy,sts,pod"
date ; kubectl get deploy,sts,pod

echo -e "\n##################################################"
echo "date ; PODS=\$(kubectl get pod -l app=deployment -oname) ; echo \${PODS}"
date ; PODS=$(kubectl get pod -l app=deployment -oname) ; echo ${PODS}

echo -e "\n##################################################"
echo "date ; for POD in \${PODS} ; do kubectl exec \${POD} -c nginx02 -- rm -rf /tmp/test.txt ; done"
date ; for POD in ${PODS} ; do kubectl exec ${POD} -c nginx02 -- rm -rf /tmp/test.txt ; done

sleep 30

echo -e "\n##################################################"
echo "date ; kubectl get deploy,sts,pod"
date ; kubectl get deploy,sts,pod

echo -e "\n##################################################"
echo "date ; kubectl rollout restart deploy test-delpoyment"
date ; kubectl rollout restart deploy test-delpoyment

sleep 60

echo -e "\n##################################################"
echo "date ; kubectl get deploy,sts,pod"
date ; kubectl get deploy,sts,pod

echo -e "\n\n####################"
echo "# StatefulSet abnormal"
echo -e "####################\n"

echo "##################################################"
echo "date ; PODS=\$(kubectl get pod -l app=statefulset -oname) ; echo \${PODS}"
date ; PODS=$(kubectl get pod -l app=statefulset -oname) ; echo ${PODS}

echo -e "\n##################################################"
echo "date ; for POD in \${PODS} ; do kubectl exec \${POD} -c nginx02 -- rm -rf /tmp/test.txt ; done"
date ; for POD in ${PODS} ; do kubectl exec ${POD} -c nginx02 -- rm -rf /tmp/test.txt ; done

sleep 30

echo -e "\n##################################################"
echo "date ; kubectl get deploy,sts,pod"
date ; kubectl get deploy,sts,pod

echo -e "\n##################################################"
echo "date ; kubectl scale sts test-statefulset --replicas 0"
date ; kubectl scale sts test-statefulset --replicas 0

sleep 60

echo -e "\n##################################################"
echo "date ; kubectl get deploy,sts,pod"
date ; kubectl get deploy,sts,pod

echo -e "\n##################################################"
echo "date ; kubectl scale sts test-statefulset --replicas 2"
date ; kubectl scale sts test-statefulset --replicas 2

sleep 60

echo -e "\n##################################################"
echo "date ; kubectl get deploy,sts,pod"
date ; kubectl get deploy,sts,pod

echo -e "\n##################################################"
echo "date ; kubectl rollout restart sts test-statefulset"
date ; kubectl rollout restart sts test-statefulset

sleep 60

echo -e "\n##################################################"
echo "date ; kubectl get deploy,sts,pod"
date ; kubectl get deploy,sts,pod

echo -e "\n##################################################"
echo "date ; PODS=\$(kubectl get pod -l app=statefulset -oname) ; echo \${PODS}"
date ; PODS=$(kubectl get pod -l app=statefulset -oname) ; echo ${PODS}

echo -e "\n##################################################"
echo "date ; for POD in \${PODS} ; do kubectl delete \${POD} --grace-period 0 --force ; done"
date ; for POD in ${PODS} ; do kubectl delete ${POD} --grace-period 0 --force ; done

sleep 60

echo -e "\n##################################################"
echo "date ; kubectl get deploy,sts,pod"
date ; kubectl get deploy,sts,pod





#!/bin/bash

# Run kubectl command to get pods with label app=test
output=$(kubectl get pod -l app=test)

# Check if the output contains "No resources found"
if [[ "$output" == *"No resources found"* ]]; then
  echo "No pods found."
  exit 1  # Exit with a non-zero status
else
  echo "Pods found:"
  echo "$output"
fi
~~~
