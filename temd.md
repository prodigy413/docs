~~~
from yaml import safe_load_all

yaml_file = 'vs.yaml'
lb_ip = "1.1.1.1"

csv_header = ['Name', 'Namespace', 'Gateway', 'Hosts', 'Prefix', 'Dest_host', 'Port', 'Timeout']
csv_datalist = list()

def default_value(dict_data: dict) -> str:
    try:
        return eval(dict_data)
    except (KeyError):
        return '-'

def check_list_length(list_data: list) -> None:
    if len(list_data) > 1:
        raise Exception('List has more than 1 value.')

with open(yaml_file, 'r') as yf:
    yaml_content = safe_load_all(yf)
    for data in yaml_content:
        check_list = [
            data['spec']['gateways'],
            data['spec']['hosts'],
            data['spec']['http'],
            data['spec']['http'][0]['match'],
            data['spec']['http'][0]['route']
        ]
        for x in check_list:
            check_list_length(x)

with open(yaml_file, 'r') as yf:
    yaml_content = safe_load_all(yf)
    for data in yaml_content:
        csv_data = dict()
        csv_data['Name'] = default_value("data['metadata']['name']")
        csv_data['Namespace'] = default_value("data['metadata']['namespace']")
        csv_data['Gateway'] = default_value("data['spec']['gateways'][0]")
        csv_data['Hosts'] = default_value("data['spec']['hosts'][0]")
        csv_data['Prefix'] = default_value("data['spec']['http'][0]['match'][0]['uri']['prefix']")
        csv_data['Dest_host'] = default_value("data['spec']['http'][0]['route'][0]['destination']['host']")
        csv_data['Port'] = default_value("data['spec']['http'][0]['route'][0]['destination']['port']['number']")
        csv_data['Timeout'] = default_value("data['spec']['http'][0]['timeout']")
        csv_datalist.append(csv_data)

for x in csv_datalist:
    print(f"curl -k https://{lb_ip}/ -H \'host: {x['Hosts']}\'")










from csv import DictWriter
from pathlib import Path
from yaml import safe_load_all

base_dir = '/home/obi/test/develop-code/python/kubernetes/manage_manifest'
yaml_file = 'vs.yaml'

csv_header = ['Name', 'Namespace', 'Gateway', 'Hosts', 'Prefix', 'Dest_host', 'Port', 'Timeout']
csv_datalist = list()

def default_value(dict_data: dict) -> str:
    try:
        return eval(dict_data)
    except (KeyError):
        return '-'

def check_list_length(list_data: list) -> None:
    if len(list_data) > 1:
        raise Exception('List has more than 1 value.')

with open(yaml_file, 'r') as yf:
    yaml_content = safe_load_all(yf)
    for data in yaml_content:
        check_list = [
            data['spec']['gateways'],
            data['spec']['hosts'],
            data['spec']['http'],
            data['spec']['http'][0]['match'],
            data['spec']['http'][0]['route']
        ]
        for x in check_list:
            check_list_length(x)

with open(yaml_file, 'r') as yf:
    yaml_content = safe_load_all(yf)
    for data in yaml_content:
        csv_data = dict()
        csv_data['Name'] = default_value("data['metadata']['name']")
        csv_data['Namespace'] = default_value("data['metadata']['namespace']")
        csv_data['Gateway'] = default_value("data['spec']['gateways'][0]")
        csv_data['Hosts'] = default_value("data['spec']['hosts'][0]")
        csv_data['Prefix'] = default_value("data['spec']['http'][0]['match'][0]['uri']['prefix']")
        csv_data['Dest_host'] = default_value("data['spec']['http'][0]['route'][0]['destination']['host']")
        csv_data['Port'] = default_value("data['spec']['http'][0]['route'][0]['destination']['port']['number']")
        csv_data['Timeout'] = default_value("data['spec']['http'][0]['timeout']")
        csv_datalist.append(csv_data)

with open('report.csv', 'w') as f:
    w = DictWriter(f, csv_header)
    w.writeheader()
    for x in csv_datalist:
        w.writerow(x)

~~~
