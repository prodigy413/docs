~~~
start-ms.py

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




functions.py

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




create_manifest.py

from pathlib import Path

ms_data = {
    "release-01": [
        {"kind": "Deployment", "details": [
            {"name": "nginx-01-app-de", "replicas": 2},
            {"name": "nginx-01-bat-de", "replicas": 1}
            ]
        },
        {"kind": "StatefulSet", "details": [
            {"name": "nginx-01-app-st", "replicas": 2},
            {"name": "nginx-01-bat-st", "replicas": 1}
            ]
        }
    ],
    "release-02": [
        {"kind": "Deployment", "details": [
            {"name": "nginx-02-app-de", "replicas": 2},
            {"name": "nginx-02-bat-de", "replicas": 1}
            ]
        },
        {"kind": "StatefulSet", "details": [
            {"name": "nginx-02-app-st", "replicas": 2},
            {"name": "nginx-02-bat-st", "replicas": 1}
            ]
        }
    ],
    "release-03": [
        {"kind": "Deployment", "details": [
            {"name": "nginx-03-app-de", "replicas": 2},
            {"name": "nginx-03-bat-de", "replicas": 1}
            ]
        },
        {"kind": "StatefulSet", "details": [
            {"name": "nginx-03-app-st", "replicas": 2},
            {"name": "nginx-03-bat-st", "replicas": 1}
            ]
        }
    ],
    "release-04": [
        {"kind": "Deployment", "details": [
            {"name": "nginx-04-app-de", "replicas": 2},
            {"name": "nginx-04-bat-de", "replicas": 1}
            ]
        },
        {"kind": "StatefulSet", "details": [
            {"name": "nginx-04-app-st", "replicas": 2},
            {"name": "nginx-04-bat-st", "replicas": 1}
            ]
        }
    ]
}

filename = '/home/obi/test/develop-code/python/kubernetes/scale_multiple_resource/ms.yaml'

file = Path(filename)

if file.exists():
    file.unlink()

def create_namespace(mslist):
    for namespace in mslist.keys():
        manifest = f'''---
apiVersion: v1
kind: Namespace
metadata:
  name: {namespace}
'''
        with file.open(mode='a') as f:
            f.write(manifest)


def create_manifest(mslist):
    for namespace, ms_data in mslist.items():
        for ms in ms_data:
            for detail in ms['details']:
                manifest=f'''---
apiVersion: apps/v1
kind: {ms['kind']}
metadata:
  name: {detail['name']}
  namespace: {namespace}
  labels:
    name: {detail['name']}
    app: {ms['kind'].lower()}
    type: ms
spec:
  selector:
    matchLabels:
      name: {detail['name']}
  replicas: {detail['replicas']}
  template:
    metadata:
      labels:
        name: {detail['name']}
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
'''
                with file.open(mode='a') as f:
                    f.write(manifest)

create_namespace(ms_data)
create_manifest(ms_data)




readme.md

kubectl -n release-01 scale deployments -l type=ms --replicas 0
kubectl -n release-02 scale deployments -l type=ms --replicas 0
kubectl -n release-03 scale deployments -l type=ms --replicas 0
kubectl -n release-04 scale deployments -l type=ms --replicas 0
kubectl -n release-01 scale statefulsets -l type=ms --replicas 0
kubectl -n release-02 scale statefulsets -l type=ms --replicas 0
kubectl -n release-03 scale statefulsets -l type=ms --replicas 0
kubectl -n release-04 scale statefulsets -l type=ms --replicas 0

kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}'

kubectl get --raw /apis/apps/v1/namespaces/default/statefulsets
kubectl get --raw /apis/apps/v1/namespaces/default/deployments

kubectl get --raw /apis/apps/v1/namespaces/release-01/deployments

python3 start-ms.py get-data reg01-ms-list-before.csv reg01-ms-list-for-start.csv
python3 start-ms.py scale reg01-ms-list-for-start.csv
python3 start-ms.py diff reg01-ms-list-before.csv reg01-ms-list-after.csv




deploy.yaml

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
---
kind: Namespace
apiVersion: v1
metadata:
  name: istio-test
  labels:
    name: istio-test
    istio-injection: enabled
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
        ports:
        - name: http
          containerPort: 80




rate_limit.yaml

apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: filter-local-ratelimit-svc
  #namespace: istio-system
  namespace: istio-test
spec:
  workloadSelector: #Pod label
    labels:
      app: nginx
  configPatches:
    - applyTo: HTTP_FILTER
      match:
        context: SIDECAR_INBOUND
        listener:
          filterChain:
            filter:
              name: "envoy.filters.network.http_connection_manager"
      patch:
        operation: INSERT_BEFORE
        value:
          name: envoy.filters.http.local_ratelimit
          typed_config:
            "@type": type.googleapis.com/udpa.type.v1.TypedStruct
            type_url: type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
            value:
              stat_prefix: http_local_rate_limiter
              token_bucket:
                max_tokens: 4
                tokens_per_fill: 4
                fill_interval: 60s
              filter_enabled:
                runtime_key: local_rate_limit_enabled
                default_value:
                  numerator: 100
                  denominator: HUNDRED
              filter_enforced:
                runtime_key: local_rate_limit_enforced
                default_value:
                  numerator: 100
                  denominator: HUNDRED
              response_headers_to_add:
                - append: false
                  header:
                    key: x-local-rate-limit
                    value: 'true'




rate_limit_by_port.yaml

apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: filter-local-ratelimit-svc
  #namespace: istio-system
  namespace: istio-test
spec:
  workloadSelector:
    labels:
      app: nginx
  configPatches:
    - applyTo: HTTP_FILTER
      match:
        context: SIDECAR_INBOUND
        listener:
          filterChain:
            filter:
              name: "envoy.filters.network.http_connection_manager"
      patch:
        operation: INSERT_BEFORE
        value:
          name: envoy.filters.http.local_ratelimit
          typed_config:
            "@type": type.googleapis.com/udpa.type.v1.TypedStruct
            type_url: type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
            value:
              stat_prefix: http_local_rate_limiter
    - applyTo: HTTP_ROUTE
      match:
        context: SIDECAR_INBOUND
        routeConfiguration:
          vhost:
            name: "inbound|http|8000"
            route:
              action: ANY
      patch:
        operation: MERGE
        value:
          typed_per_filter_config:
            envoy.filters.http.local_ratelimit:
              "@type": type.googleapis.com/udpa.type.v1.TypedStruct
              type_url: type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
              value:
                stat_prefix: http_local_rate_limiter
                token_bucket:
                  max_tokens: 4
                  tokens_per_fill: 4
                  fill_interval: 60s
                filter_enabled:
                  runtime_key: local_rate_limit_enabled
                  default_value:
                    numerator: 100
                    denominator: HUNDRED
                filter_enforced:
                  runtime_key: local_rate_limit_enforced
                  default_value:
                    numerator: 100
                    denominator: HUNDRED
                response_headers_to_add:
                  - append: false
                    header:
                      key: x-local-rate-limit
                      value: 'true'



while sleep 1 ; do curl -s http://192.168.245.111 -H 'host: nginx-istio.test.local'> /dev/null ; done
~~~
