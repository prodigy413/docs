### 落書き

- Scale「0」にするときは以下のようにannotationを追加してKedaの対象外にする。
  ~~~yaml
  apiVersion: keda.sh/v1alpha1
  kind: ScaledObject
  metadata:
    name: xxxxxxxxxx
    annotations:
      autoscaling.keda.sh/paused: "true"
  ..........
  ~~~

- `cooldownPeriod`設定
  - scale「0」時のみ変更可能
~~~
例：
以下のように「0」に戻るときはcooldownPeriod変更可能
minReplicaCount: 0
maxReplicaCount: 3

以下のように「0」以外に戻るときはcooldownPeriod変更不可
minReplicaCount: 1
maxReplicaCount: 3
~~~

### prometheus sample

### Link


~~~
$ kubectl -n istio-test get scaledobject
NAME         SCALETARGETKIND      SCALETARGETNAME   MIN   MAX   TRIGGERS     AUTHENTICATION   READY   ACTIVE   FALLBACK   PAUSED    AGE
prometheus   apps/v1.Deployment   nginx             1     5     prometheus                    True    False    False      Unknown   7m27s

$ kubectl -n istio-test get hpa
NAME                  REFERENCE          TARGETS      MINPODS   MAXPODS   REPLICAS   AGE
keda-hpa-prometheus   Deployment/nginx   0/60 (avg)   1         5         1          7m38s

$ kubectl -n istio-test get pod -l app=nginx
NAME                     READY   STATUS    RESTARTS   AGE
nginx-7c4f949b5f-l7fx4   2/2     Running   0          2m29s
~~~

~~~
$ kubectl -n istio-test get scaledobject
NAME         SCALETARGETKIND      SCALETARGETNAME   MIN   MAX   TRIGGERS     AUTHENTICATION   READY   ACTIVE   FALLBACK   PAUSED    AGE
prometheus   apps/v1.Deployment   nginx             1     5     prometheus                    True    True     False      Unknown   28m

$ kubectl -n istio-test get hpa
NAME                  REFERENCE          TARGETS           MINPODS   MAXPODS   REPLICAS   AGE
keda-hpa-prometheus   Deployment/nginx   44889m/60 (avg)   1         5         3          28m

$ kubectl -n istio-test get pod -l app=nginx
NAME                     READY   STATUS    RESTARTS   AGE
nginx-7c4f949b5f-5rjpd   2/2     Running   0          4m13s
nginx-7c4f949b5f-l7fx4   2/2     Running   0          29m
nginx-7c4f949b5f-zqjpd   2/2     Running   0          3m13s
~~~

~~~
$ kubectl -n istio-test get pod -l app=nginx
NAME                     READY   STATUS    RESTARTS   AGE
nginx-7c4f949b5f-l7fx4   2/2     Running   0          39m
~~~

### cron sample

### Link

<https://keda.sh/docs/2.15/scalers/cron/>

~~~
kubectl -n istio-test apply -f cron.yaml
kubectl -n istio-test delete -f cron.yaml
~~~

~~~
kubectl -n istio-test get pod -w
~~~

~~~
kubectl -n istio-test get scaledobject
kubectl -n istio-test get hpa
kubectl -n istio-test get cronjob
~~~


~~~
obi@obi:~/test/infra-code/yaml/keda/02_cron$ date ; kubectl -n istio-test get pod -l app=nginx
Mon Sep 23 12:44:22 AM JST 2024
NAME                     READY   STATUS    RESTARTS   AGE
nginx-7c4f949b5f-rllhk   2/2     Running   0          21s

obi@obi:~/test/infra-code/yaml/keda/02_cron$ date ; kubectl -n istio-test get pod -l app=nginx
Mon Sep 23 12:45:53 AM JST 2024
NAME                     READY   STATUS    RESTARTS   AGE
nginx-7c4f949b5f-fj7lw   2/2     Running   0          52s
nginx-7c4f949b5f-qbpjn   2/2     Running   0          52s
nginx-7c4f949b5f-rllhk   2/2     Running   0          112s

