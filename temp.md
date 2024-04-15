- healthcheck.yaml
~~~yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: healthcheck-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  labels:
    app: healthcheck
  name: healthcheck-role
rules:
  - apiGroups:
    - apps
    resources:
    - deployments
    - statefulsets
    verbs:
    - get
    - list
    - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    app: healthcheck
  name: healthcheck-role-binding
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
data:
  ms-list.yaml: |
    deployments:
    - nginx-deployment-01
    - nginx-deployment-02
    #- nginx-deployment-03
    statefulsets:
    - nginx-statefulset-01
    - nginx-statefulset-02
    #- nginx-statefulset-03
kind: ConfigMap
metadata:
  labels:
    app: healthcheck
  name: ms-list
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: healthcheck
  name: healthcheck
spec:
  selector:
    app: healthcheck
  ports:
  - name: http
    protocol: TCP
    port: 4000
    targetPort: 4000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: healthcheck
  name: healthcheck
spec:
  selector:
    matchLabels:
      app: healthcheck
  replicas: 2
  template:
    metadata:
      labels:
        app: healthcheck
    spec:
      containers:
      - name: responder-ctn
        image: prodigy413/hc-responder:1.0
        #imagePullPolicy: Always
        imagePullPolicy: IfNotPresent
        env:
        - name: TZ
          value: "Asia/Tokyo"
        ports:
        - name: http
          containerPort: 4000
        volumeMounts:
        - name: flagfile
          mountPath: /mount
      - name: resource-checker-ctn
        image: prodigy413/hc-resource-checker:1.0
        #imagePullPolicy: Always
        imagePullPolicy: IfNotPresent
        lifecycle:
          postStart:
            exec:
              command:
              - /bin/sh
              - -c
              - cp /tmp/ms-list.yaml /config/ms-list.yaml
              - python3 /work/validator.py
        env:
        - name: TZ
          value: "Asia/Tokyo"
#        livenessProbe:
#          exec:
#            command: ["python3", "resource-checker.py"]
#          initialDelaySeconds: 10
#          periodSeconds: 10
#          failureThreshold: 2
#          timeoutSeconds: 5
#          successThreshold: 1
        volumeMounts:
        - name: ms-list
          mountPath: /tmp/ms-list.yaml
          subPath: ms-list.yaml
        - name: flagfile
          mountPath: /mount
        - name: test-py
          mountPath: /tmp/test.py
          subPath: test.py
      serviceAccountName: healthcheck-sa
      volumes:
      - name: flagfile
        emptyDir: {}
      - name: ms-list
        configMap:
          name: ms-list
          items:
          - key: ms-list.yaml
            path: ms-list.yaml
      - name: test-py
        configMap:
          name: test-py
          items:
          - key: test.py
            path: test.py
---
apiVersion: v1
data:
  test.py: |
    from os import remove
    from requests import get
    from custom_logging import set_logging
    from yaml import safe_load
    import variables as var
    logger = set_logging(__name__)

    def get_data(kind: list) -> dict:
        # Get resource data

        with open(var.token_file, 'r') as f:

            token = f.readline()
        with open(var.namespace_file, 'r') as f:
            namespace = f.readline()
        url = f'https://{var.apiserver}:443/apis/apps/v1/namespaces/{namespace}/{kind}'
        headers = {'Authorization': 'Bearer ' + token}
        try:

            data = get(url, headers=headers, verify=var.cacert)
            if data.status_code != 200:

                exit(1)
        except Exception:
            logger.error('Failed to get resource data')
            exit(1)
        return data.json()

    def check_pod_status(listdata: dict) -> bool:
        # Set flag

        flag = True

        for kind in listdata.keys():
            data = get_data(kind)
            items = data['items']

            ms_status_data = dict()
            for x in items:
                try:

                    ms_status_data[x['metadata']['name']] = x['status']['availableReplicas']
                except KeyError:
                    ms_status_data[x['metadata']['name']] = 0
            # Check pod status
            for ms in listdata[kind]:
                try:

                    if ms_status_data[ms] == 0:
                        flag = False
                        logger.info(f'{ms}: No pods available.')
                except KeyError:
                    flag = False
                    logger.info(f'{ms}: No {kind} found.')
        return flag


    # Get ms list data

    with open(var.listfile, 'r') as f:
        yaml_data = safe_load(f)

    # Check pod status if list data is not empty
    if yaml_data is not None:
        flag = check_pod_status(yaml_data)

    # Control flag file
    if flag:
        try:
            with open(var.flagfile, 'w'):
                logger.info('flagfile created')
        except Exception:
            logger.error('Failed to create flagfile')
    else:
        try:
            remove(var.flagfile)
            logger.info('flagfile removed')
        except FileNotFoundError:
            logger.info('flagfile removed')
        except Exception:
            logger.error('Failed to remove flagfile')

