### Destination rules

- Default Load balancing options<br>
<https://istio.io/latest/docs/concepts/traffic-management/#load-balancing-options><br>
`By default, Istio uses a least requests load balancing policy......`

### Mutual TLS Migration

- PERMISSIVE mode<br>
<https://istio.io/latest/docs/tasks/security/authentication/mtls-migration/><br>
`By default, Istio configures the destination workloads using PERMISSIVE mode.`

### 

~~~
kubectl -n istio-system logs istiod-66ddb6b5d5-tp6rf

..........
    "enableAutoMtls": true,
..........

Automtls means using istio mtls.
~~~

### How to get default configuration #1

~~~
k -n istio-test exec -it nginx01-8dcb699bc-z8sh7 -c istio-proxy -- bash
pilot-agent request GET config_dump | grep -i tlsmode
pilot-agent request GET config_dump | grep -i lb_policy

istioctl proxy-config all nginx01-8dcb699bc-z8sh7.istio-test

istioctl proxy-status
~~~

### How to get default configuration #2

~~~
# pod-name: pod with istio enabled
kubectl port-forward pod-name 15000:15000
curl http://localhost:15000/config_dump

{
  "retry_policy": {
    "retry_on": "connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes",
    "num_retries": 2,
    "retry_host_predicate": [
      {
        "name": "envoy.retry_host_predicates.previous_hosts",
        "typed_config": {
          "@type": "type.googleapis.com/envoy.extensions.retry.host.previous_hosts.v3.PreviousHostsPredicate"
        }
      }
    ],
    "host_selection_retry_max_attempts": "5",
    "retriable_status_codes": [
      503
    ]
  }
}
~~~

~~~yaml
apiVersion: v1
kind: Namespace
metadata:
  name: istio-test
  labels:
    istio-injection: enabled
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: fastapi-ingress
  namespace: istio-system
#  annotations:
#    nginx.ingress.kubernetes.io/proxy-next-upstream: "error timeout http_503"
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
            name: istio-ingressgateway
            port:
              number: 80
---
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: test-gw
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - hosts:
    - "*"
    port:
      number: 80
      name: http
      protocol: HTTP
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: test-vs
  namespace: istio-system
spec:
  gateways:
  - test-gw
  hosts:
  - fastapi.test.local
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: fastapi.istio-test.svc.cluster.local
        port:
          number: 8000
---
apiVersion: v1
kind: Service
metadata:
  name: fastapi
  namespace: istio-test
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
  namespace: istio-test
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
  namespace: istio-test
~~~
