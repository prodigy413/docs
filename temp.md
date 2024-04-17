~~~
variables.py

from os import environ

# File path
cacert = '/chance_k8s/secrets/ca.crt'
flagfile = '/mount/healthcheck_ok.txt'
listfile = '/config/ms-list.yaml'
tokenfile = '/chance_k8s/secrets/token'

# API SERVER
apiserver = 'kubernetes.default.svc'

# ENV
try:
    namespace = environ['NAMESPACE']
except Exception:
    pass





controller.py

#!/usr/bin/env python3

from sys import argv
from pathlib import Path


def check_path(pathlist: list) -> None:
    for x in pathlist:
        target_path = Path(x)
        if not target_path.exists():
            print(f'{target_path} : File not found.')
            exit(1)


def copy_and_update(src: str, dst: str, msg: str) -> None:
    src_path = Path(src)
    dst_path = Path(dst)

    check_path([src_path])
    if not dst_path.exists():
        src_path.rename(dst_path)
    with open(src_path, 'w') as f:
        f.write(msg)


def remove_and_rename(src: str, dst: str) -> None:
    src_path = Path(src)
    dst_path = Path(dst)

    check_path([src_path, dst_path])
    src_path.unlink()
    dst_path.rename(src_path)


src_file = '/config/ms-list.yaml'
dst_file = '/config/ms-list_bk.yaml'
msg_fail = 'deployments:\n- PodCheckFail'
msg_success = '# success'

if len(argv) != 2:
    print('Available args are [-h, open, close, default]')
    exit(1)

if argv[1] == '-h':
    print('''How to use controller command:
- controller -h: help command
- controller open: Forcibly open healthcheck
- controller close: Forcibly close healthcheck
- controller default: Restore ms list''')
elif argv[1] == 'open':
    copy_and_update(src_file, dst_file, msg_success)
elif argv[1] == 'open':
    copy_and_update(src_file, dst_file, msg_fail)
elif argv[1] == 'open':
    remove_and_rename(src_file, dst_file)
else:
    print('Available args are [-h, open, close, default]')





resource-checker.py

from custom_logging import set_logging
from os import remove
from requests import get
from yaml import safe_load
import variables as var

logger = set_logging(__name__)


def get_data(kind: list) -> dict:
    # Get resource data
    with open(var.tokenfile, 'r') as f:
        token = f.readline()

    url = f'https://{var.apiserver}:443/apis/apps/v1/namespaces/{var.namespace}/{kind}'
    headers = {'Authorization': 'Bearer ' + token}

    try:
        data = get(url, headers=headers, verify=var.cacert)
        if data.status_code != 200:
            exit(1)
    except Exception:
        logger.error('Failed to get resource data')
        exit(1)

    return data.json()


def check_pod_status(listdata: dict) -> bool:
    # Set flag
    flag = True

    for kind in listdata.keys():
        data = get_data(kind)
        items = data['items']

        ms_status_data = dict()
        for x in items:
            try:
                ms_status_data[x['metadata']['name']] = x['status']['availableReplicas']
            except KeyError:
                ms_status_data[x['metadata']['name']] = 0

        # Check pod status
        for ms in listdata[kind]:
            try:
                if ms_status_data[ms] == 0:
                    flag = False
                    logger.info(f'{ms}: No pods available.')
                    break
            except KeyError:
                flag = False
                logger.info(f'{ms}: No {kind} found.')
                break
        if not flag:
            break

    return flag


# Get ms list data
with open(var.listfile, 'r') as f:
    yaml_data = safe_load(f)

# Check pod status if list data is not empty
if yaml_data is not None:
    flag = check_pod_status(yaml_data)
else:
    flag = True

# Control flag file
if flag:
    try:
        with open(var.flagfile, 'w'):
            logger.info('flagfile created')
    except Exception:
        logger.error('Failed to create flagfile')
else:
    try:
        remove(var.flagfile)
        logger.info('flagfile removed')
    except FileNotFoundError:
        logger.info('flagfile removed')
    except Exception:
        logger.error('Failed to remove flagfile')






validator.py

from custom_logging import set_logging
from os import path
from typing import List
from pydantic import BaseModel, ConfigDict, field_validator
import variables as var
from yaml import safe_load


# Definition for checking yaml
class YamlCheck(BaseModel):
    model_config = ConfigDict(extra='forbid')

    deployments: List[str] = []
    statefulsets: List[str] = []

    @field_validator('deployments', 'statefulsets')
    @classmethod
    def no_spaces(cls, v: list) -> str:
        for x in v:
            if ' ' in x:
                logger.error('Yaml check failed. Check yaml file again.')
                exit(1)


logger = set_logging(__name__)

# Check file path
filepath = [var.cacert, var.listfile, var.tokenfile]
for f in filepath:
    if not path.exists(f):
        logger.error(f'Failed to find path : {f}')
        exit(1)

# Check ENV
try:
    var.namespace
except Exception:
    logger.error('ENV check failed.')
    exit(1)

# Check yaml
try:
    with open(var.listfile, 'r') as f:
        yaml_data = safe_load(f)
    if yaml_data is not None:
        YamlCheck(**yaml_data)
    logger.info('Validation check OK.')
except Exception:
    logger.error('Yaml check failed. Check yaml file again.')
    exit(1)







responder.py


from custom_logging import set_logging
from pathlib import Path
from flask import Flask
from variables import flagfile

# Path Configuration
set_logging('werkzeug', 'warn')
logger = set_logging(__name__)

# Healthcheck Configuration
app = Flask(__name__)


@app.route('/healthcheck')
def healthcheck():
    flag_path = Path(flagfile)
    if flag_path.exists():
        logger.info('Return HealthcheckOK 200')
        return 'HealthcheckOK', 200, {'Content-Type': 'text/plain; charset=utf-8'}
    else:
        logger.info('Return Internal Server Error 500')
        return 'Internal Server Error', 500, {'Content-Type': 'text/plain; charset=utf-8'}


# Container healthcheck
@app.route('/healthz')
def container_check():
    return 'Container healthcheck OK', 200


# 404 Exception
@app.errorhandler(404)
def not_found(e):
    logger.error('Return HealthcheckNG 404')
    return 'HealthCheckNG', 404


# All exceptions
@app.errorhandler(Exception)
def undefined_exception(e):
    logger.error('This is unexpected error.')
    return e


~~~
