~~~
openssl genrsa -out tls.key 2048
openssl req -new -x509 -key tls.key -out tls.crt -days 365 -subj "/CN=obi.test.local"
openssl x509 -in tls.crt -noout -text
openssl rand -base64 8
~~~

- http
~~~
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
        - "fluentd.test.local"
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
        endpoint http://fluentd.test.local/test.log
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
        endpoint http://fluentd.test.local/fluentd.log
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
#apiVersion: networking.k8s.io/v1
#kind: Ingress
#metadata:
#  name: fluentd
#spec:
#  ingressClassName: nginx
#  rules:
#  - host: fluentd.test.local
#    http:
#      paths:
#      - path: /
#        pathType: Prefix
#        backend:
#          service:
#            name: fluentd
#            port:
#              number: 9080
#---
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
    - "fluentd.test.local"
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: test-vs
spec:
  gateways:
  - istio-system/test-gateway
  hosts:
  - "fluentd.test.local"
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
~~~

- https_gateway
~~~
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
        - name: cert
          mountPath: /cert
      hostAliases:
      - ip: "192.168.245.111"
        hostnames:
        - "fluentd.test.local"
      volumes:
      - name: http-client
        configMap:
          name: http-client
          items:
          - key: fluent.conf
            path: fluent.conf
      - name: cert
        secret:
          secretName: fluentd-crt
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
        endpoint https://fluentd.test.local/test.log
        open_timeout 2
        retryable_response_codes 503
        tls_ca_cert_path /cert/ca.crt
        tls_client_cert_path /cert/tls.crt
        tls_private_key_path /cert/tls.key
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
        endpoint https://fluentd.test.local/fluentd.log
        open_timeout 2
        retryable_response_codes 503
        tls_ca_cert_path /cert/ca.crt
        tls_client_cert_path /cert/tls.crt
        tls_private_key_path /cert/tls.key
        <buffer>
          flush_interval 3s
        </buffer>
      </match>
    </label>
kind: ConfigMap
metadata:
  name: http-client





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
        - name: cert
          mountPath: /cert
      volumes:
      - name: http
        configMap:
          name: http
          items:
          #- key: http.conf
          #  path: http.conf
          - key: fluent.conf
            path: fluent.conf
      - name: cert
        secret:
          secretName: fluentd-crt
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
#---
#apiVersion: networking.k8s.io/v1
#kind: Ingress
#metadata:
#  name: fluentd
#spec:
#  ingressClassName: nginx
#  rules:
#  - host: fluentd.test.local
#    http:
#      paths:
#      - path: /
#        pathType: Prefix
#        backend:
#          service:
#            name: fluentd
#            port:
#              number: 9080
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
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: fluentd-crt
    hosts:
    - "fluentd.test.local"
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: test-vs
spec:
  gateways:
  - istio-system/test-gateway
  hosts:
  - "fluentd.test.local"
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

~~~

- https_passthrough
~~~
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
        - name: cert
          mountPath: /cert
      hostAliases:
      - ip: "192.168.245.111"
        hostnames:
        - "fluentd.test.local"
      volumes:
      - name: http-client
        configMap:
          name: http-client
          items:
          - key: fluent.conf
            path: fluent.conf
      - name: cert
        secret:
          secretName: fluentd-crt
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
        endpoint https://fluentd.test.local/test.log
        open_timeout 2
        retryable_response_codes 503
        tls_ca_cert_path /cert/ca.crt
        tls_client_cert_path /cert/tls.crt
        tls_private_key_path /cert/tls.key
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
        endpoint https://fluentd.test.local/fluentd.log
        open_timeout 2
        retryable_response_codes 503
        tls_ca_cert_path /cert/ca.crt
        tls_client_cert_path /cert/tls.crt
        tls_private_key_path /cert/tls.key
        <buffer>
          flush_interval 3s
        </buffer>
      </match>
    </label>
kind: ConfigMap
metadata:
  name: http-client





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
        - name: cert
          mountPath: /cert
      volumes:
      - name: http
        configMap:
          name: http
          items:
          #- key: http.conf
          #  path: http.conf
          - key: fluent.conf
            path: fluent.conf
      - name: cert
        secret:
          secretName: fluentd-crt
---
apiVersion: v1
data:
  fluent.conf: |
    <source>
      @type http
      port 9080
      bind 0.0.0.0
      <transport tls>
        ca_path /cert/ca.crt
        cert_path /cert/tls.crt
        private_key_path /cert/tls.key
      </transport>
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
#---
#apiVersion: networking.k8s.io/v1
#kind: Ingress
#metadata:
#  name: fluentd
#spec:
#  ingressClassName: nginx
#  rules:
#  - host: fluentd.test.local
#    http:
#      paths:
#      - path: /
#        pathType: Prefix
#        backend:
#          service:
#            name: fluentd
#            port:
#              number: 9080
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
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: PASSTHROUGH
      #credentialName: fluentd-crt
    hosts:
    - "fluentd.test.local"
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: test-vs
spec:
  gateways:
  - istio-system/test-gateway
  hosts:
  - "fluentd.test.local"
  tls:
  - match:
    - port: 443
      sniHosts:
      - "fluentd.test.local"
    route:
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
~~~

~~~
kubectl exec -it client -- bash

curl -X POST -d '{"foo":"bar"}' -H 'Content-Type: application/json' http://fluentd:9080/app.log
curl -X POST -d '{"foo":"bar"}' -H 'Content-Type: application/json' http://192.168.245.113/app.log -H 'host: fluentd.test.local'
curl -X POST -d '{"foo":"bar"}' -H 'Content-Type: application/json' http://192.168.245.111/app.log -H 'host: fluentd-istio.test.local'

