- dns.yaml
~~~yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dns-rolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:coredns
subjects:
- kind: ServiceAccount
  name: dns
  namespace: default
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dns
---
apiVersion: v1
kind: Pod
metadata:
  name: dns
  labels:
    name: dns
spec:
  serviceAccountName: dns
  containers:
  - name: dns
    image: coredns/coredns:1.11.1
    args:
    - -conf
    - /etc/coredns/Corefile
    ports:
    - containerPort: 53
      name: dns
      protocol: UDP
    - containerPort: 53
      name: dns-tcp
      protocol: TCP
    volumeMounts:
    - mountPath: /etc/coredns
      name: config-volume
      readOnly: true
    - mountPath: /etc/coredns/zone/
      name: zone-volume
      readOnly: true
  volumes:
  - configMap:
      defaultMode: 420
      items:
      - key: Corefile
        path: Corefile
      name: coredns
    name: config-volume
  - configMap:
      defaultMode: 420
      items:
      - key: test.local
        path: test.local
      name: zone
    name: zone-volume
---
apiVersion: v1
kind: Service
metadata:
  name: dns
spec:
  selector:
    name: dns
  ports:
  - name: dns
    port: 53
    protocol: UDP
    targetPort: 53
  - name: dns-tcp
    port: 53
    protocol: TCP
    targetPort: 53
---
apiVersion: v1
data:
  Corefile: |
    . {
        log
        errors
        forward . 8.8.8.8:53
        hosts {
            192.168.245.105 control
            10.106.237.18 nginx.test.local
            fallthrough
        }
        whoami
    }
kind: ConfigMap
metadata:
  name: coredns
---
apiVersion: v1
data:
  test.local: |
    $TTL 2d    ; default TTL for zone
    $ORIGIN test.local. ; base domain-name
    @         IN      SOA   ns1.test.local. noc.test.local. (
                                    2022090400 ; serial number
                                    12h        ; refresh
                                    15m        ; update retry
                                    3w         ; expiry
                                    2h         ; minimum
                                    )
    ; name server RR for the domain
                   IN      NS      ns1.test.local.
    ; domain hosts includes NS records defined above
    ns1            IN      A       192.168.245.111
    mail           IN      A       192.168.245.111
    www            IN      A       192.168.245.111
    nginx          IN      A       192.168.245.111
kind: ConfigMap
metadata:
  name: zone
~~~

- proxy.yaml
~~~yaml
apiVersion: v1
kind: Pod
metadata:
  name: proxy
  labels:
    name: proxy
spec:
  containers:
  - name: proxy
    image: nginx:1.25.5
    #image: registry.access.redhat.com/ubi9/nginx-122:1-59.1712857762
    #command: ["sh",  "-c", "sleep infinity"]
    volumeMounts:
    #- name: v1-volume
    #  mountPath: /usr/share/nginx/html
    - name: nginx-conf
      mountPath: /etc/nginx/nginx.conf
      subPath: nginx.conf
    - name: proxy-conf
      mountPath: /etc/nginx/conf.d/proxy.conf
      subPath: proxy.conf
  volumes:
  - name: nginx-conf
    configMap:
      name: nginx-conf
  - name: proxy-conf
    configMap:
      name: proxy-conf
---
apiVersion: v1
kind: Service
metadata:
  name: proxy
spec:
  selector:
    name: proxy
  ports:
  - name: web
    protocol: TCP
    port: 80
    targetPort: 80
  - name: proxy
    protocol: TCP
    port: 8080
    targetPort: 8080
---
apiVersion: v1
kind: Pod
metadata:
  name: network
  labels:
    name: network
spec:
  containers:
  - name: network
    image: prodigy413/network-client:1.0
---
apiVersion: v1
data:
  nginx.conf: |
    worker_processes  auto;

    error_log  /var/log/nginx/error.log warn;
    pid        /tmp/nginx.pid;


    events {
        worker_connections  1024;
    }


    http {
        proxy_temp_path /tmp/proxy_temp;
        client_body_temp_path /tmp/client_temp;
        fastcgi_temp_path /tmp/fastcgi_temp;
        uwsgi_temp_path /tmp/uwsgi_temp;
        scgi_temp_path /tmp/scgi_temp;
        server_tokens off;

        include       /etc/nginx/mime.types;
        default_type  application/octet-stream;

        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for" $request_time';

        access_log  /var/log/nginx/access.log  main;

        sendfile        on;
        #tcp_nopush     on;

        keepalive_timeout  65;

        #gzip  on;

        include /etc/nginx/conf.d/*.conf;
    }
kind: ConfigMap
metadata:
  name: nginx-conf
---
apiVersion: v1
data:
  proxy.conf: |
    server {
        listen       8080;
        server_name  localhost;
        client_max_body_size 5M;
        error_page 403 404 = /dummy.html;

        location /nginx_status {
            stub_status on;
            access_log off;
            allow 127.0.0.1;
            deny all;
        }

        location /dummy.html {
            return 404 "<p>Page not found</p>";
            internal;
        }

        location / {
            resolver 10.108.128.219 ipv6=off;
            set $backend_server nginx.test.local;
            #proxy_redirect                      off;
            #proxy_set_header Host               $host;
            #proxy_set_header X-Real-IP          $remote_addr;
            #proxy_set_header X-Forwarded-For    $proxy_add_x_forwarded_for;
            #proxy_set_header X-Forwarded-Proto  $scheme;
            #proxy_read_timeout                  1m;
            #proxy_connect_timeout               1m;
            proxy_pass                          https://$backend_server;
        }
    }
kind: ConfigMap
metadata:
  name: proxy-conf
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
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
            name: nginx-for-proxy-test
            port:
              number: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-for-proxy-test
spec:
  selector:
    app: nginx-for-proxy-test
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx-for-proxy-test
  labels:
    app: nginx-for-proxy-test
spec:
  containers:
  - name: nginx-for-proxy-test
    image: nginx:1.25.5
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
~~~

