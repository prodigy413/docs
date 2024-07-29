~~~
import pandas as pd

def process_csv(input_csv, output_csv, filter_value):
    # Read the CSV file
    df = pd.read_csv(input_csv, header=None, names=['timestamp', 'az', 'ip', 'port', 'other'])

    # Filter rows based on the AZ value (e.g., 'az-a' or 'az-b')
    df = df[df['az'] == filter_value]

    # Remove duplicates
    df = df.drop_duplicates()

    # Pivot the table: IPs become columns, timestamps are the rows, and ports are the values
    pivot_df = df.pivot(index='timestamp', columns='ip', values='port').reset_index()

    # Save the pivoted DataFrame to a new CSV file
    pivot_df.to_csv(output_csv, index=False)

# Example usage
process_csv('path_to_csv_a.csv', 'path_to_csv_b.csv', 'az-a')






import pandas as pd

def process_csv(input_csv, output_csv, filter_value):
    # Read the CSV file
    df = pd.read_csv(input_csv, header=None, names=['timestamp', 'az', 'ip', 'port', 'other'])

    # Filter rows based on the AZ value (e.g., 'az-a' or 'az-b')
    df = df[df['az'] == filter_value]

    # Remove duplicates
    df = df.drop_duplicates()

    # Pivot the table: IPs become columns, timestamps are the rows, and ports are the values
    pivot_df = df.pivot(index='timestamp', columns='ip', values='port').reset_index()

    # Calculate sum and average of ports for each timestamp
    pivot_df['sum'] = pivot_df.iloc[:, 1:].sum(axis=1)
    pivot_df['average'] = pivot_df.iloc[:, 1:-1].mean(axis=1).round(0)  # exclude 'sum' column in mean calculation

    # Save the pivoted DataFrame to a new CSV file
    pivot_df.to_csv(output_csv, index=False)

# Example usage
process_csv('path_to_csv_a.csv', 'path_to_csv_b.csv', 'az-a')





---
kind: Namespace
apiVersion: v1
metadata:
  name: istio-test
  labels:
    name: istio-test
    istio-injection: enabled
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  annotations:
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header X-Forwarded-For "$http_x_forwarded_for";
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
            name: nginx
            port:
              number: 80
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
    port: 80
    targetPort: 80
