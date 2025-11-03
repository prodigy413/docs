- no_taint.yaml
~~~yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 5
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.29.1
        imagePullPolicy: IfNotPresent
~~~

- taint_affinity.yaml
~~~yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 5
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.29.1
        imagePullPolicy: IfNotPresent
      nodeSelector:
        dedicated: "4.15"
      tolerations:
      - key: "dedicated"
        operator: "Equal"
        value: "4.15"
        effect: "NoSchedule"
~~~

- Add label and taint

~~~
$ kubectl drain worker01 --ignore-daemonsets --delete-emptydir-data

$ kubectl delete -f taint_affinity.yaml 
deployment.apps "nginx" deleted from default namespace

$ kubectl label nodes worker01 dedicated=4.15
node/worker01 labeled

$ kubectl get nodes worker01 --show-labels 
NAME       STATUS   ROLES    AGE   VERSION   LABELS
worker01   Ready    worker   53d   v1.34.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,dedicated=4.15,kubernetes.io/arch=amd64,kubernetes.io/hostname=worker01,kubernetes.io/os=linux,node-role.kubernetes.io/worker=worker

$ kubectl taint nodes worker01 dedicated=4.15:NoSchedule
node/worker01 tainted

$ kubectl describe node worker01 | grep -i taint
Taints:             dedicated=4.15:NoSchedule

$ kubectl get nodes
NAME        STATUS                     ROLES           AGE   VERSION
control01   Ready                      control-plane   53d   v1.34.0
worker01    Ready,SchedulingDisabled   worker          53d   v1.34.0
worker02    Ready                      worker          53d   v1.34.0
worker03    Ready                      worker          53d   v1.34.0

$ kubectl uncordon worker01

$ kubectl get nodes
NAME        STATUS   ROLES           AGE   VERSION
control01   Ready    control-plane   53d   v1.34.0
worker01    Ready    worker          53d   v1.34.0
worker02    Ready    worker          53d   v1.34.0
worker03    Ready    worker          53d   v1.34.0

$ kubectl get pod -A -owide | grep -i worker01
# No pods except for daemonset
~~~

- Apply normal deployment

~~~
$ kubectl apply -f no_taint.yaml
deployment.apps/nginx created

$ kubectl get pod -owide
NAME                     READY   STATUS    RESTARTS   AGE    IP              NODE       NOMINATED NODE   READINESS GATES
nginx-566d6954b7-4gvz9   1/1     Running   0          7s     172.16.30.106   worker02   <none>           <none>
nginx-566d6954b7-58v6n   1/1     Running   0          103s   172.16.30.103   worker02   <none>           <none>
nginx-566d6954b7-gbwnm   1/1     Running   0          103s   172.16.19.92    worker03   <none>           <none>
nginx-566d6954b7-m8t2k   1/1     Running   0          103s   172.16.19.84    worker03   <none>           <none>

$ kubectl delete -f no_taint.yaml
deployment.apps "nginx" deleted from default namespace
~~~

- After add label and taint

~~~
$ kubectl apply -f taint_affinity.yaml
deployment.apps/nginx created

$ kubectl get pod -owide
NAME                    READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
nginx-fb698f5dc-2lmmm   1/1     Running   0          57s   172.16.5.50   worker01   <none>           <none>
nginx-fb698f5dc-9cw29   1/1     Running   0          57s   172.16.5.47   worker01   <none>           <none>
nginx-fb698f5dc-bzfcp   1/1     Running   0          57s   172.16.5.49   worker01   <none>           <none>
nginx-fb698f5dc-spqsk   1/1     Running   0          57s   172.16.5.48   worker01   <none>           <none>
nginx-fb698f5dc-w4wkb   1/1     Running   0          57s   172.16.5.41   worker01   <none>           <none>

$ kubectl delete -f taint_affinity.yaml
~~~

- Remove configuration

~~~
$ kubectl taint nodes worker01 dedicated=4.15:NoSchedule-
node/worker01 untainted

$ kubectl label nodes worker01 dedicated-
node/worker01 unlabeled