kubectl logs -f deployments/fluentd-client
kubectl logs -f deployments/fluentd

kubectl exec -it deployments/fluentd-client -- bash
echo "$(date '+%Y/%m/%d %H:%M:%S') This is test log" >> /tmp/test.log
echo {\"ip\":\"192.168.0.1\",\"msg\":\"This is test.\"} >> /tmp/test.log

kubectl rollout restart deployment fluentd-client
kubectl rollout restart deployment fluentd
~~~

~~~
apiVersion: v1
data:
  ca.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJjRENDQVJhZ0F3SUJBZ0lRSTA1ZlFtangvTzRPdTVBWnlLU0ZNekFLQmdncWhrak9QUVFEQWpBWU1SWXcKRkFZRFZRUURFdzF6Wld4bWMybG5ibVZrTFdOaE1CNFhEVEkwTURneU9ERXpNREEwTjFvWERUSTBNVEV5TmpFegpNREEwTjFvd0dERVdNQlFHQTFVRUF4TU5jMlZzWm5OcFoyNWxaQzFqWVRCWk1CTUdCeXFHU000OUFnRUdDQ3FHClNNNDlBd0VIQTBJQUJDR2tMQkhzWkxlTDMrdmRCTGdNcEovNk12Vnh0S2ZUbm1qY0U4UGlCbUFvZXhFclN0NGgKK1ZsalZmRGtROVJaVmRNWU9zQVJNaS9YZXphRDhLNFpCVXVqUWpCQU1BNEdBMVVkRHdFQi93UUVBd0lDcERBUApCZ05WSFJNQkFmOEVCVEFEQVFIL01CMEdBMVVkRGdRV0JCUm4rT1RIblU3SDdJTVVRdEtKM3U1L1VlR25mVEFLCkJnZ3Foa2pPUFFRREFnTklBREJGQWlCZDdvMGxEUSs0WVdpeWIvRS9nZWxxTmdmM2dGR1NobEpwRThCSGk3VWUKMndJaEFOK1VFc0lCNGpsV2ZPRmJlY2duQzE4bURPWStSYmlOL2p4M3Z4TUowR0NtCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
  tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJ5akNDQVhHZ0F3SUJBZ0lRWmFlZ1BETTNVYnlyZE92a0dSaHBsVEFLQmdncWhrak9QUVFEQWpBWU1SWXcKRkFZRFZRUURFdzF6Wld4bWMybG5ibVZrTFdOaE1CNFhEVEkwTURreE1ERXlOVGN6T0ZvWERUSTBNRGt4TVRFeQpOVGN6T0Zvd1ZURU9NQXdHQTFVRUJoTUZTbUZ3WVc0eERqQU1CZ05WQkFnVEJWUnZhM2x2TVE4d0RRWURWUVFICkV3WkJaR0ZqYUdreEZUQVRCZ05WQkFvVERFcGxaR2tnUVdOaFpHVnRlVEVMTUFrR0ExVUVDeE1DU1ZRd1dUQVQKQmdjcWhrak9QUUlCQmdncWhrak9QUU1CQndOQ0FBUmloeGl5ay9tTmhPeCs1Ujlzd0UrbzR6YzF2SGtEeWd1SgovN2t6SFZONGdlRGF4L3l0TElqb0UyYXFhVGkwUEpZZHIvMC9oOEcydmU4cU5nM2R0cGdnbzJBd1hqQU9CZ05WCkhROEJBZjhFQkFNQ0JhQXdEQVlEVlIwVEFRSC9CQUl3QURBZkJnTlZIU01FR0RBV2dCUm4rT1RIblU3SDdJTVUKUXRLSjN1NS9VZUduZlRBZEJnTlZIUkVFRmpBVWdoSm1iSFZsYm5Sa0xuUmxjM1F1Ykc5allXd3dDZ1lJS29aSQp6ajBFQXdJRFJ3QXdSQUlnRkdLYUNmRjMyaG5jOVVwNFozRjNvTStEQWhVdlQ3WWFwK0FoTFBEWUlkSUNJRkd1CitZdVpzY0RyLzRvM3hLb1hTblBSRld4bW5ONThFcmdKVE5LTnM3OEQKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
  tls.key: LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0tCk1IY0NBUUVFSVBWMjBLR1JWbHB4M1QrVkxqTWF1bm9xcVZCNlY4SDlHOGMwcW5tM3ZFeU5vQW9HQ0NxR1NNNDkKQXdFSG9VUURRZ0FFWW9jWXNwUDVqWVRzZnVVZmJNQlBxT00zTmJ4NUE4b0xpZis1TXgxVGVJSGcyc2Y4clN5SQo2Qk5tcW1rNHREeVdIYS85UDRmQnRyM3ZLallOM2JhWUlBPT0KLS0tLS1FTkQgRUMgUFJJVkFURSBLRVktLS0tLQo=
kind: Secret
metadata:
  annotations:
    cert-manager.io/alt-names: fluentd.test.local
    cert-manager.io/certificate-name: test-cert
    cert-manager.io/common-name: ""
    cert-manager.io/ip-sans: ""
    cert-manager.io/issuer-group: cert-manager.io
    cert-manager.io/issuer-kind: ClusterIssuer
    cert-manager.io/issuer-name: ca-issuer
    cert-manager.io/subject-countries: Japan
    cert-manager.io/subject-localities: Adachi
    cert-manager.io/subject-organizationalunits: IT
    cert-manager.io/subject-organizations: Jedi Academy
    cert-manager.io/subject-provinces: Tokyo
    cert-manager.io/uri-sans: ""
  labels:
    controller.cert-manager.io/fao: "true"
  name: fluentd-crt
  namespace: default
type: kubernetes.io/tls
~~~
