```
date ; oc apply -f https://github.com/instana/instana-agent-operator/releases/download/v2.2.12/instana-agent-operator.yaml

date ; oc delete -f https://github.com/instana/instana-agent-operator/releases/download/v2.2.12/instana-agent-operator.yaml


instana-agent-operator.yaml

oc project instana-agent

oc apply -f instana-agent-operator.yaml

Warning: resource namespaces/instana-agent is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by oc apply. oc apply should only be used on resources created declaratively by either oc create --save-config or oc apply. The missing annotation will be patched automatically.










apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: instana-agent-operator
  name: instana-agent-controller-manager
  namespace: instana-agent
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: instana-agent-operator
  template:
    metadata:
      labels:
        app.kubernetes.io/name: instana-agent-operator
    spec:
      nodeSelector:
        instana: enable
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values:
                - linux
            - matchExpressions:
              - key: kubernetes.io/arch
                operator: In
                values:
                - amd64
                - ppc64le
                - s390x
                - arm64
      containers:
      - args:
        - --leader-elect
        command:
        - /manager
        env:
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        image: icr.io/instana/instana-agent-operator:2.2.12
        imagePullPolicy: Always
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8081
          initialDelaySeconds: 15
          periodSeconds: 20
        name: manager
        readinessProbe:
          httpGet:
            path: /readyz
            port: 8081
          initialDelaySeconds: 5
          periodSeconds: 10
        resources:
          limits:
            cpu: 200m
            memory: 600Mi
          requests:
            cpu: 200m
            memory: 200Mi
        securityContext:
          allowPrivilegeEscalation: true
      serviceAccountName: instana-agent-operator
      terminationGracePeriodSeconds: 10
```
