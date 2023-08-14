~~~
from csv import DictWriter
from pathlib import Path
from yaml import safe_load_all

base_dir = '/home/obi/test/develop-code/python/kubernets/manage_manifest'

csv_header = ['Name', 'Kind', 'Label', 'Namespace', 'Deadline',
              'Container', 'Image',
              'Req_cpu', 'Req_mem', 'Lim_cpu', 'Lim_mem',
              'Readi_delay', 'Readi_period', 'Readi_tmout', 'Readi_success', 'Readi_failure',
              'live_delay', 'live_period', 'live_tmout', 'live_success', 'live_failure']
csv_datalist = list()

def default_value(dict_data: dict) -> str:
    try:
        return eval(dict_data)
    except (KeyError):
        return '-'

with open('list.txt', 'r') as mf:
    manifest_list = mf.read().strip().split('\n')

for manifest in manifest_list:
    path = Path(base_dir)
    file_path = path.joinpath(manifest)

    with open(file_path, 'r') as yf:
        yaml_content = safe_load_all(yf)
        for data in yaml_content:
            if 'Deployment' == data['kind'] or 'Job' == data['kind']:
                ctn_list = data['spec']['template']['spec']['containers']
                for ctn in ctn_list:
                    csv_data = dict()
                    csv_data['Name'] = default_value("data['metadata']['name']")
                    csv_data['Kind'] = default_value("data['kind']")
                    csv_data['Label'] = default_value("data['metadata']['labels']")
                    csv_data['Namespace'] = default_value("data['metadata']['namespace']")
                    if 'Deployment' == data['kind']:
                        csv_data['Deadline'] = default_value("data['spec']['template']['spec']['activeDeadlineSeconds']")
                    elif 'Job' == data['kind']:
                        csv_data['Deadline'] = default_value("data['spec']['activeDeadlineSeconds']")
                    csv_data['Container'] = default_value("ctn['name']")
                    csv_data['Image'] = default_value("ctn['image']")
                    csv_data['Req_cpu'] = default_value("ctn['resources']['requests']['cpu']")
                    csv_data['Req_mem'] = default_value("ctn['resources']['requests']['memory']")
                    csv_data['Lim_cpu'] = default_value("ctn['resources']['limits']['cpu']")
                    csv_data['Lim_mem'] = default_value("ctn['resources']['limits']['memory']")
                    csv_data['Readi_delay'] = default_value("ctn['readinessProbe']['initialDelaySeconds']")
                    csv_data['Readi_period'] = default_value("ctn['readinessProbe']['periodSeconds']")
                    csv_data['Readi_tmout'] = default_value("ctn['readinessProbe']['timeoutSeconds']")
                    csv_data['Readi_success'] = default_value("ctn['readinessProbe']['successThreshold']")
                    csv_data['Readi_failure'] = default_value("ctn['readinessProbe']['failureThreshold']")
                    csv_data['live_delay'] = default_value("ctn['livenessProbe']['initialDelaySeconds']")
                    csv_data['live_period'] = default_value("ctn['livenessProbe']['periodSeconds']")
                    csv_data['live_tmout'] = default_value("ctn['livenessProbe']['timeoutSeconds']")
                    csv_data['live_success'] = default_value("ctn['livenessProbe']['successThreshold']")
                    csv_data['live_failure'] = default_value("ctn['livenessProbe']['failureThreshold']")
                    csv_datalist.append(csv_data)

with open('report.csv', 'w') as f:
    w = DictWriter(f, csv_header)
    w.writeheader()
    for x in csv_datalist:
        w.writerow(x)









import sys
sys.path.append(r'../../utils')

from csv import reader
from multiprocessing import Pool
from subprocess import run
import utils

with open('lists.csv') as f:
    data_list = [data for data in reader(f)]

all_ns = {ns[0] for ns in data_list}
all_deploy = dict()
for ns in all_ns:
    all_deploy[ns] = utils.get_all_deploy(ns)

for data in data_list:
    if data[1] not in all_deploy[data[0]]:
        raise Exception(f'Deployment {data[1]} is not found.')

def scale(target_list: list) -> None:
    pods = utils.get_all_pod(target_list[0], target_list[1])
    scale_result = run(["kubectl", "scale", "deploy", target_list[1], "--replicas=0", "-n", target_list[0]], capture_output=True, text=True)
    if scale_result.returncode == 0:
        print(utils.msg(f'Stop {target_list[1]} started.'))
    else:
        print(utils.msg(scale_result.stderr))
    for pod in pods:
        delete_result = run(["kubectl", "wait", "pod", pod, "--for=delete", "--timeout", "1800s", "-n", target_list[0]], capture_output=True, text=True)
        if delete_result.returncode == 0:
            result = utils.msg(f'Stop {target_list[1]} completed.')
        else:
            result = utils.msg(delete_result.stderr)
    print(result)
#
#if __name__ == '__main__':
#    with Pool(10) as p:
#        print(p.map(scale, deploy_list))
#
~~~
