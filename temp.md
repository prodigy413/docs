~~~
from datetime import datetime
from json import loads
from pathlib import Path
from subprocess import run

def msg(msg: str) -> str:
    current_time = datetime.now().strftime('%Y/%m/%d %H:%M:%S')
    return f'{current_time} {msg.strip()}'

def check_command(cmd_list: list) -> None:
    for cmd in cmd_list:
        try:
            run([cmd], capture_output=True, text=True)
        except FileNotFoundError:
            raise Exception(f'Command {cmd} is not found.')
    print(msg('Command check OK.'))

def check_files(file_list: list) -> None:
    for file in file_list:
        path = Path(file)
        if not path.is_file():
            raise Exception(f'{file} is not found.')
    print(msg('File check OK.'))

def get_all_api_resource() -> list:
    api = run(["kubectl", "api-resources", "--verbs=list", "--namespaced=true", "-oname"], capture_output=True, text=True)
    if api.returncode == 0:
        all_api_name = sorted(api.stdout.split('\n'))
        return all_api_name
    else:
        raise Exception('Failed to get api resources.')

def get_all_namespace() -> list:
    ns = run(["kubectl", "get", "ns", "-ojson"], capture_output=True, text=True)
    if ns.returncode == 0:
        all_ns_info = loads(ns.stdout)
        all_ns_name = [item['metadata']['name'] for item in all_ns_info['items']]
        return all_ns_name
    else:
        raise Exception('Failed to get namespace.')

def get_all_deploy(ns: str) -> list:
    if ns not in get_all_namespace():
        raise Exception(f'Namespace {ns} is not found.')
    deploy = run(["kubectl", "get", "deploy", "-ojson", "-n", ns], capture_output=True, text=True)
    if deploy.returncode == 0:
        all_deploy_info = loads(deploy.stdout)
        all_deploy_name = [item['metadata']['name'] for item in all_deploy_info['items']]
        return all_deploy_name
    else:
        raise Exception('Failed to get deployment.')

def get_all_pod(ns: str, deploy: str = None) -> list:
    if ns not in get_all_namespace():
        raise Exception(f'Namespace {ns} is not found.')
    if deploy != None:
        if deploy not in get_all_deploy(ns):
            raise Exception(f'Deployment {deploy} is not found.')
    pod = run(["kubectl", "get", "pod", "-ojson", "-n", ns], capture_output=True, text=True)
    if pod.returncode == 0:
        all_pod_info = loads(pod.stdout)
        if deploy != None:
            all_pod_name = [item['metadata']['name'] for item in all_pod_info['items'] if f'{deploy}-' in item['metadata']['name']]
        else:
            all_pod_name = [item['metadata']['name'] for item in all_pod_info['items']]
        return all_pod_name
    else:
        raise Exception('Failed to get pod.')

def get_all_secret(ns: str) -> list:
    if ns not in get_all_namespace():
        raise Exception(f'Namespace {ns} is not found.')
    secret = run(["kubectl", "get", "secret", "-ojson", "-n", ns], capture_output=True, text=True)
    if secret.returncode == 0:
        all_secret_info = loads(secret.stdout)
        all_secret_name = [item['metadata']['name'] for item in all_secret_info['items']]
        return all_secret_name
    else:
        raise Exception('Failed to get secret.')




from base64 import b64decode
from json import loads
from pathlib import Path
from subprocess import run
import sys
# Add path
sys.path.append(r'../utils')
import utils

# Check arguments
if len(sys.argv) < 3:
    raise Exception(f'2 arguments needed.')

ns = sys.argv[1]
secret = sys.argv[2]

# Check commands
commands = ['kubectl']
utils.check_command(commands)

# Check namespace
if ns not in utils.get_all_namespace():
    raise Exception(f'Namespace {ns} is not found.')

# Check secret
if secret not in utils.get_all_secret(ns):
    raise Exception(f'Secret {secret} is not found.')

get_secret = run(["kubectl", "get", "secret", secret, "-n", ns, "-ojson"], capture_output=True, text=True)
data = loads(get_secret.stdout)['data']

for k, v in data.items():
    with open(k, 'w') as certfile:
        certfile.write(b64decode(v).decode('utf-8'))





### How to use


python3 get-secret.py <namespace> <secret>
python3 get-secret.py nginx-gateway test-local-crt

~~~
