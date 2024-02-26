~~~
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      app: nginx
#  serviceName: "nginx"
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        ports:
        - containerPort: 80
        volumeMounts:
        - name: data
          mountPath: /tmp
      initContainers:
      - name: initial-process
        image: ubuntu:22.04
        command: ['sh', '-c', '/mnt/script/initial-process.sh']
        envFrom:
        - configMapRef:
            name: common-env
        volumeMounts:
        - name: config
          mountPath: /mnt/script
        - name: data
          mountPath: /tmp
      volumes:
      - name: config
        configMap:
          name: config
          defaultMode: 0555
      - name: data
        emptyDir: {}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: common-env
data:
  CLUSTER: obi02
---
kind: ConfigMap
metadata:
  name: config
apiVersion: v1
data:
  initial-process.sh: |
    #!/bin/bash
    SET_INDEX=${HOSTNAME##*-}
    echo "Starting initializing for pod ${HOSTNAME}"
    if [[ $SET_INDEX = "0" && $CLUSTER = "obi01" ]]; then
        cp /mnt/script/set-0.conf /tmp/set.conf
        echo "Copy completed. (set-0.conf > set.conf)"
    elif [[ $SET_INDEX = "0" && $CLUSTER = "obi02" ]]; then
        cp /mnt/script/set-1.conf /tmp/set.conf
        echo "Copy completed. (set-1.conf > set.conf)"
    elif [[ $SET_INDEX = "1" && $CLUSTER = "obi01" ]]; then
        cp /mnt/script/set-2.conf /tmp/set.conf
        echo "Copy completed. (set-2.conf > set.conf)"
    elif [[ $SET_INDEX = "1" && $CLUSTER = "obi02" ]]; then
        cp /mnt/script/set-3.conf /tmp/set.conf
        echo "Copy completed. (set-3.conf > set.conf)"
    else
        echo "xxxxxxxxx"
        exit 1
    fi
  set-0.conf: |
    config-0
  set-1.conf: |
    config-1
  set-2.conf: |
    config-2
  set-3.conf: |
    config-3










kind: Namespace
apiVersion: v1
metadata:
  name: istio-test
  labels:
    name: istio-test
    istio-injection: enabled
---
apiVersion: v1
kind: Service
metadata:
  name: nginx01
  namespace: istio-test
spec:
  selector:
    app: nginx01
  ports:
  - name: http
    port: 80
    targetPort: 8000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx01
  labels:
    app: nginx01
  namespace: istio-test
spec:
  selector:
    matchLabels:
      app: nginx01
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx01
      annotations:
        proxy.istio.io/config: |
          proxyMetadata:
            EXIT_ON_ZERO_ACTIVE_CONNECTIONS: 'true'  
#            MINIMUM_DRAIN_DURATION: 20s
#            EXIT_ON_ZERO_ACTIVE_CONNECTIONS: 'true'         
#          terminationDrainDuration: 60s
#          drainDuration: 1s
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: nginx01
        image: prodigy413/test-fastapi:1.0
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 8000
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 20"]
---
apiVersion: v1
kind: Service
metadata:
  name: nginx02
  namespace: istio-test
spec:
  selector:
    app: nginx02
  ports:
  - name: http
    port: 80
    targetPort: 8000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx02
  labels:
    app: nginx02
  namespace: istio-test
spec:
  selector:
    matchLabels:
      app: nginx02
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx02
      annotations:
        proxy.istio.io/config: |
          drainDuration: 1s
          proxyMetadata:
            MINIMUM_DRAIN_DURATION: 30s
            EXIT_ON_ZERO_ACTIVE_CONNECTIONS: 'true'
#          terminationDrainDuration: 10s
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: nginx02
        image: prodigy413/test-fastapi:1.0
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 8000
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 50"]
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  namespace: istio-test
spec:
  ingressClassName: nginx
  rules:
  - host: nginx.test.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx01
            port:
              number: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx02
  namespace: istio-test
spec:
  ingressClassName: nginx
  rules:
  - host: nginx02.test.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx02
            port:
              number: 80













# Global Mesh Options

### ProxyConfig
[ProxyConfig](https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig)

- drainDuration
- terminationDrainDuration

# pilot-agent

### Environment variables
[Environment variables](https://istio.io/latest/docs/reference/commands/pilot-agent/#envvars)

- EXIT_ON_ZERO_ACTIVE_CONNECTIONS
- MINIMUM_DRAIN_DURATION

# テスト

- 設定に記載がない場合はデフォルト設定値利用
- 各設定のデフォルト値
  - drainDuration: 45s
  - terminationDrainDuration: 5s
  - MINIMUM_DRAIN_DURATION: 5s
  - EXIT_ON_ZERO_ACTIVE_CONNECTIONS: false
  - terminationGracePeriodSeconds: 30s
- テストのため、1と2番以外はterminationGracePeriodSeconds: 60sに設定
- inbound trafficがある場合は`in`に〇を/outbound trafficがある場合は`out`に〇をつける
- outbound trafficはDrain対象ではないため、コンテナが生きている限る、発生する

|No|項目|設定|in|out|結果|
|-|-|-|-|-|-|
|1|デフォルト設定|-|〇|〇|- 5秒後、Proxy終了<br>- PodはTGraceを待たずにコンテナ処理が終わりしたい終了|
|2|デフォルト設定|-|-|-|- 5秒後、Proxy終了<br>- PodはTGraceを待たずにコンテナ処理が終わりしたい終了|
|3|TDrainをTGraceより長く|terminationDrainDuration: 80s|〇|〇|- 60秒後、Proxy終了<br>- 処理完了してもTdrainは待機しようとし、TGraceにより強制終了|
|4|TDrainをTGraceより長く|terminationDrainDuration: 80s|-|-|- 60秒後、Proxy終了<br>- 処理完了してもTdrainは待機しようとし、TGraceにより強制終了|
|5|MINIMUM_DRAIN_DURATIONのみ01<br>- MINIMUMをTGraceより短く|MINIMUM_DRAIN_DURATION: 20s|〇|〇|- 5秒後、Proxy終了<br>- PodはTGraceを待たずにコンテナ処理が終わりしたい終了|
|6|MINIMUM_DRAIN_DURATIONのみ02<br>- MINIMUMをTGraceより長く|MINIMUM_DRAIN_DURATION: 80s|〇|〇|- 5秒後、Proxy終了<br>- PodはTGraceを待たずにコンテナ処理が終わりしたい終了|
|7|MINIMUM_DRAIN_DURATIONのみ03<br>- MINIMUMをTGraceより短く|MINIMUM_DRAIN_DURATION: 20s|-|-|- 5秒後、Proxy終了<br>- PodはTGraceを待たずにコンテナ処理が終わりしたい終了|
|8|MINIMUM_DRAIN_DURATIONのみ04<br>- MINIMUMをTGraceより長く|MINIMUM_DRAIN_DURATION: 80s|-|-|- 5秒後、Proxy終了<br>- PodはTGraceを待たずにコンテナ処理が終わりしたい終了|
|9|EXIT_ON + drain<br>- TDrainをTGraceより長く|terminationDrainDuration: 80s<br>EXIT_ON_ZERO_ACTIVE_CONNECTIONS: true|〇|〇|- Connectionが終了したらProxy終了<br>- 60秒後、Proxy強制終了<br>- 最終的にTGraceで強制終了するが、メインコンテナが終了してもProxy側のActive Connectionの終了までProxyが死なない|
|10|EXIT_ON + drain<br>- TDrainをTGraceより短く|EXIT_ON_ZERO_ACTIVE_CONNECTIONS: true|〇|〇|- 上記と同じ結果|
|11|EXIT_ON + drain<br>- TDrainをTGraceより長く|terminationDrainDuration: 60s<br>EXIT_ON_ZERO_ACTIVE_CONNECTIONS: true|-|-|- 上記と同じ結果|
|12|EXIT_ON + drain<br>- TDrainをTGraceより短く|EXIT_ON_ZERO_ACTIVE_CONNECTIONS: true|-|-|- 上記と同じ結果|
~~~
