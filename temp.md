~~~
auth
admin:FrbFMhrcN2VN2





apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: test-dashboard
rules:
- apiGroups: ["extensions", "apps"]
  resources: ["deployments"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods", "namespaces"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: test-dashboard
subjects:
- kind: ServiceAccount
  name: test-dashboard
  namespace: default
roleRef:
  kind: ClusterRole
  name: test-dashboard
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: test-dashboard
  namespace: default
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-dashboard
  labels:
    app: test-dashboard
spec:
  selector:
    matchLabels:
      app: test-dashboard
  replicas: 1
  template:
    metadata:
      labels:
        app: test-dashboard
    spec:
      serviceAccountName: test-dashboard
      containers:
      - name: test-dashboard
        image: prodigy413/fastapi:1.0
#        imagePullPolicy: IfNotPresent
        imagePullPolicy: Always
#        command: ["sleep", "infinity"]
        ports:
        - containerPort: 80
        env:
        - name: CLUSTER_NAME
          value: "TEST-CLUSTER"
        - name: TZ
          value: "Asia/Tokyo"
        readinessProbe:
          httpGet:
            path: /healthz
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 30
          failureThreshold: 3
          timeoutSeconds: 5
          successThreshold: 1
        livenessProbe:
          httpGet:
            path: /healthz
            port: 80
          initialDelaySeconds: 60
          periodSeconds: 30
          failureThreshold: 3
          timeoutSeconds: 5
          successThreshold: 1
---
apiVersion: v1
kind: Service
metadata:
  name: test-dashboard
spec:
  selector:
    app: test-dashboard
  type: ClusterIP
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
#---
#apiVersion: gateway.networking.k8s.io/v1
#kind: HTTPRoute
#metadata:
#  name: dashboard
#spec:
#  parentRefs:
#  - name: tls-gateway
#    namespace: kube-system
#    sectionName: http
#  hostnames:
#  - dashboard.test.local
#  rules:
#  - matches:
#    - path:
#        type: PathPrefix
#        value: /
#    backendRefs:
#    - name: test-dashboard
#      port: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: dashboard
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required - admin'
spec:
  ingressClassName: nginx
  rules:
  - host: dashboard.test.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: test-dashboard
            port:
              number: 80
---
apiVersion: v1
kind: Secret
metadata:
  creationTimestamp: null
  name: basic-auth
data:
  auth: YWRtaW46RnJiRk1ocmNOMlZOMg==















requirements.txt
fastapi==0.108.0
Jinja2==3.1.2
uvicorn==0.25.0

pip freeze > requirements.txt
docker build . -t prodigy413/fastapi:1.0
docker push prodigy413/fastapi:1.0
docker rmi prodigy413/fastapi:1.0


FROM python:3.11.7-slim
#FROM python:3.11.7

WORKDIR /app

COPY ./requirements.txt /code/requirements.txt

RUN apt-get update \
&& apt-get install curl -y \
&& curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
&& install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
&& pip install --no-cache-dir --upgrade -r /code/requirements.txt \
&& apt-get purge curl -y \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* kubectl

COPY ./app /app

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80", "--log-level", "warning"]
# uvicorn main:app --reload --limit-concurrency 5 --log-level warning





app/
static/css
static/images
templates



styles_main.css
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    font-family: sans-serif;
}

.side-nav {
    width: 210px;
    height: 100%;
    position: fixed;
    top: 0;
    left: 0;
    padding: 30px 15px;
    background: rgb(241, 241, 241);
    backdrop-filter: blur(5px);
    flex-direction: column;
}

ul {
    list-style: none;
    padding: 0 0px;
}

ul li {
    margin: 5px 0;
    padding: 5px 10px;
    display: flex;
    text-align: left;
    justify-content: left;
    cursor: pointer;
}

ul a {
    display: block;
    font-weight: bold;
    text-decoration: none;
    text-indent: 10px;
    color: #444;
}

li:hover {
    width: 100%;
    background: rgba(220, 220, 220, 1);
    backdrop-filter: blur(5px);
    border-radius: 10px;
}

body {
    background: #fafafa;
    color: #444;
    font: 100%/30px sans-serif;
    text-shadow: 0 1px 0 #fff;
}




styles_ns.css
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    font-family: sans-serif;
}

.side-nav {
    width: 210px;
    height: 100%;
    position: fixed;
    top: 0;
    left: 0;
    padding: 30px 15px;
    background: rgb(241, 241, 241);
    backdrop-filter: blur(5px);
    flex-direction: column;
}

ul {
    list-style: none;
    padding: 0 0px;
}

ul li {
    margin: 5px 0;
    padding: 5px 10px;
    display: flex;
    text-align: left;
    justify-content: left;
    cursor: pointer;
}

