```
ibmcloud oc worker-pool create vpc-gen2 \
--name test \
--cluster test-cluster \
--flavor bx3d.4x20 \
--size-per-zone 1 \
--operating-system REDHAT_8_64


ibmcloud oc worker-pool rm -p test -c test-cluster

ibmcloud oc worker-pool ls -c test-cluster


ibmcloud oc zone add vpc-gen2 \
  --cluster test-cluster \
  --worker-pool test \
  --zone jp-tok-1 \
  --subnet-id 02e7-8aea0c65-34cf-40f5-be15-242d2457d08e



oc delete pod -l deploymentconfig=nginx01

ibmcloud oc worker-pool get --cluster test-cluster --worker-pool default

ibmcloud oc worker-pool zones -c test-cluster -p default

ibmcloud oc worker-pool zones -c test-cluster -p test

oc get deploymentconfig,pods -owide

oc delete pod -l deploymentconfig=nginx01

oc exec -it deploymentconfig/nginx01 -- bash

oc -n default scale deploymentconfig --all --replicas 0
```

OpenJDK 8u372 to feature cgroup v2 support
https://developers.redhat.com/articles/2023/04/19/openjdk-8u372-feature-cgroup-v2-support
