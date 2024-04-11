~~~manifest.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment-01
  labels:
    app: nginx-deployment-01
spec:
  selector:
    matchLabels:
      app: nginx-deployment-01
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx-deployment-01
    spec:
      containers:
      - name: nginx-deployment-01
        image: nginx:1.25.3
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment-02
  labels:
    app: nginx-deployment-02
spec:
  selector:
    matchLabels:
      app: nginx-deployment-02
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx-deployment-02
    spec:
      containers:
      - name: nginx-deployment-02
        image: nginx:1.25.3
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx-statefulset-01
  labels:
    app: nginx-statefulset-01
spec:
  selector:
    matchLabels:
      app: nginx-statefulset-01
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx-statefulset-01
    spec:
      containers:
      - name: nginx-statefulset-01
        image: nginx:1.25.3
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx-statefulset-02
  labels:
    app: nginx-statefulset-02
spec:
  selector:
    matchLabels:
      app: nginx-statefulset-02
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx-statefulset-02
    spec:
      containers:
      - name: nginx-statefulset-02
        image: nginx:1.25.3
---
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx-statefulset-03
  labels:
    app: nginx-statefulset-03
spec:
  selector:
    matchLabels:
      app: nginx-statefulset-03
  replicas: 0
  template:
    metadata:
      labels:
        app: nginx-statefulset-03
    spec:
      containers:
      - name: nginx-statefulset-03
        image: nginx:1.25.3
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: healthcheck-sa
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: healthcheck-role
  namespace: default
rules:
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: healthcheck-role-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: healthcheck-role
subjects:
- kind: ServiceAccount
  name: healthcheck-sa
  namespace: default
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.25.3
  serviceAccountName: healthcheck-sa
~~~




~~~ms-list.yaml
deployments:
- nginx-deployment-01
- nginx-deployment-02
#- nginx-deployment-03
statefulsets:
- nginx-statefulset-01
- nginx-statefulset-02
#- nginx-statefulset-03
~~~

~~~resource-checker.py
import logging
import os
from requests import get
from yaml import safe_load

# Set flag
flag = True

# File Path Configuration
listfile = '/home/obi/test/infra-code/yaml/healthcheck/20240410/ms-list.yaml'
flagfile = '/home/obi/test/infra-code/yaml/healthcheck/20240410/healthcheck_ok.txt'
tokenfile = '/var/run/secrets/kubernetes.io/serviceaccount/token'
cacert = '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'
namespace = 'default'
apiserver = '127.0.0.1:8001'
logfile = 'test.log'

# Logging Configuration
formatter = '%(asctime)s %(levelname)s %(message)s'
date_format = '%Y/%m/%d %H:%M:%S'
logging.basicConfig(filename=logfile, format=formatter, datefmt=date_format, level=logging.INFO)


with open(listfile, 'r') as f:
    yaml_data = safe_load(f)

if yaml_data is not None:
    for kind in yaml_data.keys():
        url = 'http://' + apiserver + '/apis/apps/v1/namespaces/' + namespace + '/' + kind
        try:
            data = get(url)
            if data.status_code != 200:
                exit(1)
        except Exception:
            logging.error('Failed to get resource data')
            exit(1)

        items = data.json()['items']
        ms_status_data = {x['metadata']['name']: x['status']['availableReplicas'] for x in items}

        for ms in yaml_data[kind]:
            try:
                if ms_status_data[ms] == 0:
                    flag = False
                    logging.info(f'{ms}: No pods available.')
            except KeyError:
                flag = False
                logging.info(f'{ms}: No {kind} found.')

# Control flag file
if flag:
    try:
        with open(flagfile, 'w'):
            logging.info('flagfile created')
    except Exception:
        logging.error('Failed to create flagfile')
else:
    try:
        os.remove(flagfile)
        logging.info('flagfile removed')
    except FileNotFoundError:
        logging.info('flagfile removed')
    except Exception:
        logging.error('Failed to remove flagfile')
~~~
