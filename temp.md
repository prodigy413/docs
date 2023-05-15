~~~
import os
import yaml

def find_indices(target_list, keyword):
    indices = []
    for idx, value in enumerate(target_list):
        if value == keyword:
            indices.append(idx)
    return indices

with open('list.txt', 'r') as lf:
    yaml_file = lf.read().split('\n')

for file in yaml_file:
    with open(file, 'r') as yf:
        content = yf.readlines()
        if 'kind: Deployment\n' in content:
            deploy_index = find_indices(content, 'kind: Deployment\n')
        elif 'kind: Job\n' in content:
            deploy_index = find_indices(content, 'kind: Job\n')
        for idx in deploy_index:
            for x in range(idx, 0, -1):
                if content[x] == '---\n':
                    start_line = x + 1
                    break
                else:
                    start_line = 0
            for x in range(idx, len(content)):
                if content[x] == '---\n':
                    end_line = x -1
                    break
                else:
                    end_line = len(content) - 1

            temp_content = [content[i] for i in range(start_line, end_line)]

            with open('temp.yaml', 'w') as yf:
                yf.writelines(temp_content)

            with open('temp.yaml', 'r') as yf:
                yaml_content = yaml.safe_load(yf)

            dict_container = yaml_content['spec']['template']['spec']['containers']

            print(yaml_content['metadata']['name'], end=',')
            try:
                print('/'.join(list(yaml_content['metadata']['labels'].values())), end=',')
            except KeyError:
                print('-', end=',')
            print(dict_container[0]['name'], end=',')
            print(dict_container[0]['image'], end=',')
            try:
                print(dict_container[0]['resources']['requests']['cpu'], end=',')
                print(dict_container[0]['resources']['requests']['memory'], end=',')
                print(dict_container[0]['resources']['limits']['cpu'], end=',')
                print(dict_container[0]['resources']['limits']['memory'])
            except KeyError:
                print('-,-,-,-')

os.remove('./temp.yaml')
#os.remove('./pod.json')

~~~
