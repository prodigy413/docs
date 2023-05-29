~~~
utils.py
from datetime import datetime
from json import loads
from subprocess import run

def msg(msg: str) -> str:
    current_time = datetime.now().strftime('%Y/%m/%d %H:%M:%S')
    return f'{current_time} {msg.strip()}'

def check_command(cmd_list: list) -> None:
    for cmd in cmd_list:
        try:
            run([cmd], capture_output=True, text=True)
        except FileNotFoundError:
            print(f'Command {cmd} is not found.')

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






start_pod.py
import sys
sys.path.append(r'../utils')

from csv import reader
from multiprocessing import Pool
from subprocess import run
import utils

with open('lists.csv') as f:
    deploy_list = [deploy for deploy in reader(f)]

ns = deploy_list[0][0]
all_deploy = utils.get_all_deploy(ns)

for deploy in deploy_list:
    if deploy[1] not in all_deploy:
        raise Exception(f'Deployment {deploy[1]} is not found.')

def scale(deploy):
    scale_result = run(["kubectl", "scale", "deploy", deploy[1], "--replicas=2", "-n", deploy[0]], capture_output=True, text=True)
    if scale_result.returncode == 0:
        print(utils.msg(f'Start {deploy[1]} started.'))
    else:
        print(utils.msg(scale_result.stderr))
    start_result = run(["kubectl", "wait", "deploy", deploy[1], "--for", "condition=Available=True", "--timeout", "1200s", "-n", deploy[0]], capture_output=True, text=True)
    if start_result.returncode == 0:
        result = utils.msg(f'Start {deploy[1]} completed.')
    else:
        result = utils.msg(start_result.stderr)
    print(result)

if __name__ == '__main__':
    with Pool(10) as p:
        print(p.map(scale, deploy_list))










stop_pod.py
import sys
sys.path.append(r'../utils')

from csv import reader
from multiprocessing import Pool
from subprocess import run
import utils

with open('lists.csv') as f:
    deploy_list = [deploy for deploy in reader(f)]

ns = deploy_list[0][0]
all_deploy = utils.get_all_deploy(ns)

for deploy in deploy_list:
    if deploy[1] not in all_deploy:
        raise Exception(f'Deployment {deploy[1]} is not found.')

def scale(deploy):
    pods = utils.get_all_pod(deploy[0], deploy[1])
    scale_result = run(["kubectl", "scale", "deploy", deploy[1], "--replicas=0", "-n", deploy[0]], capture_output=True, text=True)
    if scale_result.returncode == 0:
        print(utils.msg(f'Stop {deploy[1]} started.'))
    else:
        print(utils.msg(scale_result.stderr))
    for pod in pods:
        delete_result = run(["kubectl", "wait", "pod", pod, "--for=delete", "--timeout", "1200s", "-n", deploy[0]], capture_output=True, text=True)
        if delete_result.returncode == 0:
            result = utils.msg(f'Stop {deploy[1]} completed.')
        else:
            result = utils.msg(delete_result.stderr)
    print(result)

if __name__ == '__main__':
    with Pool(10) as p:
        print(p.map(scale, deploy_list))
~~~