ul a {
    display: block;
    font-weight: bold;
    text-decoration: none;
    text-indent: 10px;
    color: #444;
}

li:hover {
    width: 100%;
    background: rgba(220, 220, 220, 1);
    backdrop-filter: blur(5px);
    border-radius: 10px;
}

h1, h2 {
    width: 900px;
    margin-left: auto;
    margin-right: auto;
    text-align: left;
}

hr {
    width: 900px;
    margin-left: auto;
    margin-right: auto;
}

body {
    background: #fafafa;
    color: #444;
    font: 100%/30px sans-serif;
    text-shadow: 0 1px 0 #fff;
}

strong {
    font-weight: bold;
}

em {
    font-style: italic;
}

.content {
    margin: 30px 0;
}

table {
    background: #f5f5f5;
    border-collapse: separate;
    box-shadow: inset 0 1px 0 #fff;
    font-size: 14px;
    line-height: 16px;
    margin: 15px auto;
    text-align: left;
    width: 900px;
}

th {
    background: linear-gradient(#777, #444);
    border-left: 1px solid #555;
    border-right: 1px solid #777;
    border-top: 1px solid #555;
    border-bottom: 1px solid #333;
    box-shadow: inset 0 1px 0 #999;
    color: #fff;
    font-weight: bold;
    padding: 5px 10px;
    position: relative;
    text-shadow: 0 1px 0 #000;
}

th:after {
    background: linear-gradient(rgba(255, 255, 255, 0), rgba(255, 255, 255, .08));
    content: '';
    display: block;
    height: 25%;
    left: 0;
    margin: 1px 0 0 0;
    position: absolute;
    top: 25%;
    width: 100%;
}

th:first-child {
    border-left: 1px solid #777;
    box-shadow: inset 1px 1px 0 #999;
}

th:last-child {
    box-shadow: inset -1px 1px 0 #999;
}

.abnormal {
    color: rgb(214, 122, 127);
}

td {
    border-right: 1px solid #fff;
    border-left: 1px solid #e8e8e8;
    border-top: 1px solid #fff;
    border-bottom: 1px solid #e8e8e8;
    padding: 5px 10px;
    position: relative;
    transition: all 300ms;
}

td:first-child {
    box-shadow: inset 1px 0 0 #fff;
}

td:last-child {
    border-right: 1px solid #e8e8e8;
    box-shadow: inset -1px 0 0 #fff;
}

tr:nth-child(odd) td {
    background: #f1f1f1;
}

tr:last-of-type td {
    box-shadow: inset 0 -1px 0 #fff;
}

tr:last-of-type td:first-child {
    box-shadow: inset 1px -1px 0 #fff;
}

tr:last-of-type td:last-child {
    box-shadow: inset -1px -1px 0 #fff;
}









error.html
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Test Dashboard</title>
        <link rel="stylesheet" href="/static/css/styles_ns.css">
        <link rel="icon" href="/static/images/favicon.ico">
    </head>
    <body>
        <P>Failed to access page.</P>
        <P>Go to main page.</P>
        <a href="/">main page</a>
    </body>
</html>



index.html
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Test Dashboard</title>
        <link rel="stylesheet" href="/static/css/styles_main.css">
        <link rel="icon" href="/static/images/favicon.ico">
    </head>
    <body>
        <div class="header">
            <div class="side-nav">
                <ul>
                    {% for i in ns %}
                    <a href="ns/{{ i }}"><li>{{ i }}</li></a>
                    {% endfor %}
                </ul>
            </div>
        </div>
    </body>
</html>



ns.html
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Test Dashboard</title>
        <link rel="stylesheet" href="/static/css/styles_ns.css">    
        <link rel="icon" href="/static/images/favicon.ico">
<!--         <script>
            function autoRefresh() {
                location.reload();
            }
            setInterval('autoRefresh()', 10000);
        </script> -->
    </head>
    <body>
        <div class="header">
            <div class="side-nav">
                <ul>
                    <a href="../"><li>Home</li></a><hr style="width: 150px">
                    {% for i in ns %}
                    <a href="{{ i }}"><li>{{ i }}</li></a>
                    {% endfor %}
                </ul>
            </div>
        </div>
        <div class="content">
            <h1>Environment</h1>
            <table>
                <thead>
                    <tr>
                        <th>Cluster</th>
                        <th>Namespace</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>{{ cluster }}</td>
                        <td>{{ ns_name }}</td>
                    </tr>
                </tbody>
            </table><br>
            <hr><br>
            {% for k, v in deployment_data.items() %}
            <h2>{{ k }} ({{ v|length - 1 }})</h2>
            {% endfor %}
            <table>
                <thead>
                    <tr>
                        {% for v in deployment_data.values() %}
                            {% for th in v[0] %}
                            <th>{{ th }}</th>
                            {% endfor %}
                        {% endfor %}
                    </tr>
                </thead>
                <tbody>
                    {% for v in deployment_data.values() %}
                        {% for tr in v[1:] %}
                            {% if tr.5 == 'True' %}
                            <tr>
                            {% else %}
                            <tr class="abnormal">
                            {% endif %}
                                {% for td in tr[:5] %}
                                <td>{{ td }}</td>
                                {% endfor %}
                            </tr>
                        {% endfor %}
                    {% endfor %}
                </tbody>
            </table><br>

            {% for k, v in pod_data.items() %}
            <h2>{{ k }} ({{ v|length - 1 }})</h2>
            {% endfor %}
            <table>
                <thead>
                    <tr>
                        {% for v in pod_data.values() %}
                            {% for th in v[0] %}
                            <th>{{ th }}</th>
                            {% endfor %}
                        {% endfor %}
                    </tr>
                </thead>
                <tbody>
                    {% for v in pod_data.values() %}
                        {% for tr in v[1:] %}
                            {% if tr.5 == 'True' %}
                            <tr>
                            {% else %}
                            <tr class="abnormal">
                                {% endif %}
                                    {% for td in tr[:5] %}
                                    <td>{{ td }}</td>
                                    {% endfor %}
                            </tr>
                        {% endfor %}
                    {% endfor %}
                </tbody>
            </table>
        </div>
    </body>
</html>








k8s_data.py
from subprocess import run


# Get deployment / pod
def get_data(ns: str, kind: str) -> dict:

    # Check kind
    if kind == 'deployment':
        headers = ['NAME', 'READY', 'UP-TO-DATE', 'AVAILABLE', 'AGE']
    elif kind == 'pod':
        headers = ['NAME', 'READY', 'STATUS', 'RESTARTS', 'AGE']
    else:
        raise Exception('Available values are deployment and pod')

    # Get k8s data
    data = run(['kubectl', '-n', ns, 'get', kind, '-owide', '--no-headers'],
               capture_output=True, text=True)
    if data.returncode == 0:
        if len(data.stdout.strip()) == 0:
            data_list = [f'No {kind} resources found']
        else:
            data_list = data.stdout.strip().split('\n')
            # Format data
            for i in range(len(data_list)):
                data_splitted = [x.lstrip() for x in data_list[i].split('  ') if x != '']
                del data_splitted[len(headers):]
                data_list[i] = data_splitted

                # Check deployment / pod status 
                if kind == 'deployment':
                    if data_list[i][1] == '0/0' or data_list[i][2] != data_list[i][3]:
                        data_list[i].append('False')
                    else:
                        data_list[i].append('True')
                elif kind == 'pod':
                    ready = data_list[i][1].split('/')
                    if data_list[i][2].lower() != 'running' or ready[0] != ready[1]:
                        data_list[i].append('False')
                    else:
                        data_list[i].append('True')
                else:
                    raise Exception('Wrong kind.')
            data_list.insert(0, headers)
    else:
        raise Exception(f'Failed to get {kind} data')

    return {f'{kind.title()}': data_list}


# Get namespace
def get_ns(ns_prefix: list) -> list:
    # Get k8s data
    data = run(['kubectl', 'get', 'ns', '-oname'], capture_output=True, text=True)
    if data.returncode == 0:
        data_list = [x.replace('namespace/', '') for x in data.stdout.strip().split('\n')]
    else:
        raise Exception('Failed to get namespace data')

    ns_list = [x for x in data_list if x.startswith(tuple(ns_prefix))]

    return ns_list



main.py

from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from os import environ
from k8s_data import get_ns, get_data

app = FastAPI()
app.mount(path="/static", app=StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

ns = []


@app.get("/")
async def home(request: Request):
    global ns
    ns = get_ns(['release-', 'ns-'])
    return templates.TemplateResponse("index.html", {"request": request, "ns": ns})


@app.get("/ns/{namespace}")
async def about(request: Request, namespace: str):
    deployment_data = get_data(namespace, 'deployment')
    pod_data = get_data(namespace, 'pod')
    try:
        cluster = environ["CLUSTER_NAME"]
    except KeyError:
        cluster = "Anonymous"

    if len(ns) == 0:
        return templates.TemplateResponse("error.html", {"request": request})
    else:
        return templates.TemplateResponse("ns.html", {
            "request": request,
            "ns": ns,
            "ns_name": namespace,
            "deployment_data": deployment_data,
            "pod_data": pod_data,
            "cluster": cluster
            })


@app.get("/healthz")
async def healthcheck():
    return {"healthstatus": "ok"}


~~~