$ date ; kubectl -n istio-test get pod -l app=nginx
Mon Sep 23 12:59:48 AM JST 2024
NAME                     READY   STATUS    RESTARTS   AGE
nginx-7c4f949b5f-rllhk   2/2     Running   0          15m


~~~


~~~yaml
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
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.27.1
        ports:
        - name: http
          containerPort: 80
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
  name: client
  labels:
    name: client
  namespace: istio-test
spec:
  containers:
  - name: network
    image: nginx:1.27.1
---
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: prometheus
  namespace: istio-test
  annotations:
    autoscaling.keda.sh/paused: "true"
#  annotations:
#    autoscaling.keda.sh/paused-replicas: "1" # Stop autoscaling after set replicas to 2
#    autoscaling.keda.sh/paused: "true" # Stop autoscaling
spec:
  scaleTargetRef:
    name: nginx
  minReplicaCount: 1
  maxReplicaCount: 5
  pollingInterval: 30 # Get metrcis data every 3os that means updat cache data every 3os
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

~~~yaml
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
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.27.1
        ports:
        - name: http
          containerPort: 80
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
  name: client
  labels:
    name: client
  namespace: istio-test
spec:
  containers:
  - name: network
    image: nginx:1.27.1
---
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: cron
  namespace: istio-test
spec:
  scaleTargetRef:
    name: nginx
  minReplicaCount: 1
  maxReplicaCount: 5
  cooldownPeriod: 10
  triggers:
  - type: cron
    metadata:
      timezone: Asia/Tokyo
      start: 45 0 * * *
      end: 50 0 * * *
      desiredReplicas: "3"
~~~

### Link

<https://keda.sh/docs/2.15/scalers/prometheus/>

~~~
kubectl -n istio-test apply -f prometheus.yaml
kubectl -n istio-test delete -f prometheus.yaml
~~~

~~~
kubectl -n istio-test exec client -- /bin/sh -c "while sleep 0.9 ; do curl -sI http://nginx | head -n 1 ; done"
~~~

~~~
kubectl -n istio-test get pod
kubectl -n istio-test get scaledobject
kubectl -n istio-test get hpa
~~~

~~~
$ kubectl -n istio-test get scaledobject
NAME         SCALETARGETKIND      SCALETARGETNAME   MIN   MAX   TRIGGERS     AUTHENTICATION   READY   ACTIVE   FALLBACK   PAUSED    AGE
prometheus   apps/v1.Deployment   nginx             1     5     prometheus                    True    False    False      Unknown   7m27s

$ kubectl -n istio-test get hpa
NAME                  REFERENCE          TARGETS      MINPODS   MAXPODS   REPLICAS   AGE
keda-hpa-prometheus   Deployment/nginx   0/60 (avg)   1         5         1          7m38s

$ kubectl -n istio-test get pod -l app=nginx
NAME                     READY   STATUS    RESTARTS   AGE
nginx-7c4f949b5f-l7fx4   2/2     Running   0          2m29s
~~~

~~~
$ kubectl -n istio-test get scaledobject
NAME         SCALETARGETKIND      SCALETARGETNAME   MIN   MAX   TRIGGERS     AUTHENTICATION   READY   ACTIVE   FALLBACK   PAUSED    AGE
prometheus   apps/v1.Deployment   nginx             1     5     prometheus                    True    True     False      Unknown   28m

$ kubectl -n istio-test get hpa
NAME                  REFERENCE          TARGETS           MINPODS   MAXPODS   REPLICAS   AGE
keda-hpa-prometheus   Deployment/nginx   44889m/60 (avg)   1         5         3          28m

$ kubectl -n istio-test get pod -l app=nginx
NAME                     READY   STATUS    RESTARTS   AGE
nginx-7c4f949b5f-5rjpd   2/2     Running   0          4m13s
nginx-7c4f949b5f-l7fx4   2/2     Running   0          29m
nginx-7c4f949b5f-zqjpd   2/2     Running   0          3m13s
~~~

~~~
$ kubectl -n istio-test get pod -l app=nginx
NAME                     READY   STATUS    RESTARTS   AGE
nginx-7c4f949b5f-l7fx4   2/2     Running   0          39m
~~~
