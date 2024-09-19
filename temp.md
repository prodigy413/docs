~~~
obi@obi:~/test/infra-code/yaml/fluentbit/daemonset$ kubectl rollout restart deploy/fluentbit-receiver
deployment.apps/fluentbit-receiver restarted
obi@obi:~/test/infra-code/yaml/fluentbit/daemonset$ kubectl -n kube-system get ds fluent-bit 
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
fluent-bit   4         4         4       4            4           <none>          3h8m
obi@obi:~/test/infra-code/yaml/fluentbit/daemonset$ 
obi@obi:~/test/infra-code/yaml/fluentbit/daemonset$ kubectl -n kube-system get pod -l app=fluent-bit
NAME               READY   STATUS    RESTARTS   AGE
fluent-bit-d2dth   1/1     Running   0          124m
fluent-bit-fdx8t   1/1     Running   0          124m
fluent-bit-fvjfb   1/1     Running   0          124m
fluent-bit-m88x6   1/1     Running   0          124m
obi@obi:~/test/infra-code/yaml/fluentbit/daemonset$ 
obi@obi:~/test/infra-code/yaml/fluentbit/daemonset$ kubectl get deploy fluentbit-receiver 
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
fluentbit-receiver   1/1     1            1           3h9m
obi@obi:~/test/infra-code/yaml/fluentbit/daemonset$ kubectl get pod -l app=fluentbit-receiver
No resources found in default namespace.
obi@obi:~/test/infra-code/yaml/fluentbit/daemonset$ kubectl get pod -l app=fluent-bit
NAME                                  READY   STATUS    RESTARTS   AGE
fluentbit-receiver-69f79b4c7d-b77wh   1/1     Running   0          52m
obi@obi:~/test/infra-code/yaml/fluentbit/daemonset$ kubectl get svc
NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)     AGE
fluentbit-receiver   ClusterIP   10.101.248.218   <none>        24224/TCP   3h10m
kubernetes           ClusterIP   10.96.0.1        <none>        443/TCP     24d




fluentbit_receiver.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: fluentbit-receiver
  labels:
    name: fluentbit-receiver
    app: fluent-bit
spec:
  selector:
    matchLabels:
      name: fluentbit-receiver
      app: fluent-bit
  replicas: 1
  template:
    metadata:
      labels:
        name: fluentbit-receiver
        app: fluent-bit
    spec:
      containers:
      - name: fluentbit-receiver
        image: fluent/fluent-bit:3.1.7-amd64
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - name: config-receiver
          mountPath: /fluent-bit/etc
      volumes:
      - name: config-receiver
        configMap:
          name: config-receiver
---
apiVersion: v1
kind: Service
metadata:
  name: fluentbit-receiver
spec:
  selector:
    name: fluentbit-receiver
  ports:
  - name: port-for-get-logs
    port: 24224
    targetPort: 24224
---
apiVersion: v1
data:
  fluent-bit.conf: |
    [SERVICE]
        Flush     1
        Log_Level info
        Daemon    off

    [INPUT]
        Name   forward
        Listen 0.0.0.0
        Port   24224

    [FILTER]
        Name   lua
        Match  *
        script /fluent-bit/etc/custom_format.lua
        call   format_log

    [OUTPUT]
        Name          stdout
        Match         *
        Format        json_stream
        json_date_key false
  custom_format.lua: |
    function format_log(tag, timestamp, record)
        local new_record = {}
        new_record["log"] = string.format("%s %s %s %s",
                                          os.date("%Y-%m-%d %H:%M:%S", timestamp),
                                          record["kubernetes"]["namespace_name"],
                                          record["kubernetes"]["container_name"],
                                          record["message"])
        return 1, timestamp, new_record
    end
kind: ConfigMap
metadata:
  name: config-receiver






fluent_sender.yaml

apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluent-bit
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: fluent-bit
rules:
- apiGroups:
  - ""
  resources:
  - pods
  - namespaces
  verbs:
  - get
  - list
  - watch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: fluent-bit
