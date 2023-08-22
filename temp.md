~~~
control_pods.py

import sys
# Add path
sys.path.append(r'../../utils')

from csv import reader
from multiprocessing import Pool
import argparse
from subprocess import run
import utils

# Check arguments
parser = argparse.ArgumentParser()
parser.add_argument('-m', '--mode', required=True, help='Start or stop deployment.', choices=['start', 'stop'])
args = parser.parse_args()
print(utils.msg('Argument check OK.'))

# Check commands
commands = ['kubectl']
utils.check_command(commands)

# Check files
files = ['lists.csv']
utils.check_files(files)

# Read deployment list
with open(files[0]) as f:
    data_list = [data for data in reader(f)]

# Check namespace / deployment
all_ns = {dt[0] for dt in data_list}
all_deploy = dict()
for ns in all_ns:
    all_deploy[ns] = utils.get_all_deploy(ns)
for dt in data_list:
    if dt[1] not in all_deploy[dt[0]]:
        raise Exception(f'Deployment {dt[1]} is not found in namespace {dt[0]}.')

# Function: Scale out pods / Start pods
def scale_out(target_list: list) -> None:
    pods = utils.get_all_pod(target_list[0], target_list[1])
    scale_result = run(["kubectl", "scale", "deploy", target_list[1], "--replicas", target_list[2], "-n", target_list[0]], capture_output=True, text=True)
    if scale_result.returncode == 0:
        print(utils.msg(f'Start {target_list[1]} started.'))
    else:
        print(utils.msg(scale_result.stderr))
    start_result = run(["kubectl", "wait", "deploy", target_list[1], "--for", "condition=Available=True", "--timeout", "3600s", "-n", target_list[0]], capture_output=True, text=True)
    if start_result.returncode == 0:
        result = utils.msg(f'Start {target_list[1]} completed.')
    else:
        result = utils.msg(start_result.stderr)
    print(result)

# Function: Scale in pods / Stop pods
def scale_in(target_list: list) -> None:
    pods = utils.get_all_pod(target_list[0], target_list[1])
    scale_result = run(["kubectl", "scale", "deploy", target_list[1], "--replicas", "0", "-n", target_list[0]], capture_output=True, text=True)
    if scale_result.returncode == 0:
        print(utils.msg(f'Stop {target_list[1]} started.'))
    else:
        print(utils.msg(scale_result.stderr))
    if len(pods) == 0:
        result = utils.msg(f'No pods found of {target_list[1]}. Task completed.')
    else:
        for pod in pods:
            delete_result = run(["kubectl", "wait", "pod", pod, "--for=delete", "--timeout", "3600s", "-n", target_list[0]], capture_output=True, text=True)
            if delete_result.returncode == 0:
                result = utils.msg(f'Stop {target_list[1]} completed.')
            else:
                result = utils.msg(delete_result.stderr)
    print(result)

# Run
if args.mode == 'start':
    if __name__ == '__main__':
        with Pool(5) as p:
            p.map(scale_out, data_list)
elif args.mode == 'stop':
    if __name__ == '__main__':
        with Pool(5) as p:
            p.map(scale_in, data_list)





utils.py

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






$ ls -l | awk -v OFS='\t' '{print $1,$2,$3}'

$ ls -l | awk -v OFS=',' -v ORS=';' '{print $1,$2,$3}'

$ ls -l | awk 'NR>1 {print $0}'

$ ls -l | awk 'NR>1 && NR<=2 {print $0}'

$ ls -l | awk 'BEGIN {print "permission", "what", "what2"} NR>1 {print $1,$2,$3}'
~~~