$ kubectl get nodes worker01 --show-labels
NAME       STATUS   ROLES    AGE   VERSION   LABELS
worker01   Ready    worker   29h   v1.34.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=worker01,kubernetes.io/os=linux,node-role.kubernetes.io/worker=worker

$ kubectl describe node worker01 | grep -i taint
Taints:             <none>
~~~

### Openshift

~~~
oc adm drain 10.0.1.4 --ignore-daemonsets --delete-emptydir-data

$ oc get nodes
NAME       STATUS                     ROLES           AGE   VERSION
10.0.1.4   Ready,SchedulingDisabled   master,worker   32m   v1.28.15+d227d65
10.0.1.5   Ready                      master,worker   32m   v1.28.15+d227d65
10.0.1.6   Ready                      master,worker   32m   v1.28.15+d227d65

oc label nodes 10.0.1.4 dedicated=4.15

$ oc get nodes -l dedicated=4.15
NAME       STATUS                     ROLES           AGE   VERSION
10.0.1.4   Ready,SchedulingDisabled   master,worker   34m   v1.28.15+d227d65

oc adm taint nodes 10.0.1.4 dedicated=4.15:NoSchedule

$ oc describe nodes 10.0.1.4 | grep Taints
Taints:             dedicated=4.15:NoSchedule

oc adm uncordon 10.0.1.4

$ oc adm uncordon 10.0.1.4
node/10.0.1.4 uncordoned
obi@obi:~/test/infra-code/yaml/openshift$ oc get nodes
NAME       STATUS   ROLES           AGE   VERSION
10.0.1.4   Ready    master,worker   35m   v1.28.15+d227d65
10.0.1.5   Ready    master,worker   35m   v1.28.15+d227d65
10.0.1.6   Ready    master,worker   35m   v1.28.15+d227d65

##### Set disable nodeselect / tolerations

oc apply -f deploymentconfig.yaml

$ oc get pod -owide
NAME             READY   STATUS      RESTARTS   AGE   IP             NODE       NOMINATED NODE   READINESS GATES
nginx-1-deploy   0/1     Completed   0          17s   172.17.31.55   10.0.1.5   <none>           <none>
nginx-1-fk8rz    1/1     Running     0          16s   172.17.5.43    10.0.1.6   <none>           <none>
nginx-1-jlfv7    1/1     Running     0          16s   172.17.5.44    10.0.1.6   <none>           <none>
nginx-1-ksgxw    1/1     Running     0          16s   172.17.31.57   10.0.1.5   <none>           <none>
nginx-1-n84d4    1/1     Running     0          15s   172.17.31.56   10.0.1.5   <none>           <none>

oc delete -f deploymentconfig.yaml

##### After enable nodeselect / tolerations

oc apply -f deploymentconfig.yaml

$ oc get pod -owide
NAME             READY   STATUS      RESTARTS   AGE   IP              NODE       NOMINATED NODE   READINESS GATES
nginx-1-deploy   0/1     Completed   0          7s    172.17.61.181   10.0.1.4   <none>           <none>
nginx-1-r7qpn    1/1     Running     0          5s    172.17.61.184   10.0.1.4   <none>           <none>
nginx-1-rdvrb    1/1     Running     0          5s    172.17.61.185   10.0.1.4   <none>           <none>
nginx-1-tgrht    1/1     Running     0          5s    172.17.61.183   10.0.1.4   <none>           <none>
nginx-1-wptdx    1/1     Running     0          5s    172.17.61.182   10.0.1.4   <none>           <none>

oc adm taint nodes 10.0.1.4 dedicated=4.15:NoSchedule-

oc label nodes 10.0.1.4 dedicated-
~~~

~~~yaml
apiVersion: apps.openshift.io/v1
kind: DeploymentConfig
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 4
  selector:
    app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.29.1
        ports:
        - containerPort: 80
#      nodeSelector:
#        dedicated: "4.15"
#      tolerations:
#      - key: "dedicated"
#        operator: "Equal"
#        value: "4.15"
#        effect: "NoSchedule"
~~~