roleRef:
  kind: ClusterRole
  name: fluent-bit
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: fluent-bit
  namespace: kube-system
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluent-bit
  namespace: kube-system
  labels:
    app: fluent-bit
spec:
  selector:
    matchLabels:
      app: fluent-bit
  template:
    metadata:
      labels:
        app: fluent-bit
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        effect: NoSchedule
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: fluent-bit
        image: fluent/fluent-bit:3.1.7-amd64
        resources:
          limits:
            cpu: 500m
            memory: 1000Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: dockercontainerlogdirectory
          mountPath: /var/log/pods
          readOnly: true
        - name: config
          mountPath: /fluent-bit/etc
          readOnly: true
      serviceAccountName: fluent-bit
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: dockercontainerlogdirectory
        hostPath:
          path: /var/log/pods
      - name: config
        configMap:
          name: config
---
apiVersion: v1
data:
  fluent-bit.conf: |
    [SERVICE]
        Flush     1
        Log_Level info
        Daemon    off
        Parsers_File parsers.conf

    [INPUT]
        Name             tail
        Path             /var/log/containers/*_test-ns-0*.log
        Parser           cri
        Tag              kube.*
        Refresh_Interval 5

    [FILTER]
        Name            kubernetes
        Match           kube.*
        Kube_Tag_Prefix kube.var.log.containers
        Buffer_Size     0
        Merge_Log       On
        Merge_Log_Key   log

    [OUTPUT]
        Name   forward
        Match  kube.*
        Host   fluentbit-receiver.default
        Port   24224
  parsers.conf: |
    [PARSER]
        Name        cri
        Format      regex
        #Regex       ^(?<time>.+) (?<stream>stdout|stderr) (?<logtag>.*) (?<log>.*)$
        Regex       ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>[^ ]*) (?<message>.*)$
        Time_Key    time
        Time_Format %Y-%m-%dT%H:%M:%S.%L%z
        Time_Keep   On
kind: ConfigMap
metadata:
  name: config
  namespace: kube-system




obi@obi:~$ kubectl logs -f deploy/fluentbit-receiver
Fluent Bit v3.1.7
* Copyright (C) 2015-2024 The Fluent Bit Authors
* Fluent Bit is a CNCF sub-project under the umbrella of Fluentd
* https://fluentbit.io

______ _                  _    ______ _ _           _____  __  
|  ___| |                | |   | ___ (_) |         |____ |/  | 
| |_  | |_   _  ___ _ __ | |_  | |_/ /_| |_  __   __   / /`| | 
|  _| | | | | |/ _ \ '_ \| __| | ___ \ | __| \ \ / /   \ \ | | 
| |   | | |_| |  __/ | | | |_  | |_/ / | |_   \ V /.___/ /_| |_
\_|   |_|\__,_|\___|_| |_|\__| \____/|_|\__|   \_/ \____(_)___/

[2024/09/19 16:37:40] [ info] [fluent bit] version=3.1.7, commit=c6e902a43a, pid=1
[2024/09/19 16:37:40] [ info] [storage] ver=1.5.2, type=memory, sync=normal, checksum=off, max_chunks_up=128
[2024/09/19 16:37:40] [ info] [cmetrics] version=0.9.5
[2024/09/19 16:37:40] [ info] [ctraces ] version=0.5.5
[2024/09/19 16:37:40] [ info] [input:forward:forward.0] initializing
[2024/09/19 16:37:40] [ info] [input:forward:forward.0] storage_strategy='memory' (memory only)
[2024/09/19 16:37:40] [ info] [input:forward:forward.0] listening on 0.0.0.0:24224
[2024/09/19 16:37:40] [ info] [sp] stream processor started
[2024/09/19 16:37:40] [ info] [output:stdout:stdout.0] worker #0 started
{"log":"2024-09-19 16:37:41 test-ns-02 nginx-02 127.0.0.1 - - [19/Sep/2024:16:37:41 +0000] \"HEAD / HTTP/1.1\" 200 0 \"-\" \"curl/7.88.1\" \"-\""}
{"log":"2024-09-19 16:37:41 test-ns-01 nginx-01 127.0.0.1 - - [19/Sep/2024:16:37:41 +0000] \"HEAD / HTTP/1.1\" 200 0 \"-\" \"curl/7.88.1\" \"-\""}
{"log":"2024-09-19 16:37:42 test-ns-01 nginx-01 127.0.0.1 - - [19/Sep/2024:16:37:42 +0000] \"HEAD / HTTP/1.1\" 200 0 \"-\" \"curl/7.88.1\" \"-\""}
{"log":"2024-09-19 16:37:42 test-ns-02 nginx-02 127.0.0.1 - - [19/Sep/2024:16:37:42 +0000] \"HEAD / HTTP/1.1\" 200 0 \"-\" \"curl/7.88.1\" \"-\""}
{"log":"2024-09-19 16:37:43 test-ns-01 nginx-01 127.0.0.1 - - [19/Sep/2024:16:37:43 +0000] \"HEAD / HTTP/1.1\" 200 0 \"-\" \"curl/7.88.1\" \"-\""}
{"log":"2024-09-19 16:37:43 test-ns-02 nginx-02 127.0.0.1 - - [19/Sep/2024:16:37:43 +0000] \"HEAD / HTTP/1.1\" 200 0 \"-\" \"curl/7.88.1\" \"-\""}
{"log":"2024-09-19 16:37:44 test-ns-01 nginx-01 127.0.0.1 - - [19/Sep/2024:16:37:44 +0000] \"HEAD / HTTP/1.1\" 200 0 \"-\" \"curl/7.88.1\" \"-\""}
{"log":"2024-09-19 16:37:44 test-ns-02 nginx-02 127.0.0.1 - - [19/Sep/2024:16:37:44 +0000] \"HEAD / HTTP/1.1\" 200 0 \"-\" \"curl/7.88.1\" \"-\""}
{"log":"2024-09-19 16:37:45 test-ns-02 nginx-02 127.0.0.1 - - [19/Sep/2024:16:37:45 +0000] \"HEAD / HTTP/1.1\" 200 0 \"-\" \"curl/7.88.1\" \"-\""}
{"log":"2024-09-19 16:37:46 test-ns-02 nginx-02 127.0.0.1 - - [19/Sep/2024:16:37:46 +0000] \"HEAD / HTTP/1.1\" 200 0 \"-\" \"curl/7.88.1\" \"-\""}
{"log":"2024-09-19 16:37:45 test-ns-01 nginx-01 127.0.0.1 - - [19/Sep/2024:16:37:45 +0000] \"HEAD / HTTP/1.1\" 200 0 \"-\" \"curl/7.88.1\" \"-\""}
{"log":"2024-09-19 16:37:47 test-ns-02 nginx-02 127.0.0.1 - - [19/Sep/2024:16:37:47 +0000] \"HEAD / HTTP/1.1\" 200 0 \"-\" \"curl/7.88.1\" \"-\""}
{"log":"2024-09-19 16:37:46 test-ns-01 nginx-01 127.0.0.1 - - [19/Sep/2024:16:37:46 +0000] \"HEAD / HTTP/1.1\" 200 0 \"-\" \"curl/7.88.1\" \"-\""}
{"log":"2024-09-19 16:37:47 test-ns-01 nginx-01 127.0.0.1 - - [19/Sep/2024:16:37:47 +0000] \"HEAD / HTTP/1.1\" 200 0 \"-\" \"curl/7.88.1\" \"-\""}
{"log":"2024-09-19 16:37:48 test-ns-02 nginx-02 127.0.0.1 - - [19/Sep/2024:16:37:48 +0000] \"HEAD / HTTP/1.1\" 200 0 \"-\" \"curl/7.88.1\" \"-\""}




Warning: EnvoyFilter exposes internal implementation details that may change at any time. Prefer other APIs if possible, and exercise extreme caution, especially around upgrades.

~~~
