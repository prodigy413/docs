~~~
deploy.yaml
kind: Namespace
apiVersion: v1
metadata:
  name: release-01
---
kind: Namespace
apiVersion: v1
metadata:
  name: release-02
---
kind: Namespace
apiVersion: v1
metadata:
  name: release-03
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-bat-nginx01
  namespace: release-03
  labels:
    app: nginx
    group: test
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx01
  namespace: release-03
  labels:
    app: nginx
    group: test
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: bat-nginx02
  namespace: release-03
  labels:
    app: nginx
    group: test
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
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx02
  namespace: release-03
  labels:
    app: nginx
    group: test
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
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx03
  namespace: release-03
  labels:
    app: nginx
    group: test
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx04
  namespace: release-03
  labels:
    app: nginx
    group: test
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
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx05
  namespace: release-01
  labels:
    app: nginx
    group: test
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
        readinessProbe:
          exec:
            command:
            - /bin/bash
            - -c
            - test.sh
          initialDelaySeconds: 30
          periodSeconds: 5
          failureThreshold: 3
          timeoutSeconds: 1
          successThreshold: 1
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx06
  namespace: release-01
  labels:
    app: nginx
    group: test
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 3
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: test-bat-nginx06
  namespace: release-01
  labels:
    app: nginx
    group: test
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 3
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: bat-nginx06
  namespace: release-01
  labels:
    app: nginx
    group: test
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 3
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx07
  namespace: release-02
  labels:
    app: nginx
    group: test
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx08
  namespace: release-02
  labels:
    app: nginx
    group: test
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 3
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent




functions.py
from csv import reader, writer
from json import loads
from logging import basicConfig, getLogger, INFO
from os import path
from subprocess import run
from time import sleep


def set_logging():

    logger = getLogger()

    formatter = '%(asctime)s %(levelname)s %(message)s'
    date_format = '%Y/%m/%d %H:%M:%S'
    basicConfig(format=formatter, datefmt=date_format, level=INFO)

    return logger


logger = set_logging()


def check_command(cmd_list: list) -> None:

    for cmd in cmd_list:
        try:
            run([cmd], capture_output=True)
        except Exception:
            logger.error(f'Command {cmd} is not found.')
            exit(1)


def manage_csv(filepath: str = './data.csv', mode: str = 'r', data: list = None) -> list:

    if mode == 'w':
        with open(filepath, 'a') as f:
            write = writer(f)
            write.writerows(data)
    elif mode == 'r':
        if not path.exists(filepath):
            logger.error('csv file not found.')
            exit(1)

        with open(filepath, mode) as f:
            csv_data = list(reader(f))
            if len(csv_data) != 0:
                return_data = [x for x in csv_data]
                for x in return_data:
                    for i in range(len(x)):
                        try:
                            x[i] = int(x[i])
                        except ValueError:
                            pass
            else:
                logger.error('No csv data found.')
                exit(1)

        return_data.sort()

        return return_data
    else:
        logger.warning('Modes availiable are r(read) and w(write)')
        exit(1)


def get_namespace(filter: str = None) -> list:

    result = run(["kubectl", "get", "--raw", "/api/v1/namespaces"], capture_output=True, text=True)

    if result.returncode == 0:
        data = loads(result.stdout)['items']
        if len(data) != 0:
            if filter is not None:
                namespace = [x['metadata']['name'] for x in data if x['metadata']['name'].startswith(filter)]
            else:
                namespace = [x['metadata']['name'] for x in data if x['metadata']['name']]
    else:
        logger.error(result.stderr)
        exit(1)

    return namespace


def get_replicas(namespaces: list, kind: str) -> list:

    all_data = []

    if len(namespaces) == 0:
        logger.error('No namespaces found.')
        exit(1)

    if kind not in ['deployments', 'statefulsets']:
        logger.error('Only deployments and statefulsets are allowed.')
        exit(1)

    for ns in namespaces:
        result = run(["kubectl", "get", "--raw", f"/apis/apps/v1/namespaces/{ns}/{kind}"], capture_output=True, text=True)

        if result.returncode == 0:
            data = loads(result.stdout)['items']
            if len(data) != 0:
                resource_data = [[ns, f"{kind}/{x['metadata']['name']}", x['spec']['replicas'], x['status'].get('availableReplicas', 0)] for x in data]
                all_data += resource_data
            else:
                logger.info(f'{ns}: No {kind} found')
        else:
            logger.error(result.stderr)
            exit(1)

    all_data.sort()

    return all_data


