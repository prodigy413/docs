~~~
$ kubectl -n ingress-nginx get svc ingress-nginx-controller -oyaml
apiVersion: v1
kind: Service
metadata:
  annotations:
..........
    service.beta.kubernetes.io/ncloud-load-balancer-proxy-protocol: "true"
..........

$ kubectl -n ingress-nginx get cm ingress-nginx-controller -oyaml
apiVersion: v1
data:
..........
  use-proxy-protocol: "true"
kind: ConfigMap
metadata:
..........

### Before
$ kubectl logs nginx
198.18.0.164 - - [22/Nov/2024:02:27:08 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/8.5.0" "10.0.6.8"

### After
$ kubectl logs nginx
198.18.0.160 - - [22/Nov/2024:03:14:57 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/8.5.0" "126.51.143.114"
~~~
