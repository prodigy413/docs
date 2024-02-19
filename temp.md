~~~
app/main.py
from os import environ
from fastapi import FastAPI
import asyncio

app = FastAPI()

@app.get("/{sec}/{id}")
async def five(sec: int, id: int):
    await asyncio.sleep(sec)
    try:
        PODNAME = environ["HOSTNAME"]
    except KeyError:
        PODNAME = "Anonymous"
    return {
        "time": f"{sec}s",
        "podname": PODNAME,
        "id": id
        }





Dockerfile
FROM python:3.11.7-slim

WORKDIR /app

COPY ./requirements.txt /code/requirements.txt

RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

COPY ./app /app

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]




requirements.txt
fastapi
uvicorn
asyncio




test.yaml
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
  name: nginx
  namespace: istio-test
spec:
  selector:
    app: nginx
  ports:
  - name: http
    port: 80
    #targetPort: 80
    targetPort: 8000
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
      annotations:
        proxy.istio.io/config: |
          drainDuration: 59s
          proxyMetadata:
            EXIT_ON_ZERO_ACTIVE_CONNECTIONS: 'true'
#          terminationDrainDuration: 10s
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: nginx
        #image: nginx:1.25.3
        image: prodigy413/test-fastapi:1.0
        #imagePullPolicy: IfNotPresent
        imagePullPolicy: Always
        ports:
        - name: http
          #containerPort: 80
          containerPort: 8000
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 50"]
---
apiVersion: v1
kind: Pod
metadata:
  name: network01
  labels:
    name: network
  namespace: istio-test
spec:
  containers:
  - name: network
    image: prodigy413/network-client:1.0
---
apiVersion: v1
kind: Pod
metadata:
  name: network02
  labels:
    name: network
  namespace: istio-test
spec:
  containers:
  - name: network
    image: prodigy413/network-client:1.0
---
apiVersion: v1
kind: Pod
metadata:
  name: network03
  labels:
    name: network
  namespace: istio-test
spec:
  containers:
  - name: network
    image: prodigy413/network-client:1.0
# while true ; do curl -sI http://nginx.istio-test | head -n 1 ; sleep 1 ; done
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
            name: nginx
            port:
              number: 80




drain_test.md
### Commands

~~~
kubectl apply -f test.yaml ; kubectl -n istio-test get pod -w
kubectl delete -f test.yaml ; kubectl -n istio-test get pod -w

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
~~~

~~~
date ; kubectl -n istio-test rollout restart deployment nginx ; kubectl -n istio-test get pod -w

~~~

~~~
kubectl -n istio-test get pod

~~~

### Summary

- terminationDrainDuration
  - Default graceful termination period is 5s.
  - Same as terminationGracePeriodSeconds.
  - Overrided by EXIT_ON_ZERO_ACTIVE_CONNECTIONS
~~~
