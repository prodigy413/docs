~~~
from json import loads
from subprocess import run

target_ns = ""
target_image = ""
csv_content = 'Namespace,Deployment,Image\n'

all_ns = run(["kubectl", "get", "ns", "-ojson"], capture_output=True, text=True)
ns_list = [ns['metadata']['name'] for ns in loads(all_ns.stdout)['items']]
ns_filtered = ns_list if target_ns == "" else [ns for ns in ns_list if target_ns in ns]

for ns in ns_filtered:
    all_deploy = run(["kubectl", "get", "deploy", "-ojson", "-n", ns], capture_output=True, text=True)
    deploy_list = loads(all_deploy.stdout)['items']
    if target_image == "":
        for deploy in deploy_list:
            csv_content += f"{ns},"
            csv_content += f"{deploy['metadata']['name']},"
            image_list = deploy['spec']['template']['spec']['containers']
            for image in image_list:
                csv_content += f"{image['image']},"
            csv_content = f"{csv_content[:-1]}\n"
    else:
        for deploy in deploy_list:
            image_list = deploy['spec']['template']['spec']['containers']
            for image in image_list:
                if target_image in image['image']:
                    csv_content += f"{ns},"
                    csv_content += f"{deploy['metadata']['name']},"
                    csv_content += f"{image['image']},"
                csv_content = f"{csv_content[:-1]}\n"

with open('result.csv', 'w') as csvfile:
    csvfile.write(csv_content)













import csv
from collections import defaultdict
import json
import yaml

deploy_job_len, ctn_len, ctn_port_len, svc_len, cm_len, secret_len = (0 for i in range(6))
deploy_job_all, ctn_all, svc_all, cm_all, secret_all = ([] for i in range(5))
deploy_job_csv, svc_csv, cm_csv, secret_csv = ([] for i in range(4))
csv_header = ['Name', 'Kind', 'Label']

def default_index(dict_data, index):
    try:
        return dict_data[index]
    except IndexError:
        return '-'

def default_value(dict_data):
    try:
        return eval(dict_data)
    except (KeyError, IndexError):
        return '-'

def final_value(dict_data, index, dict_value):
    if isinstance(default_index(dict_data, index), dict):
        return dict_value
    else:
        default_index(dict_data, index)

with open('list.txt', 'r') as lf:
    file_list = lf.read().strip().split('\n')

for file in file_list:
    deploy_job, svc, cm, secret = ([] for i in range(4))
    with open(file, 'r') as yf:
        yaml_content = yaml.safe_load_all(yf)
        for data in yaml_content:
            if 'Deployment' == data['kind'] or 'Job' == data['kind']:
                deploy_job.append(data)
                ctn_list = data['spec']['template']['spec']['containers']
                ctn_port_list = [x['ports'] for x in ctn_list if 'ports' in x.keys()]
            elif 'Service' == data['kind']:
                svc.append(data)
            elif 'ConfigMap' == data['kind']:
                cm.append(data)
            elif 'Secret' == data['kind']:
                secret.append(data)
        deploy_job_all.append(deploy_job)
        svc_all.append(svc)
        cm_all.append(cm)
        secret_all.append(secret)
        if len(deploy_job) >= deploy_job_len: deploy_job_len = len(deploy_job)
        if len(ctn_list) >= ctn_len: ctn_len = len(ctn_list)
        if len(ctn_port_list) >= ctn_port_len: ctn_port_len = len(ctn_port_list)
        if len(svc) >= svc_len: svc_len = len(svc)
        if len(cm) >= cm_len: cm_len = len(cm)
        if len(secret) >= secret_len: secret_len = len(secret)

for deploy_job_list in deploy_job_all:
    for resource in deploy_job_list:
        deploy_job_dict = defaultdict(lambda: '-')
        deploy_job_dict['Name'] = resource['metadata']['name']
        deploy_job_dict['Kind'] = resource['kind']
        labels = resource['metadata'].get('labels', '-')
        if isinstance(labels, dict):
            labels = ' / '.join([f'{k}: {v}' for k, v in labels.items()])
        deploy_job_dict['Label'] = labels
        ctn_list = resource['spec']['template']['spec']['containers']
        header_count = 1
        for i in range(ctn_len):
            dict_keys01 = [
                f'Container{header_count}0',
                f'Image{header_count}0',
            ]
            dict_keys02 = [f'port{header_count}{j}' for j in range(ctn_port_len)]
            dict_keys03 = [
                f'Req_cpu{header_count}0',
                f'Req_mem{header_count}0',
                f'Lim_cpu{header_count}0',
                f'Lim_mem{header_count}0',
                f'Readi_path{header_count}0',
                f'Readi_port{header_count}0',
                f'Readi_delay{header_count}0',
                f'Readi_period{header_count}0',
                f'Readi_tmout{header_count}0',
                f'Readi_success{header_count}0',
                f'Readi_failure{header_count}0',
                f'live_path{header_count}0',
                f'live_port{header_count}0',
                f'live_delay{header_count}0',
                f'live_period{header_count}0',
                f'live_tmout{header_count}0',
                f'live_success{header_count}0',
                f'live_failure{header_count}0'
            ]
            dict_keys_list = [dict_keys01, dict_keys02, dict_keys03]
            for k in dict_keys_list:
                if k[0] not in csv_header: csv_header += k
            if isinstance(default_index(ctn_list, i), dict):
                dict_values01 = [
                    "ctn_list[i]['name']",
                    "ctn_list[i]['image']"
                ]
                dict_values02 = [f"ctn_list[i]['ports'][{j}]['containerPort']" for j in range(ctn_port_len)]
                dict_values03 = [
                    "ctn_list[i]['resources']['requests']['cpu']",
                    "ctn_list[i]['resources']['requests']['memory']",
                    "ctn_list[i]['resources']['limits']['cpu']",
                    "ctn_list[i]['resources']['limits']['memory']",
                    "ctn_list[i]['readinessProbe']['httpGet']['path']",
                    "ctn_list[i]['readinessProbe']['httpGet']['port']",
                    "ctn_list[i]['readinessProbe']['initialDelaySeconds']",
                    "ctn_list[i]['readinessProbe']['periodSeconds']",
                    "ctn_list[i]['readinessProbe']['timeoutSeconds']",
                    "ctn_list[i]['readinessProbe']['successThreshold']",
                    "ctn_list[i]['readinessProbe']['failureThreshold']",
                    "ctn_list[i]['livenessProbe']['httpGet']['path']",
                    "ctn_list[i]['livenessProbe']['httpGet']['port']",
                    "ctn_list[i]['livenessProbe']['initialDelaySeconds']",
                    "ctn_list[i]['livenessProbe']['periodSeconds']",
                    "ctn_list[i]['livenessProbe']['timeoutSeconds']",
                    "ctn_list[i]['livenessProbe']['successThreshold']",
                    "ctn_list[i]['livenessProbe']['failureThreshold']"
                ]
                dict_values_list = [dict_values01, dict_values02, dict_values03]
                for k, v in zip(dict_keys_list, dict_values_list):
                    for key, value in zip(k, v):
                        deploy_job_dict[key] = default_value(value)
            else:
                for d in dict_keys_list:
                    for k in d:
                        deploy_job_dict[k] = default_index(ctn_list, i)
            header_count += 1
        deploy_job_csv.append(json.loads(json.dumps(deploy_job_dict)))

with open('result.csv', 'w') as f:
    writer = csv.DictWriter(f, csv_header)
    writer.writeheader()
    writer.writerows(deploy_job_csv)

~~~
