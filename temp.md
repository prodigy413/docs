~~~
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx01
  labels:
    app: nginx01
spec:
  selector:
    matchLabels:
      app: nginx01
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx01
    spec:
      containers:
      - name: nginx01
        image: nginx:1.27.2
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        lifecycle:
          postStart:
            exec:
              command: ["/bin/sh", "-c", "touch /tmp/healthcheck.txt"]
        readinessProbe:
          exec:
            command: ["cat", "/tmp/healthcheck.txt"]
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 3
          timeoutSeconds: 1
          successThreshold: 1




kubectl exec deploy/nginx01 -- rm -rf /tmp/healthcheck.txt
kubectl exec deploy/nginx02 -- rm -rf /tmp/healthcheck.txt

kubectl scale deployment nginx01 --replicas 3
kubectl scale deployment nginx02 --replicas 3

kubectl scale deployment nginx01 --replicas 0
kubectl scale deployment nginx02 --replicas 0

kubectl rollout restart deploy nginx01 ; kubectl get pod -w
kubectl rollout restart deploy nginx02 ; kubectl get pod -w
~~~
