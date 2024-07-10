~~~
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app: cronjob
  name: cronjob
  namespace: test-ns
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  labels:
    app: cronjob
  name: cronjob
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["delete", "list"]
- apiGroups: ["apps"]
  resources: ["statefulsets"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    app: cronjob
  name: cronjob
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: cronjob
subjects:
- kind: ServiceAccount
  name: cronjob
---
apiVersion: batch/v1
kind: CronJob
metadata:
  labels:
    app: cronjob
  name: restart-resource
  namespace: test-ns
spec:
  timeZone: "Asia/Tokyo"
  schedule: "01 23 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: kubectl
            image: bitnami/kubectl:latest
            imagePullPolicy: IfNotPresent
            command:
            - /bin/sh
            - -c
            - |
              kubectl -n test-ns delete pod -l name=test-statefulset --wait=false
              kubectl -n test-ns delete pod -l name=test-statefulset-02 --wait=false
              kubectl -n test-ns rollout status sts test-statefulset --timeout=1200s
              kubectl -n test-ns rollout status sts test-statefulset-02 --timeout=1200s
          restartPolicy: OnFailure
          serviceAccountName: cronjob





apiVersion: v1
kind: Namespace
metadata:
  name: test-ns
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-delpoyment
  labels:
    name: test-delpoyment
    app: deployment
  namespace: test-ns
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
    name: test-statefulset
    app: statefulset
  namespace: test-ns
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
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: test-statefulset-02
  labels:
    name: test-statefulset-02
    app: statefulset
  namespace: test-ns
spec:
  selector:
    matchLabels:
      name: test-statefulset-02
      app: statefulset
  replicas: 2
  template:
    metadata:
      labels:
        name: test-statefulset-02
        app: statefulset
    spec:
      terminationGracePeriodSeconds: 15
      #serviceAccountName: test
      containers:
      - name: nginx01
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent




kubectl -n test-ns apply -f ms.yaml
kubectl -n test-ns apply -f cronjob.yaml
kubectl -n test-ns get cronjob
kubectl -n test-ns get pod

kubectl -n test-ns delete -f ms.yaml
kubectl -n test-ns delete -f cronjob.yaml

~~~
