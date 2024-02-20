~~~
### Commands

~~~
kubectl apply -f test.yaml ; kubectl -n istio-test get pod -w
kubectl delete -f test.yaml ; kubectl -n istio-test get pod -w

kubectl apply -f two_fastapi.yaml ; kubectl -n istio-test get pod -w
kubectl delete -f two_fastapi.yaml ; kubectl -n istio-test get pod -w

kubectl -n istio-test delete deploy nginx ; kubectl -n istio-test get pod -w

~~~

~~~
kubectl -n istio-test logs -f deploy/nginx -c istio-proxy

~~~

~~~
kubectl -n istio-test exec -it network -- bash

kubectl -n istio-test exec -it network01 -- bash

kubectl -n istio-test exec -it network02 -- bash

kubectl -n istio-test exec -it network02 -- bash

while true ; do echo -n "$(date) " ; curl -sI http://nginx.istio-test | head -n 1 ; sleep 1 ; done

i=1 ; while true ; do echo -n "$(date) " ; curl http://nginx.istio-test/five/$((i++)) ; echo ; done

i=1 ; while true ; do echo -n "$(date) " ; curl http://nginx.istio-test/ten/$((i++)) ; echo ; done

i=1 ; while true ; do echo -n "$(date) " ; curl http://nginx.istio-test/fifteen/$((i++)) ; echo ; done

i=1 ; while true ; do echo -n "$(date) " ; curl http://nginx.istio-test/1/$((i++)) ; echo ; sleep 1 ; done

i=1 ; while true ; do echo -n "$(date) " ; curl http://nginx.istio-test/15/$((i++)) ; echo ; sleep 1 ; done

i=1 ; while true ; do echo -n "$(date) " ; curl http://nginx.istio-test/30/$((i++)) ; echo ; sleep 1 ; done

i=1 ; while true ; do echo -n "$(date) " ; curl -X GET -I http://nginx.istio-test/0.1/$((i++)) ; echo ; sleep 1 ; done

i=1 ; while true ; do echo -n "$(date) " ; curl -X GET -I http://nginx.istio-test/15/$((i++)) ; echo ; sleep 1 ; done

i=1 ; while true ; do echo -n "$(date) " ; curl -X GET -I http://nginx.istio-test/30/$((i++)) ; echo ; sleep 1 ; done

i=1 ; while true ; do echo -n "$(date) " ; curl http://nginx.test.local/1/$((i++)) ; echo ; done

i=1 ; while true ; do echo -n "$(date) " ; curl http://nginx.test.local/15/$((i++)) ; echo ; sleep 1 ; done

i=1 ; while true ; do echo -n "$(date) " ; curl http://nginx.test.local/30/$((i++)) ; echo ; sleep 1 ; done

i=1 ; while true ; do echo -n "$(date) " ; curl http://nginx02/1/$((i++)) ; echo ; done

i=1 ; while true ; do echo -n "$(date) " ; curl http://nginx02/15/$((i++)) ; echo ; sleep 1 ; done

i=1 ; while true ; do echo -n "$(date) " ; curl http://nginx02/30/$((i++)) ; echo ; sleep 1 ; done
~~~

~~~
date ; kubectl -n istio-test rollout restart deployment nginx ; kubectl -n istio-test get pod -w

~~~

~~~
kubectl -n istio-test get pod

kubectl -n istio-test exec -it deploy/nginx01 -- bash

~~~

### Summary

- terminationDrainDuration
  - Default graceful termination period is 5s.
  - Same as terminationGracePeriodSeconds.
  - Overrided by EXIT_ON_ZERO_ACTIVE_CONNECTIONS





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
          drainDuration: 1s
          proxyMetadata:
            MINIMUM_DRAIN_DURATION: 30s
            EXIT_ON_ZERO_ACTIVE_CONNECTIONS: 'true'
#          terminationDrainDuration: 10s
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
              command: ["/bin/sh", "-c", "sleep 50"]
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
~~~
