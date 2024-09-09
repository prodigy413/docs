~~~
fluentd_client.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: fluentd-client
  labels:
    app: fluentd-client
spec:
  selector:
    matchLabels:
      app: fluentd-client
  replicas: 1
  template:
    metadata:
      labels:
        app: fluentd-client
    spec:
      containers:
      - name: fluentd-client
        image: fluent/fluentd:v1.17-debian
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - name: http-client
          mountPath: /fluentd/etc/fluent.conf
          subPath: fluent.conf
      hostAliases:
      - ip: "192.168.245.111"
        hostnames:
        - "fluentd-istio.test.local"
      volumes:
      - name: http-client
        configMap:
          name: http-client
          items:
          - key: fluent.conf
            path: fluent.conf
---
apiVersion: v1
data:
  fluent.conf: |
    <source>
      @type tail
      path /tmp/test.log
      pos_file /tmp/test.log.pos
      tag test.log
      <parse>
        @type none
      </parse>
    </source>

    <filter test.log>
      @type parser
      key_name message
      reserve_data true
      <parse>
        @type regexp
        expression /^(?<time>\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2}) (?<message>.*)$/
        time_key time
        time_format %Y/%m/%d %H:%M:%S
      </parse>
    </filter>

    <match test.log>
      @type copy
      <store>
        @type http
        #endpoint http://fluentd:9080/test.log
        endpoint http://fluentd-istio.test.local/test.log
        open_timeout 2
        retryable_response_codes 503
        <buffer>
          flush_interval 3s
        </buffer>
      </store>
      <store>
        @type stdout
      </store>
    </match>
    <label @FLUENT_LOG> 
      <match>
        @type http
        #endpoint http://fluentd:9080/fluentd.log
        endpoint http://fluentd-istio.test.local/fluentd.log
        open_timeout 2
        retryable_response_codes 503
        <buffer>
          flush_interval 3s
        </buffer>
      </match>
    </label>
kind: ConfigMap
metadata:
  name: http-client









fluentd_receiver.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: fluentd
  labels:
    app: fluentd
spec:
  selector:
    matchLabels:
      app: fluentd
  replicas: 1
  template:
    metadata:
      labels:
        app: fluentd
    spec:
      containers:
      - name: fluentd
        image: fluent/fluentd:v1.17-debian
        imagePullPolicy: IfNotPresent
        volumeMounts:
        #- name: http.conf
        #  mountPath: /fluentd/etc/http.conf
        #  subPath: http.conf
        - name: http
          mountPath: /fluentd/etc/fluent.conf
          subPath: fluent.conf
      volumes:
      - name: http
        configMap:
          name: http
          items:
          #- key: http.conf
          #  path: http.conf
          - key: fluent.conf
            path: fluent.conf
---
apiVersion: v1
data:
  fluent.conf: |
    <source>
      @type http
      port 9080
      bind 0.0.0.0
      #<parse>
      #  @type json
      #</parse>
    </source>

    <match **>
      @type stdout
    </match>
kind: ConfigMap
metadata:
  name: http
---
apiVersion: v1
kind: Service
metadata:
  name: fluentd
spec:
  selector:
    app: fluentd
  ports:
  - name: http
    #protocol: TCP
    port: 9080
    targetPort: 9080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: fluentd
spec:
  ingressClassName: nginx
  rules:
  - host: fluentd.test.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: fluentd
            port:
              number: 9080
---
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: test-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "fluentd-istio.test.local"
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: test-vs
spec:
  gateways:
  - istio-system/test-gateway
  hosts:
  - "fluentd-istio.test.local"
  http:
  - route:
    - destination:
        host: fluentd
        port:
          number: 9080
---
apiVersion: v1
kind: Pod
metadata:
  name: client
  labels:
    app: client
spec:
  containers:
  - name: client
    image: nginx:1.27.1
    imagePullPolicy: IfNotPresent









### SelfSigned Issuer ###
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: selfsigned-ca
  namespace: cert-manager
spec:
  isCA: true
  commonName: selfsigned-ca
  secretName: root-secret
  privateKey:
    algorithm: ECDSA
    size: 256
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
    group: cert-manager.io
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ca-issuer
spec:
  ca:
    secretName: root-secret
---
### Certificate ###
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-local
  namespace: nginx-gateway
spec:
  subject:
    organizations:
    - Jedi Academy
    countries:
    - Japan
    organizationalUnits:
    - IT
    localities:
    - Adachi
    provinces:
    - Tokyo
#  commonName: nginx # discouraged from being used.
  duration: 24h
  dnsNames:
  - "*.test.local"
  secretName: test-local-crt
  issuerRef:
    name: ca-issuer
    kind: ClusterIssuer
    group: cert-manager.io
  privateKey:
    algorithm: ECDSA
    size: 256
~~~

~~~
kubectl exec -it client -- bash

curl -X POST -d '{"foo":"bar"}' -H 'Content-Type: application/json' http://fluentd:9080/app.log
curl -X POST -d '{"foo":"bar"}' -H 'Content-Type: application/json' http://192.168.245.113/app.log -H 'host: fluentd.test.local'
curl -X POST -d '{"foo":"bar"}' -H 'Content-Type: application/json' http://192.168.245.111/app.log -H 'host: fluentd-istio.test.local'
~~~

~~~
kubectl logs -f deployments/fluentd-client
kubectl logs -f deployments/fluentd
~~~

~~~
kubectl exec -it deployments/fluentd-client -- bash
echo "$(date '+%Y/%m/%d %H:%M:%S') This is test log" >> /tmp/test.log
echo {\"ip\":\"192.168.0.1\",\"msg\":\"This is test.\"} >> /tmp/test.log
~~~
