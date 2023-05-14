~~~
### Configmap
apiVersion: v1
kind: Pod
metadata:
  name: sample
spec:
  containers:
    - name: sample
      image: sample
      env:
        - name: TEST
          valueFrom:
            configMapKeyRef:
              name: sample
              key: test
      volumeMounts:
      - name: config
        mountPath: "/config"
        readOnly: true
  volumes:
    - name: config
      configMap:
        name: test
        items:
        - key: "test.properties"
          path: "test.properties"
---
apiVersion: v1
kind: Pod
metadata:
  name: sample
spec:
  containers:
  - name: sample
    image: sample
    volumeMounts:
    - name: foo
      mountPath: "/etc/foo"
      readOnly: true
  volumes:
  - name: foo
    configMap:
      name: sample
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: sample
data:
  test: "3"
  test.properties: |
    enemy.types=aliens,monsters
    player.maximum-lives=5    


### cronjob
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: cron
spec:
  schedule: "*/1 * * * *"
  # concurrencyPolicy: Allow / Forbid / Replace
  startingDeadlineSeconds: 100
  successfulJobsHistoryLimit: 5
  failedJobsHistoryLimit: 5
  #suspend: true / false
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: sample
            image: sample:1.0
            imagePullPolicy: Always
            command: ["/bin/bash",  "-c", "/tmp/DeleteTaskrun.sh"]
          serviceAccountName: sample
          restartPolicy: Never


### daemonset
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-elasticsearch
  namespace: kube-system
  labels:
    k8s-app: fluentd-logging
spec:
  selector:
    matchLabels:
      name: fluentd-elasticsearch
  template:
    metadata:
      labels:
        name: fluentd-elasticsearch
    spec:
      tolerations:
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      containers:
      - name: fluentd-elasticsearch
        image: quay.io/fluentd_elasticsearch/fluentd:v2.5.2
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      terminationGracePeriodSeconds: 30
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers


### deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
  labels:
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx-pc
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: nginx-pc
    spec:
      terminationGracePeriodSeconds: 30
      serviceAccountName: mbadev
      containers:
      - name: nginx-ctn
        image: prodigy413/nginx-1.17.9-net:1.0
        imagePullPolicy: IfNotPresent # Always / IfNotPresent / Never
        command: ["/bin/bash",  "-c", "/tmp/DeleteTaskrun.sh"]
        lifecycle:
          postStart:
            exec:
              command: ["/bin/sh", "-c", "echo Hello from the postStart handler > /proc/1/fd/1"]
          preStop:
            exec:
              command: ["/usr/sbin/nginx","-s","quit"]
#          postStart:
#            exec:
#              command:
#                - /bin/sh
#                - -c
#                - |
#                  echo hook postStart.
#                  date
#                  exit 0
#          preStop:
#            exec:
#              command:
#                - /bin/sh
#                - -c
#                - |
#                  echo hook preStop.
#                  sleep 40
#                  exit 0
#          limits:
#            memory: "128Mi"
#            cpu: "500m"
#        lifecycle:
#          preStop:
#            exec:
#              command: ["sh", "-c", "sleep 40"]
#              command: ["sh", "-c", "/tmp/test.sh"]
#      terminationGracePeriodSeconds: 60
        ports:
        - name: http
          containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        volumeMounts:
        - name: v1-volume
          mountPath: /usr/share/nginx/html
        - name: sub-test
          mountPath: /usr/share/nginx/html
          subPath: test.sh
        env:
        - name: TZ
          value: "Asia/Tokyo"
        envFrom:
        - configMapRef:
            name: test-cm
        - secretRef:
            name: test-secret-cm
        readinessProbe:
          exec:
            command:
            - /bin/bash
            - -c
            - test.sh
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 3
          timeoutSeconds: 1
          successThreshold: 1
        livenessProbe:
          exec:
            command:
            - /bin/bash
            - -c
            - test.sh
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 30
          timeoutSeconds: 1
          successThreshold: 1
      volumes:
      - name: v1-volume
        configMap:
          name: v1-configmap
      - name: empty-sample
        emptyDir: {}
      - name: sub-test
        configMap:
          name: v1-configmap
          defaultMode: 0755
          items:
          - key: deploy.sh
            path: deploy.sh
      - name: test-cm
        persistentVolumeClaim:
          claimName: nfs-pvc
      hostAliases:
      - ip: 192.168.245.111
        hostnames:
        - obi-nginx.test.local


### job
apiVersion: batch/v1
kind: Job
metadata:
  name: cron
  annotations:
      count: "3"
spec:
  backoffLimit: 5
  template:
    spec:
      containers:
      - name: sample
        image: sample:1.0
        imagePullPolicy: Always
        command: ["/bin/bash", "-c", "echo test ; exit 0"]
      restartPolicy: Never


### namespace
kind: Namespace
apiVersion: v1
metadata:
  name: sample
  labels:
    name: sample


### pod
apiVersion: v1
kind: Pod
metadata:
  name: sample
  labels:
    name: sample
spec:
  containers:
  - name: sample
    image: nginx:1.19.2


### sa
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sample
secrets:
  - name: sample


### secret
---
apiVersion: v1
kind: Pod
metadata:
  name: sample
spec:
  containers:
  - name: sample
    image: redis
    volumeMounts:
    - name: foo
      mountPath: "/etc/foo"
      readOnly: true
  volumes:
  - name: foo
    secret:
      secretName: sample
---
apiVersion: v1
kind: Pod
metadata:
  name: sample
spec:
  containers:
  - name: sample
    image: redis
    volumeMounts:
    - name: foo
      mountPath: "/etc/foo"
      readOnly: true
  volumes:
  - name: foo
    secret:
      secretName: sample
      items:
      - key: test
        path: my-group/my-username
---
apiVersion: v1
kind: Secret
metadata:
  name: sample
data:
  test: YWRtaW4=
type: Opaque
---
apiVersion: v1
kind: Secret
metadata:
  name: sample2
stringData:
  test: 1234
type: Opaque


### service
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx
  type: ClusterIP
  #type: NodePort
  #type: LoadBalancer
  ports:
  - name: http
    protocol: TCP
    port: 8080
    targetPort: 80
    #nodePort: 30007
  - name: https
    protocol: TCP
    port: 8443
    targetPort: 443
  clusterIP: 10.43.230.2
  #clusterIP: None
status:
  loadBalancer:
    ingress:
    - ip: 192.0.2.127

~~~