---
apiVersion: v1
data:
  nginx.conf: |
    user  nginx;
    worker_processes  auto;

    error_log  /var/log/nginx/error.log notice;
    pid        /var/run/nginx.pid;


    events {
        worker_connections  1024;
    }


    http {
        include       /etc/nginx/mime.types;
        default_type  application/octet-stream;

        server_tokens on;

        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

        access_log  /var/log/nginx/access.log  main;

        sendfile        on;
        #tcp_nopush     on;

        keepalive_timeout  65;

        #gzip  on;

        include /etc/nginx/conf.d/*.conf;
    }
kind: ConfigMap
metadata:
  name: conf
---
apiVersion: v1
data:
  nginx.conf: |
    user  nginx;
    worker_processes  auto;

    error_log  /var/log/nginx/error.log notice;
    pid        /var/run/nginx.pid;


    events {
        worker_connections  1024;
    }


    http {
        include       /etc/nginx/mime.types;
        default_type  application/octet-stream;

        server_tokens on;

        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

        access_log  /var/log/nginx/access.log  main;

        sendfile        on;
        #tcp_nopush     on;

        keepalive_timeout  65;

        #gzip  on;

        include /etc/nginx/conf.d/*.conf;
    }
kind: ConfigMap
metadata:
  name: conf
  namespace: istio-test
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
      - name: nginx01
        image: nginx:1.25.3
        volumeMounts:
        - name: conf
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
      volumes:
      - name: conf
        configMap:
          name: conf
          items:
          - key: nginx.conf
            path: nginx.conf
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx-client
spec:
  containers:
  - name: nginx
    image: nginx:1.25.3
---
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: test-gw
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
    - "*"
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: test-vs
  namespace: istio-test
spec:
  gateways:
  - istio-system/test-gw
  hosts:
  - "nginx-istio.test.local"
  http:
  - route:
    - destination:
        host: nginx
        port:
          number: 80
    retries:
      attempts: 2
      retryOn: "429"
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: test-vs-internal
  namespace: istio-test
spec:
  gateways:
  - istio-system/test-gw
  hosts:
  - "ngix.istio-test.svc.cluster.local"
  http:
  - route:
    - destination:
        host: nginx
        port:
          number: 80
    retries:
      attempts: 2
      retryOn: "429"
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: istio-test
spec:
  selector:
    app: nginx
  ports:
  - name: http
    port: 80
    targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
  namespace: istio-test
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
        volumeMounts:
        - name: conf
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
      volumes:
      - name: conf
        configMap:
          name: conf
          items:
          - key: nginx.conf
            path: nginx.conf





~~~
curl -sI http://192.168.245.112 -H 'host: nginx.test.local'

curl -sI http://192.168.245.111 -H 'host: nginx-istio.test.local'

while sleep 1 ; do echo -n "$(date '+%Y/%m/%d %H:%M:%S') " ; curl -sI http://192.168.245.112 -H 'host: nginx.test.local' | head -1 ; done

curl -H 'X-Forwarded-For: 192.168.245.101' -sI http://192.168.245.112 -H 'host: nginx.test.local'

curl -H 'X-Forwarded-For: 192.168.245.101' -sI http://192.168.245.111 -H 'host: nginx-istio.test.local'

kubectl exec nginx-client -- curl -sI http://nginx
~~~

~~~
kubectl logs -f deploy/nginx

kubectl -n istio-test logs -f deploy/nginx
~~~

~~~
kubectl exec -it deploy/nginx -- bash
cat /etc/nginx/nginx.conf

kubectl exec deploy/nginx -- cat /etc/nginx/nginx.conf
~~~

~~~
helm upgrade test ingress-nginx/ingress-nginx -n ingress-system --set allow-backend-server-header=true
~~~





import pandas as pd

def process_csv(input_csv, output_csv, filter_value):
    # Read the CSV file
    df = pd.read_csv(input_csv, header=None, names=['timestamp', 'az', 'ip', 'port', 'other'])

    # Filter rows based on the AZ value (e.g., 'az-a' or 'az-b')
    df = df[df['az'] == filter_value]

    # Remove duplicates
    df = df.drop_duplicates()

    # Pivot the table: IPs become columns, timestamps are the rows, and ports are the values
    pivot_df = df.pivot(index='timestamp', columns='ip', values='port').reset_index()

    # Calculate sum and average of ports for each timestamp
    pivot_df['sum'] = pivot_df.iloc[:, 1:].sum(axis=1)
    pivot_df['average'] = pivot_df.iloc[:, 1:-1].mean(axis=1).round(0)  # exclude 'sum' column in mean calculation

    # Save the pivoted DataFrame to a new CSV file
    pivot_df.to_csv(output_csv, index=False)

# Example usage
process_csv('report_for_test.csv', 'path_to_csv_b.csv', 'az-a')





~~~
### To use venv
sudo apt install python3.12-venv -y

mkdir test && cd test
python3 -m venv venv

### Activate
source venv/bin/activate

### Deactivate
deactivate

python3 -m pip list

### basic
pip install pandas
~~~





from csv import reader, writer
from difflib import Differ
from json import loads
from logging import basicConfig, getLogger, INFO
from pathlib import Path
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
            raise SystemExit(logger.error(f'Command {cmd} is not found.'))


def check_file(filepath: str, if_exists: bool) -> None:
    file = Path(filepath)
    if if_exists:
        if file.exists():
            raise SystemExit(logger.error(f'File {file} already exists.'))
    else:
        if not file.exists():
            raise SystemExit(logger.error(f'File {file} already exists.'))


def manage_csv(filepath: str = './data.csv', mode: str = 'r', data: list = None) -> list:
    file = Path(filepath)
    if mode == 'w' and data is not None:
        with file.open('a') as f:
            csv_writer = writer(f)
            csv_writer.writerows(data)
    elif mode == 'r':
        if not file.exists():
            raise SystemExit(logger.error('file not found.'))
        with file.open(mode) as f:
            csv_data = list(reader(f))
            if csv_data:
                return_data = [x for x in csv_data]
                for row in return_data:
                    for i in range(len(row)):
                        try:
                            row[i] = int(row[i])
                        except ValueError:
                            pass
            else: 
                raise SystemExit(logger.error('No csv data found.'))
        return return_data
    else:
        raise SystemExit(logger.warning('Available modes are [r, w].'))


def get_namespace(filter: str = None) -> list:
    result = run(["kubectl", "get", "--raw", "/api/v1/namespaces"], capture_output=True, text=True)
    if result.returncode == 0:
        data = loads(result.stdout)['items']
        if data:
            if filter:
                return [x['metadata']['name'] for x in data if x['metadata']['name'].startswith(filter)]
            else:
                return [x['metadata']['name'] for x in data if x['metadata']['name']]
    else:
        raise SystemExit(logger.error(result.stderr))


def get_replicas(namespaces: list, kind: str) -> list:
    if not namespaces:
        raise SystemExit(logger.error('No namespaces found.'))
    all_data = []
    if kind in ['deployments', 'statefulsets']:
        for ns in namespaces:
            result = run(["kubectl", "get", "--raw", f"/apis/apps/v1/namespaces/{ns}/{kind}"], capture_output=True, text=True)
            if result.returncode == 0:
                ms_data = loads(result.stdout)['items']
                if ms_data:
                    replicas_data = [[ns, f"{kind}/{x['metadata']['name']}", x['spec']['replicas'], x['status'].get('availableReplicas', 0)] for x in ms_data]
                    all_data.extend(replicas_data)
                else:
                    logger.info(f'{ns}: No {kind} found')
            else:
                raise SystemExit(logger.error(result.stderr))
    elif kind == 'all':
        for ns in namespaces:
            for kind in ['deployments', 'statefulsets']:
                result = run(["kubectl", "get", "--raw", f"/apis/apps/v1/namespaces/{ns}/{kind}"], capture_output=True, text=True)
                if result.returncode == 0:
                    ms_data = loads(result.stdout)['items']
                    if ms_data:
                        replicas_data = [[ns, f"{kind}/{x['metadata']['name']}", x['spec']['replicas'], x['status'].get('availableReplicas', 0)] for x in ms_data]
                        all_data.extend(replicas_data)
                    else:
                        logger.info(f'{ns}: No {kind} found')
                else:
                    raise SystemExit(logger.error(result.stderr))
    else:
        raise SystemExit(logger.error('Available kinds are [deployments, statefulsets, all].'))
    all_data.sort()
    bat_data = [data for data in all_data if 'bat-' in data[1]]
    etc_data = [data for data in all_data if 'bat-' not in data[1]]
    return [all_data, etc_data + bat_data]


def scale(filepath: str) -> None:
    k8s_data = manage_csv(filepath=filepath)
    for data in k8s_data:
        result = run(["kubectl", "scale", data[1], "--replicas", str(data[2]), "-n", data[0]], capture_output=True, text=True)
        if result.returncode == 0:
            logger.info(f'{data[0]}/{data[1]}: Changed replicas to {data[2]}')
        else:
            raise SystemExit(logger.error(result.stderr))
        sleep(10)


def diff(file01: str, file02: str) -> None:
    with open(file01) as f1, open(file02) as f2:
        file1 = f1.readlines()
        file2 = f2.readlines()
        d = Differ()
        difference = [d.replace('\n', '') for d in d.compare(file1, file2) if d[0] in ('+', '-')]
    for d in difference:
        print(d)





---
apiVersion: v1
kind: Namespace
metadata:
  name: release-01
---
apiVersion: v1
kind: Namespace
metadata:
  name: release-02
---
apiVersion: v1
kind: Namespace
metadata:
  name: release-03
---
apiVersion: v1
kind: Namespace
metadata:
  name: release-04
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-01-app-de
  namespace: release-01
  labels:
    name: nginx-01-app-de
    app: deployment
    type: ms
spec:
  selector:
    matchLabels:
      name: nginx-01-app-de
  replicas: 2
  template:
    metadata:
      labels:
        name: nginx-01-app-de
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-01-bat-de
  namespace: release-01
  labels:
    name: nginx-01-bat-de
    app: deployment
    type: ms
spec:
  selector:
    matchLabels:
      name: nginx-01-bat-de
  replicas: 1
  template:
    metadata:
      labels:
        name: nginx-01-bat-de
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx-01-app-st
  namespace: release-01
  labels:
    name: nginx-01-app-st
    app: statefulset
    type: ms
spec:
  selector:
    matchLabels:
      name: nginx-01-app-st
  replicas: 2
  template:
    metadata:
      labels:
        name: nginx-01-app-st
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx-01-bat-st
  namespace: release-01
  labels:
    name: nginx-01-bat-st
    app: statefulset
    type: ms
spec:
  selector:
    matchLabels:
      name: nginx-01-bat-st
  replicas: 1
  template:
    metadata:
      labels:
        name: nginx-01-bat-st
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-02-app-de
  namespace: release-02
  labels:
    name: nginx-02-app-de
    app: deployment
    type: ms
spec:
  selector:
    matchLabels:
      name: nginx-02-app-de
  replicas: 2
  template:
    metadata:
      labels:
        name: nginx-02-app-de
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-02-bat-de
  namespace: release-02
  labels:
    name: nginx-02-bat-de
    app: deployment
    type: ms
spec:
  selector:
    matchLabels:
      name: nginx-02-bat-de
  replicas: 1
  template:
    metadata:
      labels:
        name: nginx-02-bat-de
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx-02-app-st
  namespace: release-02
  labels:
    name: nginx-02-app-st
    app: statefulset
    type: ms
spec:
  selector:
    matchLabels:
      name: nginx-02-app-st
  replicas: 2
  template:
    metadata:
      labels:
        name: nginx-02-app-st
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx-02-bat-st
  namespace: release-02
  labels:
    name: nginx-02-bat-st
    app: statefulset
    type: ms
spec:
  selector:
    matchLabels:
      name: nginx-02-bat-st
  replicas: 1
  template:
    metadata:
      labels:
        name: nginx-02-bat-st
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-03-app-de
  namespace: release-03
  labels:
    name: nginx-03-app-de
    app: deployment
    type: ms
spec:
  selector:
    matchLabels:
      name: nginx-03-app-de
  replicas: 2
  template:
    metadata:
      labels:
        name: nginx-03-app-de
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-03-bat-de
  namespace: release-03
  labels:
    name: nginx-03-bat-de
    app: deployment
    type: ms
spec:
  selector:
    matchLabels:
      name: nginx-03-bat-de
  replicas: 1
  template:
    metadata:
      labels:
        name: nginx-03-bat-de
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx-03-app-st
  namespace: release-03
  labels:
    name: nginx-03-app-st
    app: statefulset
    type: ms
spec:
  selector:
    matchLabels:
      name: nginx-03-app-st
  replicas: 2
  template:
    metadata:
      labels:
        name: nginx-03-app-st
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx-03-bat-st
  namespace: release-03
  labels:
    name: nginx-03-bat-st
    app: statefulset
    type: ms
spec:
  selector:
    matchLabels:
      name: nginx-03-bat-st
  replicas: 1
  template:
    metadata:
      labels:
        name: nginx-03-bat-st
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-04-app-de
  namespace: release-04
  labels:
    name: nginx-04-app-de
    app: deployment
    type: ms
spec:
  selector:
    matchLabels:
      name: nginx-04-app-de
  replicas: 2
  template:
    metadata:
      labels:
        name: nginx-04-app-de
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-04-bat-de
  namespace: release-04
  labels:
    name: nginx-04-bat-de
    app: deployment
    type: ms
spec:
  selector:
    matchLabels:
      name: nginx-04-bat-de
  replicas: 1
  template:
    metadata:
      labels:
        name: nginx-04-bat-de
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx-04-app-st
  namespace: release-04
  labels:
    name: nginx-04-app-st
    app: statefulset
    type: ms
spec:
  selector:
    matchLabels:
      name: nginx-04-app-st
  replicas: 2
  template:
    metadata:
      labels:
        name: nginx-04-app-st
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx-04-bat-st
  namespace: release-04
  labels:
    name: nginx-04-bat-st
    app: statefulset
    type: ms
spec:
  selector:
    matchLabels:
      name: nginx-04-bat-st
  replicas: 1
  template:
    metadata:
      labels:
        name: nginx-04-bat-st
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent





from functions import check_command, get_namespace, get_replicas, manage_csv, scale

check_command(['kubectl'])
namespace = get_namespace('release-')
#mslist01 = get_replicas(namespace, "deployments")
#mslist02 = get_replicas(namespace, "statefulsets")
ms_list_before, ms_list_for_start = get_replicas(namespace, "all")

manage_csv('ms_list_before.csv', 'w', ms_list_before)
manage_csv('ms_list_for_start.csv', 'w', ms_list_for_start)

#for x in mslist01:
#    for z in x:
#        print(z)
#    print()
#print()
#for x in mslist02:
#    for z in x:
#        print(z)
#    print()
#print()
#for x in mslist03:
#    for z in x:
#        print(z)
#    print()
#print()

#scale()





from functions import check_command, check_file, get_namespace, get_replicas, manage_csv, scale, set_logging, diff
from sys import argv

# Set logging
logger = set_logging()

## Check parameter
#if len(argv) < 2 or len(argv) > 3:
#    raise SystemExit(logger.error(f'Incorrect number of paramters.'))
#
#if len(argv) == 3 and not argv[2].endswith('.csv'):
#    raise SystemExit(logger.error(f'Wrong file format.'))

# Check command
check_command(['kubectl'])

# Get namespace
namespace = get_namespace('release-')

# Get k8s resource data
if argv[1] == 'get-data' and argv[2] and argv[3]:
    check_file(argv[2], True)
    ms_list_before, ms_list_for_start = get_replicas(namespace, 'all')
    manage_csv(argv[2], 'w', ms_list_before)
    manage_csv(argv[3], 'w', ms_list_for_start)


# Scale k8s resource
elif argv[1] == 'scale':
    check_file(argv[2], False)
    try:
        scale(argv[2])
    except IndexError:
        scale('ms-list-for-start.csv')

# Compare before and after
elif argv[1] == 'diff' and argv[2] and argv[3]:
    check_file(argv[2], False)
    check_file(argv[3], True)
    ms_list_after, ignore_list = get_replicas(namespace, "all")
    manage_csv(argv[3], 'w', ms_list_after)
    diff(argv[2], argv[3])

else:
    raise SystemExit(logger.error('Wrong parameters.'))

~~~
