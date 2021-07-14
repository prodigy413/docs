### Restart All Deployments

~~~
kubectl get deploy --no-headers -A | awk '{system("kubectl -n "$1" rollout restart deploy "$2"")}'
~~~

### Restart All Daemonsets

~~~
kubectl get ds --no-headers -A | awk '{system("kubectl -n "$1" rollout restart ds "$2"")}'
~~~

### Restart All Statefulsets

~~~
kubectl get sts --no-headers -A | awk '{system("kubectl -n "$1" rollout restart sts "$2"")}'
~~~

### Change replicas
~~~
kubectl scale deployment nginx --replicas=2 ; kubectl rollout status deployment nginx -w --timeout=600s
deployment.apps/nginx scaled
Waiting for deployment "nginx" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "nginx" rollout to finish: 1 of 2 updated replicas are available...
deployment "nginx" successfully rolled out


kubectl scale deployment nginx --replicas=0 ; kubectl wait pod -l app=nginx --for=delete --timeout 600s
deployment.apps/nginx scaled
pod/nginx-7dfb57d6d9-mzbv7 condition met
pod/nginx-7dfb57d6d9-s2wqn condition met
~~~