kind: ConfigMap
metadata:
  labels:
    app: healthcheck
  name: test-py
~~~

- manifest.yaml
~~~yaml
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
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        #image: prodigy413/hc-responder:1.0
        image: prodigy413/resource-checker:1.0
        imagePullPolicy: Always
        volumeMounts:
        - name: flagfile
          mountPath: /mount
      serviceAccountName: healthcheck-sa
      volumes:
      - name: flagfile
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx
  ports:
  - name: http
    protocol: TCP
    port: 4000
    targetPort: 4000
~~~

- ms-list.yaml
~~~
deployments:
- nginx-deployment-01
- nginx-deployment-02
#- nginx-deployment-03
statefulsets:
- nginx-statefulset-01
- nginx-statefulset-02
#- nginx-statefulset-03
~~~

~~~
### To use venv
sudo apt install python3.10-venv -y

mkdir test && cd test
python3 -m venv venv

### Activate
source venv/bin/activate

### Deactivate
deactivate

python3 -m pip list

### basic
pip install requests PyYAML pydantic Flask
~~~

~~~
docker build . -t prodigy413/hc-responder:1.0
docker build -f Dockerfile-responder . -t prodigy413/hc-responder:1.0
docker push prodigy413/hc-responder:1.0

docker build . -t prodigy413/resource-checker:1.0
docker build -f ./Dockerfile-resource-checker . -t prodigy413/hc-resource-checker:1.0
docker push prodigy413/hc-resource-checker:1.0
~~~

- Dockerfile-resource-checker
~~~
FROM python:3.11.7-slim

USER 0

COPY ./resource-checker/requirements.txt /code/

RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt \
  && python3 -m pip uninstall -y pip \
  && mkdir -m 775 /config \
  && mkdir /work \
  && rm -rf /code 

