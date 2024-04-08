<https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/><br>
<https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_next_upstream>

- proxy-next-upstream
- proxy-next-upstream-timeout
- proxy-next-upstream-tries

~~~yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: fastapi-ingress
  annotations:
    nginx.ingress.kubernetes.io/proxy-next-upstream: "error timeout http_503"
spec:
  ingressClassName: nginx
  rules:
..........
~~~

### Link

<https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/nginx-configuration/annotations.md>

### Get configuration

~~~
kubectl -n ingress-system exec test-ingress-nginx-controller-68f5b748cc-bz8jb -- cat /etc/nginx/nginx.conf
~~~

~~~yaml
# uvicorn normal:app --host 0.0.0.0 --port 8000
# uvicorn error:app --host 0.0.0.0 --port 8000
# curl http://192.168.245.111 -H 'host: fastapi.test.local'
# while true ; do date ; curl http://192.168.245.111 -H 'host: fastapi.test.local' ; echo ; sleep 1 ; done
# while true ; do date ; curl -X GET -sI http://192.168.245.111 -H 'host: fastapi.test.local' | head -1 ; echo ; sleep 1 ; done

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: fastapi-ingress
  annotations:
    nginx.ingress.kubernetes.io/proxy-next-upstream: "error timeout http_503"
spec:
  ingressClassName: nginx
  rules:
  - host: fastapi.test.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: fastapi
            port:
              number: 8000
---
apiVersion: v1
kind: Service
metadata:
  name: fastapi
spec:
  selector:
    app: fastapi
  ports:
  - name: http
    protocol: TCP
    port: 8000
    targetPort: 8000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fastapi
  labels:
    app: fastapi
spec:
  selector:
    matchLabels:
      app: fastapi
  replicas: 2
  template:
    metadata:
      labels:
        app: fastapi
    spec:
      containers:
      - name: fastapi
        image: prodigy413/empty-fastapi:1.0
        ports:
        - name: http
          containerPort: 8000
        volumeMounts:
        - name: script
          mountPath: /tmp
      volumes:
      - name: script
        configMap:
          name: script
---
apiVersion: v1
data:
  normal.py: |
    from fastapi import FastAPI
    import os

    app = FastAPI()

    @app.get("/")
    async def home():
        return {"message": os.environ['HOSTNAME']}

  error.py: |
    from fastapi import FastAPI
    import os

    app = FastAPI()

    @app.get("/", status_code=503)
    async def home():
        return {"message": os.environ['HOSTNAME']}

kind: ConfigMap
metadata:
  name: script
~~~

~~~
docker build . -t empty-fastapi:1.0
docker push empty-fastapi:1.0
docker rmi empty-fastapi:1.0
~~~

- requirements.txt
~~~
fastapi
uvicorn
~~~

~~~
FROM python:3.11.7-slim

WORKDIR /app

COPY ./requirements.txt /code/requirements.txt

RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt && rm -rf /code

ENTRYPOINT ["sleep", "infinity"]
~~~
