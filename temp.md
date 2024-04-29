~~~
apiVersion: v1
kind: Pod
metadata:
  name: proxy
  labels:
    name: proxy
spec:
  containers:
  - name: proxy
    #image: nginx:1.25.5
    image: nginxinc/nginx-unprivileged:1.25.5
    #image: registry.access.redhat.com/ubi9/nginx-122:1-59.1712857762
    imagePullPolicy: IfNotPresent
    #imagePullPolicy: Always
    #command: ["sh",  "-c", "sleep infinity"]
    volumeMounts:
    #- name: v1-volume
    #  mountPath: /usr/share/nginx/html
    - name: nginx-conf
      mountPath: /etc/nginx/nginx.conf
      subPath: nginx.conf
    - name: proxy-conf
      mountPath: /etc/nginx/conf.d
    #- name: proxy-conf
    #  mountPath: /etc/nginx/conf.d/proxy.conf
    #  subPath: proxy.conf
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
  - name: ssh
    protocol: TCP
    port: 8022
    targetPort: 8022
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
    imagePullPolicy: IfNotPresent
    #imagePullPolicy: Always
---
apiVersion: v1
data:
  nginx.conf: |2

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

        keepalive_timeout  65;

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

        location /nginx_status {
            stub_status on;
            access_log off;
            allow 127.0.0.1;
            deny all;
        }

        location / {
            set $backend_server 10.102.153.254;
            proxy_redirect                      off;
            proxy_set_header Host               $host;
            proxy_set_header X-Real-IP          $remote_addr;
            proxy_set_header X-Forwarded-For    $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto  $scheme;
            proxy_read_timeout                  1m;
            proxy_connect_timeout               1m;
            proxy_pass                          http://$backend_server;
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
    #imagePullPolicy: Always
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: ssh
  labels:
    name: ssh
spec:
  containers:
  - name: ssh
    image: linuxserver/openssh-server:amd64-version-9.6_p1-r0
    imagePullPolicy: IfNotPresent
    ports:
    - name: http
      containerPort: 2222
    env:
    - name: USER_NAME
      value: "test"
    - name: USER_PASSWORD
      value: "password"
    - name: PASSWORD_ACCESS
      value: "true"
    - name: UPUID
      value: "1000"
    - name: PGID
      value: "1000"
    - name: TZ
      value: "Etc/UTC"
---
apiVersion: v1
kind: Service
metadata:
  name: ssh
spec:
  selector:
    name: ssh
  type: ClusterIP
  ports:
  - name: http
    protocol: TCP
    port: 2222
    targetPort: 2222

# registry.access.redhat.com/ubi9/nginx-122:1-59.1712857762 Nginx 1.22 CMD ["nginx", "-g", "daemon off;"]
~~~
