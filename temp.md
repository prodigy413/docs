~~~
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








### SelfSigned Issuer ###
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
---
### Certificate ###
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-local
  namespace: nginx-gateway
spec:
  duration: 24h
  dnsNames:
  - "*.test.local"
  secretName: test-local-crt
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
    group: cert-manager.io
  privateKey:
    algorithm: ECDSA
    size: 256






---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/issuer: ca-issuer
  name: nginx-ingress
  namespace: cert-test
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
            name: nginx-svc
            port:
              number: 80
  tls:
  - hosts:
    - nginx.test.local
    secretName: nginx-cert-secret
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
  namespace: cert-test
spec:
  selector:
    app: nginx
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: cert-test
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.21.4
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
~~~