COPY --chown=1001:0 ./resource-checker/*.py /work/
COPY --chown=1001:0 ./common /work
COPY --chown=1001:0 ./resource-checker/ms-list.yaml /config/

USER 1001

WORKDIR /work

ENTRYPOINT ["sleep", "infinity"]
~~~

- Dockerfile-responder
~~~
FROM python:3.11.7-slim

USER 0

COPY ./responder/requirements.txt /code/

RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt \
  && python3 -m pip uninstall -y pip \
  && mkdir /work \
  && rm -rf /code 

COPY --chown=1001:0 ./responder/*.py /work/
COPY --chown=1001:0 ./common /work

ENV FLASK_APP responder.py
ENV FLASK_RUN_PORT 4000
ENV FLASK_DEBUG 0

#RUN chmod 644 /work/*

USER 1001

WORKDIR /work

EXPOSE 4000

ENTRYPOINT [ "flask", "run", "--host=0.0.0.0" ]
~~~

- custom_logging.py
~~~python
from logging import Formatter, FileHandler, getLogger, INFO, WARN


def set_logging(name: str, level: str = 'info'):
    logger = getLogger(name)
    if level == 'info':
        logger.setLevel(INFO)
    elif level == 'warn':
        logger.setLevel(WARN)
    else:
        raise Exception('Only INFO or WARN is available')
    date_format = '%Y-%m-%d %H:%M:%S'
    formatter = Formatter(fmt='%(asctime)s.%(msecs)03d %(levelname)s %(message)s', datefmt=date_format)

    file_handler = FileHandler(filename='/proc/1/fd/1', encoding='utf-8')
    file_handler.setLevel(INFO)
    file_handler.setFormatter(formatter)

    logger.addHandler(file_handler)

    return logger


if __name__ == "__main__":
    logger = set_logging(__name__)
    logger.info('test')
~~~

- variables.py
~~~python
# flag
flag = True

# File path
cacert = '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'
flagfile = '/mount/healthcheck_ok.txt'
listfile = '/config/ms-list.yaml'
namespace_file = '/var/run/secrets/kubernetes.io/serviceaccount/namespace'
token_file = '/var/run/secrets/kubernetes.io/serviceaccount/token'

# API SERVER
apiserver = 'kubernetes.default.svc'
~~~

- ms-list.yaml
~~~yaml
# This is a sample list.
# Please overwrite this file when actually using it.
~~~

- requirements.txt
~~~
pydantic
PyYAML
requests
~~~

- resource-checker.py
~~~python
from custom_logging import set_logging
from os import remove
from requests import get
from yaml import safe_load
import variables as var

logger = set_logging(__name__)


def get_data(kind: list) -> dict:
    # Get resource data
    with open(var.token_file, 'r') as f:
        token = f.readline()
    with open(var.namespace_file, 'r') as f:
        namespace = f.readline()

    url = f'https://{var.apiserver}:443/apis/apps/v1/namespaces/{namespace}/{kind}'
    headers = {'Authorization': 'Bearer ' + token}

    try:
        data = get(url, headers=headers, verify=var.cacert)
        if data.status_code != 200:
            exit(1)
    except Exception:
        logger.error('Failed to get resource data')
        exit(1)

    return data.json()


def check_pod_status(listdata: dict) -> bool:
    # Set flag
    flag = True

    for kind in listdata.keys():
        data = get_data(kind)
        items = data['items']

        ms_status_data = dict()
        for x in items:
            try:
                ms_status_data[x['metadata']['name']] = x['status']['availableReplicas']
            except KeyError:
                ms_status_data[x['metadata']['name']] = 0

        # Check pod status
        for ms in listdata[kind]:
            try:
                if ms_status_data[ms] == 0:
                    flag = False
                    logger.info(f'{ms}: No pods available.')
                    break
            except KeyError:
                flag = False
                logger.info(f'{ms}: No {kind} found.')
                break
        if not flag:
            break

    return flag


# Get ms list data
with open(var.listfile, 'r') as f:
    yaml_data = safe_load(f)

# Check pod status if list data is not empty
if yaml_data is not None:
    flag = check_pod_status(yaml_data)
else:
    flag = True

# Control flag file
if flag:
    try:
        with open(var.flagfile, 'w'):
            logger.info('flagfile created')
    except Exception:
        logger.error('Failed to create flagfile')
else:
    try:
        remove(var.flagfile)
        logger.info('flagfile removed')
    except FileNotFoundError:
        logger.info('flagfile removed')
    except Exception:
        logger.error('Failed to remove flagfile')
~~~

- validator.py
~~~python
from custom_logging import set_logging
from os import path
from typing import List
from pydantic import BaseModel, ConfigDict, field_validator
import variables as var
from yaml import safe_load


# Definition for checking yaml
class YamlCheck(BaseModel):
    model_config = ConfigDict(extra='forbid')

    deployments: List[str] = []
    statefulsets: List[str] = []

    @field_validator('deployments', 'statefulsets')
    @classmethod
    def no_spaces(cls, v: list) -> str:
        for x in v:
            if ' ' in x:
                logger.error('Yaml check failed. Check yaml file again.')
                exit(1)


logger = set_logging(__name__)

# Check file path
filepath = [var.cacert, var.listfile, var.namespace_file, var.token_file]
for f in filepath:
    if not path.exists(f):
        logger.error(f'Failed to find path: {f}.')
        exit(1)

# Check yaml
try:
    with open(var.listfile, 'r') as f:
        yaml_data = safe_load(f)
    if yaml_data is not None:
        YamlCheck(**yaml_data)
    logger.info('Validation check OK.')
except Exception:
    logger.error('Yaml check failed. Check yaml file again.')
    exit(1)
~~~

- requirements.txt
~~~
flask
~~~

- responder.py
~~~python
from custom_logging import set_logging
import os
from flask import Flask
from variables import flagfile

# Path Configuration
set_logging('werkzeug', 'warn')
logger = set_logging(__name__)

# Healthcheck Configuration
app = Flask(__name__)


@app.route('/healthcheck')
def healthcheck():
    file_exists = os.path.isfile(flagfile)
    if file_exists:
        logger.info('Return HealthcheckOK 200')
        return 'HealthcheckOK', 200, {'Content-Type': 'text/plain; charset=utf-8'}
    else:
        logger.info('Return Internal Server Error 500')
        return 'Internal Server Error', 500, {'Content-Type': 'text/plain; charset=utf-8'}


# readinessProbe Configuration
@app.route('/healthz')
def liveness():
    return 'Container healthcheck OK', 200


# Exception Configuration
@app.errorhandler(404)
def not_found(e):
    logger.error('Return HealthcheckNG 404')
    return 'HealthCheckNG', 404


@app.errorhandler(Exception)
def undefined_exception(e):
    logger.error('This is unexpected error.')
    return e
~~~
