~~~
while sleep 0.01 ; do curl -s http://nginx > /dev/null ; done












cpu.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        ports:
        - name: http
          containerPort: 80
        resources:
          requests:
            memory: 64Mi
            cpu: 250m
          limits:
            memory: 128Mi
            cpu: 500m
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: network
  labels:
    name: network
spec:
  containers:
  - name: network
    image: prodigy413/network-client:1.0
    imagePullPolicy: IfNotPresent
---
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: cpu-scaledobject
spec:
  scaleTargetRef:
    name: nginx               # Name of resource not label!!
  minReplicaCount: 1
  maxReplicaCount: 3
  triggers:
  - type: cpu
    metricType: Utilization
    metadata:
      value: "50"            # Percentage of requests not limits








datadog.yaml

kind: Namespace
apiVersion: v1
metadata:
  name: istio-test
  labels:
    name: istio-test
    istio-injection: enabled
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
  namespace: istio-test
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        ports:
        - name: http
          containerPort: 80
        resources:
          requests:
            memory: 64Mi
            cpu: 250m
          limits:
            memory: 128Mi
            cpu: 500m
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: istio-test
spec:
  selector:
    app: nginx
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: network
  labels:
    name: network
  namespace: istio-test
spec:
  containers:
  - name: network
    image: prodigy413/network-client:1.0
    imagePullPolicy: IfNotPresent
---
apiVersion: v1
data:
  apiKey: xxxxxxxxxxxxxxxxxxxx
  appKey: xxxxxxxxxxxxxxxxxxxxxxxxxxx
  datadogSite: xxxxxxxxxxxxxxxxxxxxxxxxx
kind: Secret
metadata:
  name: datadog-secrets
  namespace: istio-test
---
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: keda-trigger-auth-datadog-secret
  namespace: istio-test
spec:
  secretTargetRef:
  - parameter: apiKey
    name: datadog-secrets
    key: apiKey
  - parameter: appKey
    name: datadog-secrets
    key: appKey
  - parameter: datadogSite
    name: datadog-secrets
    key: datadogSite
---
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: datadog-scaledobject
  namespace: istio-test
spec:
  scaleTargetRef:
    name: nginx
  minReplicaCount: 1
  maxReplicaCount: 5
  triggers:
  - type: datadog
    metricType: "AverageValue"
    metadata:
      query: "sum:istio.mesh.request.count.total{kube_namespace:istio-test, kube_deployment:nginx} by {kube_deployment}.as_count().rollup(sum, 60)"
      queryValue: "60"
    authenticationRef:
      name: keda-trigger-auth-datadog-secret





prometheus.yaml

kind: Namespace
apiVersion: v1
metadata:
  name: istio-test
  labels:
    name: istio-test
    istio-injection: enabled
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
  namespace: istio-test
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        ports:
        - name: http
          containerPort: 80
        resources:
          requests:
            memory: 64Mi
            cpu: 250m
          limits:
            memory: 128Mi
            cpu: 500m
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: istio-test
spec:
  selector:
    app: nginx
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: network
  labels:
    name: network
  namespace: istio-test
spec:
  containers:
  - name: network
    image: prodigy413/network-client:1.0
    imagePullPolicy: IfNotPresent
---
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: prometheus-scaledobject
  namespace: istio-test
spec:
  scaleTargetRef:
    name: nginx
  minReplicaCount: 1
  maxReplicaCount: 5
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://prometheus.istio-system.svc:9090
      threshold: '60'
      query: sum by(app) (increase(istio_requests_total{namespace="istio-test", app="nginx"}[1m]))
      # sum is needed because KEDA doesn't get multiple values like 2 pods.
      # If 1 pod get more than 60 requests then add another pod.
      # If 2 pod get more than 120 requests then add another pod.

~~~