def get_replicas_customize(namespaces: list, kind: str) -> list:

    all_data = []
    bat_data = []
    etc_data = []

    if len(namespaces) == 0:
        logger.error('No namespaces found.')
        exit(1)

    if kind not in ['deployments', 'statefulsets']:
        logger.error('Only deployments and statefulsets are allowed.')
        exit(1)

    for ns in namespaces:
        result = run(["kubectl", "get", "--raw", f"/apis/apps/v1/namespaces/{ns}/{kind}"], capture_output=True, text=True)

        if result.returncode == 0:
            data = loads(result.stdout)['items']
            if len(data) != 0:
                resource_data = [[ns, f"{kind}/{x['metadata']['name']}", x['spec']['replicas'], x['status'].get('availableReplicas', 0)] for x in data]
                all_data += resource_data
            else:
                logger.info(f'{ns}: No {kind} found')
        else:
            logger.error(result.stderr)
            exit(1)

    all_data.sort()

    for d in all_data:
        if 'bat-' in d:
            bat_data += d
        else:
            etc_data += d

    modified_data = etc_data + bat_data

    return [all_data, modified_data]


def scale(filepath: str) -> None:

    k8s_data = manage_csv(filepath=filepath)

    for data in k8s_data:
        result = run(["kubectl", "scale", data[1], "--replicas", str(data[2]), "-n", data[0]], capture_output=True, text=True)

        if result.returncode == 0:
            logger.info(f'{data[0]}/{data[1]}: Changed replcas to {data[2]}')
        else:
            logger.error(result.stderr)
            exit(1)

        sleep(10)


def diff(list1: list, list2: list) -> None:

    for x in [list1, list2]:
        if len(x) == 0:
            logger.error('List is empty.')
            exit(1)

    data = [[x, y] for x, y in zip(list1, list2) if x != y]
    for z in data:
        print(z)




main.py
from functions import check_command, diff, get_namespace, get_replicas, get_replicas_customize, manage_csv, scale, set_logging
from os import path
from sys import argv

# Set logging
logger = set_logging()

# Check
if len(argv) != 2:
    logger.warning('Only one command is allowed.')
    exit(1)

check_command(['kubectl'])

# Variables
csv_file = './data.csv'
modified_file = './modified_data.csv'
check_file = True

# Get namespace
namespace = get_namespace('release-')

# Get k8s resource data
if argv[1] == 'get-data':
    for kind in ['deployments', 'statefulsets']:
        if check_file:
            if path.exists(csv_file):
                logger.error('Same csv file is already exists.')
                exit(1)
            check_file = False

        data = get_replicas(namespace, kind)
        manage_csv(filepath=csv_file, mode='w', data=data)

# Get k8s resource data
elif argv[1] == 'get-data-multiple':
    for kind in ['deployments', 'statefulsets']:
        if check_file:
            if path.exists(csv_file):
                logger.error('Same csv file is already exists.')
                exit(1)
            check_file = False

        data = get_replicas_customize(namespace, kind)
        for d, f in zip(data, [csv_file, modified_file]):
            manage_csv(filepath=f, mode='w', data=d)

# Scale k8s resource
elif argv[1] == 'scale':
    scale(csv_file)

# Diff before and after
elif argv[1] == 'diff':

    new_data = []

    if not path.exists(csv_file):
        logger.error('csv file not found.')

    data = manage_csv(filepath=csv_file)

    for kind in ['deployments', 'statefulsets']:
        new_data += get_replicas(namespace, kind)
        new_data.sort()

    diff(data, new_data)

else:
    logger.error('Commands available are [get-data, scale, diff]')
    exit(1)





~~~
