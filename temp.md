~~~
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
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.25.3










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
                max_tokens: 10
                tokens_per_fill: 10
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











kubectl apply -f basic.yaml
while sleep 1 ; do curl -s http://192.168.245.111 -H 'host: nginx-istio.test.local'> /dev/null ; done
while sleep 1 ; do echo -n "$(date '+%Y/%m/%d %H:%M:%S') " ; curl -sI http://192.168.245.111 -H 'host: nginx-istio.test.local' | head -1 ; done
while sleep 1 ; do echo -n "$(date '+%Y/%m/%d %H:%M:%S') " ; curl -sI http://nginx.istio-test | head -1 ; done


### Images

- ratelimit<br>
envoyproxy/ratelimit:3fcc3609<br>
<https://hub.docker.com/layers/envoyproxy/ratelimit/3fcc3609/images/sha256-d24adda34c34a00a95752f8209f01fb5e807b257720a83829ef7a6c0649762a2?context=explore>

- redis<br>
redis:7.2.4<br>
<https://hub.docker.com/layers/library/redis/7.2.4/images/sha256-7aae2924046c2ad547fa222514e4e411f07ab2f6ba926c4673e911f41f5b4d6d?context=explore>










#!/bin/bash

rm -rf /tmp/test01
rm -rf /tmp/test02

mkdir -p /tmp/test01
mkdir -p /tmp/test02

echo "haha" > /tmp/test01/test01.txt
echo "haha" > /tmp/test01/test02.txt
echo "haha" > /tmp/test01/test03.txt
echo "haha" > /tmp/test01/test04.txt

echo "hahaha" > /tmp/test02/test01.txt
echo "hahaha" > /tmp/test02/test02.txt
echo "hahaha" > /tmp/test02/test03.txt

ls -lR /tmp/test01
ls -lR /tmp/test02

~~~


~~~
bash 00_create_env.sh

rm -rf /tmp/test01
rm -rf /tmp/test02
~~~

~~~
date ; ${kubectl} -n test-ns diff -f ./
date ; ${kubectl} -n test-ns apply -f ./

date ; ${kubectl} -n test-ns get -f ./
~~~

~~~
date ; LIST=$(${kubectl} -n test-ns get -f ./ | awk '{print $1}' | grep -e deployment. -e statefulset.) ; echo ${LIST} | tr ' ' '\n' 
date ; ${kubectl} -n test-ns scale ${LIST} --replicas=0



log
$ date ; LIST=$(${kubectl} -n test-ns get -f ./ | awk '{print $1}' | grep -e deployment. -e statefulset.) ; echo ${LIST} | tr ' ' '\n' 
Fri Jul 19 10:06:57 PM JST 2024
deployment.apps/nginx-01-app-deploy
statefulset.apps/nginx-01-app-statefulset
deployment.apps/nginx-01-bat-deploy
statefulset.apps/nginx-01-bat-statefulset
deployment.apps/nginx-02-app-deploy
statefulset.apps/nginx-02-app-statefulset
deployment.apps/nginx-02-bat-deploy
statefulset.apps/nginx-02-bat-statefulset


$ date ; ${kubectl} -n test-ns scale ${LIST} --replicas=0
Fri Jul 19 10:32:02 PM JST 2024
deployment.apps/nginx-01-app-deploy scaled
statefulset.apps/nginx-01-app-statefulset scaled
deployment.apps/nginx-01-bat-deploy scaled
statefulset.apps/nginx-01-bat-statefulset scaled
deployment.apps/nginx-02-app-deploy scaled
statefulset.apps/nginx-02-app-statefulset scaled
deployment.apps/nginx-02-bat-deploy scaled
statefulset.apps/nginx-02-bat-statefulset scaled
~~~

~~~
FILES=(
test01.txt
test02.txt
test03.txt
test04.txt
)

for FILE in ${FILES[@]}; do
    echo "###### ${FILE} ######"
    diff /tmp/test01/${FILE} /tmp/test02/
    cksum /tmp/test01/${FILE} /tmp/test02/${FILE}
    echo
done

for FILE in ${FILES[@]}; do
    sudo cp -pi /tmp/test01/${FILE} /tmp/test02/
done

~~~

~~~
date ; echo "MS COMMIT_ID" > LIST.TXT
while read LINE; do
    PODS=$(${kubectl} -n test-ns get pod -oname | grep ${LINE})
    for POD in ${PODS}; do
        echo -n "${LINE} " >> LIST.TXT
        ${kubectl} -n test-ns exec ${POD} -- env | grep COMMIT_ID | cut -d "=" -f2 >> LIST.TXT
    done
done << EOF
nginx-01-app-deploy
nginx-01-bat-deploy
nginx-02-app-statefulset
nginx-02-bat-statefulset
nginx-02-app-deploy
nginx-02-bat-deploy
nginx-01-app-statefulset
nginx-01-bat-statefulset
EOF

date ; echo -e "Full\n" ; cat LIST.TXT ; echo -e "\nUniq\n" ; uniq LIST.TXT | column -t


### log

$ date ; echo "MS COMMIT_ID" > LIST.TXT
while read LINE; do
    PODS=$(${kubectl} -n test-ns get pod -oname | grep ${LINE})
    for POD in ${PODS}; do
        echo -n "${LINE} " >> LIST.TXT
        ${kubectl} -n test-ns exec ${POD} -- env | grep COMMIT_ID | cut -d "=" -f2 >> LIST.TXT
    done
done << EOF
nginx-01-app-deploy
nginx-01-bat-deploy
nginx-02-app-statefulset
nginx-02-bat-statefulset
nginx-02-app-deploy
nginx-02-bat-deploy
nginx-01-app-statefulset
nginx-01-bat-statefulset
EOF
Fri Jul 19 06:37:00 PM JST 2024



$ date ; echo -e "Full\n" ; cat LIST.TXT ; echo -e "\nUniq\n" ; uniq LIST.TXT | column -t
Fri Jul 19 06:37:18 PM JST 2024
Full

MS COMMIT_ID
nginx-01-app-deploy MTIzNAo
nginx-01-app-deploy MTIzNAo
nginx-01-bat-deploy MjM0NQo
nginx-01-bat-deploy MjM0NQo
nginx-02-app-statefulset NDU2Nwo
nginx-02-app-statefulset NDU2Nwo
nginx-02-bat-statefulset Nzg5MQo
nginx-02-bat-statefulset Nzg5MQo
nginx-02-app-deploy ODkxMAo
nginx-02-app-deploy ODkxMAo
nginx-02-bat-deploy Njc4OQo
nginx-02-bat-deploy Njc4OQo
nginx-01-app-statefulset MzQ1Ngo
nginx-01-app-statefulset MzQ1Ngo
nginx-01-bat-statefulset NTY3OAo
nginx-01-bat-statefulset NTY3OAo

Uniq

MS                        COMMIT_ID
nginx-01-app-deploy       MTIzNAo
nginx-01-bat-deploy       MjM0NQo
nginx-02-app-statefulset  NDU2Nwo
nginx-02-bat-statefulset  Nzg5MQo
nginx-02-app-deploy       ODkxMAo
nginx-02-bat-deploy       Njc4OQo
nginx-01-app-statefulset  MzQ1Ngo
nginx-01-bat-statefulset  NTY3OAo
~~~

~~~
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






python3 start-ms.py get-data reg01-ms-list-before.csv reg01-ms-list-for-start.csv
python3 start-ms.py scale reg01-ms-list-for-start.csv
python3 start-ms.py diff reg01-ms-list-before.csv reg01-ms-list-after.csv
~~~
