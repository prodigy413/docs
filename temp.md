~~~
access.py

import ssl
import requests
from urllib3.poolmanager import PoolManager
from requests.adapters import HTTPAdapter

class Ssl3HttpAdapter(HTTPAdapter):
    """"Transport adapter" that allows us to use SSLv3."""

    def init_poolmanager(self, connections, maxsize, block=False):
        self.poolmanager = PoolManager(
            num_pools=connections, maxsize=maxsize,
            block=block, ssl_version=ssl.PROTOCOL_TLSv1_1)

url = 'https://nginx.test.local'
s = requests.Session()
s.mount('https://', Ssl3HttpAdapter())
response = s.get(url, verify=False)
print(response)





openssl s_client -connect nginx.test.local:443 -tls1_1 < /dev/null




build_prod_new.py

# List all subdirectories in a directory in Python
# https://www.techiedelight.com/list-all-subdirectories-in-directory-python
# pathlib reference
# https://note.nkmk.me/python-pathlib-mkdir-rmdir/

from datetime import datetime
from os import chdir
from pathlib import Path
from subprocess import run

kust_rootdir = '/home/obi/test/infra-code/yaml/kustomize/dsp/MS'
output_rootdir = '/tmp/build/'
kind = 'bat' # 'online' or 'bat'

start_time = datetime.now()
task_success_count = 0
task_fail_count = 0
path_list = []

kust_file_path = f'{kust_rootdir}/{kind}'
output_file_path = f'{output_rootdir}/{kind}'
if not Path(output_file_path).exists():
    Path(output_file_path).mkdir(parents=True)

def listdirs(dirpath, pathlist):
    for path in Path(dirpath).iterdir():
        if path.is_dir():
            pathlist.append(str(path))
            listdirs(path, pathlist)
    return pathlist

final_path_list = [ x for x in listdirs(kust_file_path, path_list) if 'ns-' in x and 'base' not in x and Path(f'{x}/kustomization.yaml').exists()]
for path in final_path_list:
    path_list = path.split('/')
    i = path_list.index(kind)
    if 'tok02' in path_list or 'tok04' in path_list:
        if not Path(f'{output_file_path}/{path_list[i+4]}').exists():
            Path(f'{output_file_path}/{path_list[i+4]}').mkdir()
        filename = f'{output_file_path}/{path_list[i+4]}/{path_list[i+2]}-{path_list[i+1]}-{path_list[i+5]}.yaml'
        chdir(path)
        kustomize = run(["kustomize", "build", ".", "-o", filename], capture_output=True, text=True)
        if kustomize.returncode == 0:
            print(kustomize.stdout)
            print(f'path: {path}\nfile: {filename}\ntask completed')
            task_success_count += 1
        else:
            print(kustomize.stderr)
            print(f'path: {path}\nfile: {filename}\ntask failed')
            task_fail_count += 1
    else:
        if kind == 'online':
            if not Path(f'{output_file_path}/{path_list[i+4]}').exists():
                Path(f'{output_file_path}/{path_list[i+4]}').mkdir()
            filename = f'{output_file_path}/{path_list[i+4]}/{path_list[i+2]}-{path_list[i+1]}.yaml'
            chdir(path)
            kustomize = run(["kustomize", "build", ".", "-o", filename], capture_output=True, text=True)
            if kustomize.returncode == 0:
                print(kustomize.stdout)
                print(f'path: {path}\nfile: {filename}\ntask completed')
                task_success_count += 1
            else:
                print(kustomize.stderr)
                print(f'path: {path}\nfile: {filename}\ntask failed')
                task_fail_count += 1
        else:
            chdir(path)
            kustomize = run(["kustomize", "build", "."], capture_output=True, text=True)
            if kustomize.returncode == 0:
                if 'kind: Deployment' in kustomize.stdout:
                    if not Path(f'{output_file_path}/{path_list[i+4]}/deployment').exists():
                        Path(f'{output_file_path}/{path_list[i+4]}/deployment').mkdir(parents=True)
                    filename_deploy = f'{output_file_path}/{path_list[i+4]}/deployment/{path_list[i+2]}-{path_list[i+1]}.yaml'
                    kustomize = run(["kustomize", "build", ".", "-o", filename_deploy], capture_output=True, text=True)
                    if kustomize.returncode == 0:
                        print(kustomize.stdout)
                        print(f'path: {path}\nfile: {filename_deploy}\ntask completed')
                        task_success_count += 1
                if 'kind: Job' in kustomize.stdout:
                    if not Path(f'{output_file_path}/{path_list[i+4]}/job').exists():
                        Path(f'{output_file_path}/{path_list[i+4]}/job').mkdir(parents=True)
                    filename_job = f'{output_file_path}/{path_list[i+4]}/job/{path_list[i+2]}-{path_list[i+1]}.yaml'
                    kustomize = run(["kustomize", "build", ".", "-o", filename_job], capture_output=True, text=True)
                    if kustomize.returncode == 0:
                        print(kustomize.stdout)
                        print(f'path: {path}\nfile: {filename_job}\ntask completed')
                        task_success_count += 1
            else:
                print(kustomize.stderr)
                print(f'path: {path}\nfile: {filename_deploy}\ntask failed')
                task_fail_count += 1

print(f'Success: {task_success_count}')
print(f'Failed: {task_fail_count}')
time_elapsed = datetime.now() - start_time
print(f'Time elapsed: {time_elapsed}')

~~~
