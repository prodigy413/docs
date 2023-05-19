~~~
import os
import yaml

csv_content = 'Deployment,Label,Container01,Image,Req_cpu,Req_memory,Lim_cpu,Lim_memory,Container02,Image,Req_cpu,Req_memory,Lim_cpu,Lim_memory,Service,Label,Configmap01,Label,Configmap02,Label,Configmap03,Label,Configmap04,Label,Secret,Label\n'

def find_indices(target_list, keyword):
    indices = []
    for idx, value in enumerate(target_list):
        if value == keyword:
            indices.append(idx)
    return indices

os.chdir('/home/obi/test/develop-code/python/kubernets/yaml_to_json')
with open('list.txt', 'r') as lf:
    yaml_file = lf.read().strip().split('\n')

os.chdir('/home/obi/test/develop-code/python/kubernets/yaml_to_json')
for file in yaml_file:
    with open(file, 'r') as yf:
        content = yf.readlines()
        # Deployment or Job
        if 'kind: Deployment\n' in content:
            deploy_index = find_indices(content, 'kind: Deployment\n')
        elif 'kind: Job\n' in content:
            deploy_index = find_indices(content, 'kind: Job\n')
        for idx in range(len(deploy_index)):
            for x in range(deploy_index[idx], 0, -1):
                if content[x] == '---\n':
                    start_line = x + 1
                    break
                else:
                    start_line = 0
            for x in range(deploy_index[idx], len(content)):
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

            csv_content += f"{yaml_content['metadata']['name']},"
            try:
                csv_content += f"{'/'.join(list(yaml_content['metadata']['labels'].values()))},"
            except KeyError:
                csv_content += '-,'
            csv_content += f"{dict_container[0]['name']},"
            csv_content += f"{dict_container[0]['image']},"
            try:
                csv_content += f"{dict_container[0]['resources']['requests']['cpu']},"
                csv_content += f"{dict_container[0]['resources']['requests']['memory']},"
                csv_content += f"{dict_container[0]['resources']['limits']['cpu']},"
                csv_content += f"{dict_container[0]['resources']['limits']['memory']},"
            except KeyError:
                csv_content += '-,-,-,-,'
            try:
                csv_content += f"{dict_container[1]['name']},"
                csv_content += f"{dict_container[1]['image']},"
            except (KeyError, IndexError):
                csv_content += '-,-,'
            try:
                csv_content += f"{dict_container[1]['resources']['requests']['cpu']},"
                csv_content += f"{dict_container[1]['resources']['requests']['memory']},"
                csv_content += f"{dict_container[1]['resources']['limits']['cpu']},"
                csv_content += f"{dict_container[1]['resources']['limits']['memory']},"
            except (KeyError, IndexError):
                csv_content += '-,-,-,-,'

            # Service
            if 'kind: Service\n' in content:
                service_index = find_indices(content, 'kind: Service\n')
                try:
                    for x in range(service_index[idx], 0, -1):
                        if content[x] == '---\n':
                            start_line = x + 1
                            break
                        else:
                            start_line = 0
                    for x in range(service_index[idx], len(content)):
                        if content[x] == '---\n':
                            end_line = x -1
                            break
                        else:
                            end_line = len(content) - 1

                    svc_temp_content = [content[i] for i in range(start_line, end_line)]

                    with open('svc_temp.yaml', 'w') as yf:
                        yf.writelines(svc_temp_content)

                    with open('svc_temp.yaml', 'r') as yf:
                        svc_yaml_content = yaml.safe_load(yf)

                    csv_content += f"{svc_yaml_content['metadata']['name']},"
                    try:
                        csv_content += f"{'/'.join(list(svc_yaml_content['metadata']['labels'].values()))},"
                    except KeyError:
                        csv_content += '-,'
                except IndexError:
                    csv_content += '-,-,'
            else:
                csv_content += '-,-,'

            # ConfigMap
            if 'kind: ConfigMap\n' in content:
                configmap_index = find_indices(content, 'kind: ConfigMap\n')
                for idx in range(4):
                    try:
                        for x in range(configmap_index[idx], 0, -1):
                            if content[x] == '---\n':
                                start_line = x + 1
                                break
                            else:
                                start_line = 0
                        for x in range(configmap_index[idx], len(content)):
                            if content[x] == '---\n':
                                end_line = x -1
                                break
                            else:
                                end_line = len(content) - 1

                        cm_temp_content = [content[i] for i in range(start_line, end_line)]

                        with open('cm_temp.yaml', 'w') as yf:
                            yf.writelines(cm_temp_content)

                        with open('cm_temp.yaml', 'r') as yf:
                            cm_yaml_content = yaml.safe_load(yf)

                        csv_content += f"{cm_yaml_content['metadata']['name']},"
                        try:
                            csv_content += f"{'/'.join(list(cm_yaml_content['metadata']['labels'].values()))},"
                        except KeyError:
                            csv_content += '-,'
                    except IndexError:
                        csv_content += '-,-,'
            else:
                csv_content += '-,-,'

            # Secret
            if 'kind: Secret\n' in content:
                secret_index = find_indices(content, 'kind: Secret\n')
                for idx in range(2):
                    try:
                        for x in range(secret_index[idx], 0, -1):
                            if content[x] == '---\n':
                                start_line = x + 1
                                break
                            else:
                                start_line = 0
                        for x in range(secret_index[idx], len(content)):
                            if content[x] == '---\n':
                                end_line = x -1
                                break
                            else:
                                end_line = len(content) - 1

                        secret_temp_content = [content[i] for i in range(start_line, end_line)]

                        with open('secret_temp.yaml', 'w') as yf:
                            yf.writelines(secret_temp_content)

                        with open('secret_temp.yaml', 'r') as yf:
                            secret_yaml_content = yaml.safe_load(yf)

                        csv_content += f"{secret_yaml_content['metadata']['name']},"
                        try:
                            csv_content += f"{'/'.join(list(secret_yaml_content['metadata']['labels'].values()))},"
                        except KeyError:
                            csv_content += '-,'
                    except IndexError:
                        csv_content += '-,-,'
            else:
                csv_content += '-,-,'
            csv_content = f"{csv_content[:-1]}\n"

with open('result.csv', 'w') as csvfile:
    csvfile.write(csv_content)

os.remove('./temp.yaml')
os.remove('./svc_temp.yaml')
os.remove('./cm_temp.yaml')
os.remove('./secret_temp.yaml')
#os.remove('./pod.json')

~~~
