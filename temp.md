~~~
from datetime import datetime
import subprocess

def msg(msg: str):
    current_time = datetime.now().strftime('%Y/%m/%d %H:%M:%S')
    print(f'{current_time} {msg.strip()}')

namespace = "default"

all_deploys = subprocess.run(["kubectl", "get", "deployment", "-o", "name", "-n", namespace], capture_output=True, text=True)
if all_deploys.returncode != 0:
    raise Exception(msg('Failed to get deployments or No deployments found.'))
else:
    deploy_list = all_deploys.stdout.strip().split('\n')

all_pods = subprocess.run(["kubectl", "get", "pod", "-o", "name", "-n", namespace], capture_output=True, text=True)
if all_pods.returncode != 0:
    raise Exception(msg('Failed to get pods or No pods found.'))
else:
    pod_list = all_pods.stdout.strip().split('\n')

for deploy in deploy_list:
    scale_result = subprocess.run(["kubectl", "scale", deploy, "--replicas=0", "-n", namespace], capture_output=True, text=True)
    if scale_result.returncode != 0:
        msg(scale_result.stderr)
    else:
        msg(scale_result.stdout)
    pods = [x for x in pod_list if deploy.split('/')[1] in x]
    for pod in pods:
        delete_result = subprocess.run(["kubectl", "wait", pod, "--for=delete", "--timeout", "1200s", "-n", namespace], capture_output=True, text=True)
        if delete_result.returncode != 0:
            msg(delete_result.stderr)

# Check
check_deploy = subprocess.run(["kubectl", "get", "deployment", "-n", namespace], capture_output=True, text=True)
msg(f'\nCheck Deployments of {namespace}\n')
print(check_deploy.stdout.strip(), check_deploy.stderr.strip())

check_pod = subprocess.run(["kubectl", "get", "pod", "-n", namespace], capture_output=True, text=True)
msg(f'\nCheck Pods of {namespace}\n')
print(check_pod.stdout.strip(), check_pod.stderr.strip())

~~~
