~~~
from pathlib import Path

ms_data = {
    "release-01": [
        {"kind": "Deployment", "details": [
            {"name": "nginx-01-app-de", "replicas": 2},
            {"name": "nginx-01-bat-de", "replicas": 1}
            ]
        },
        {"kind": "StatefulSet", "details": [
            {"name": "nginx-01-app-st", "replicas": 2},
            {"name": "nginx-01-bat-st", "replicas": 1}
            ]
        }
    ],
    "release-02": [
        {"kind": "Deployment", "details": [
            {"name": "nginx-02-app-de", "replicas": 2},
            {"name": "nginx-02-bat-de", "replicas": 1}
            ]
        },
        {"kind": "StatefulSet", "details": [
            {"name": "nginx-02-app-st", "replicas": 2},
            {"name": "nginx-02-bat-st", "replicas": 1}
            ]
        }
    ],
    "release-03": [
        {"kind": "Deployment", "details": [
            {"name": "nginx-03-app-de", "replicas": 2},
            {"name": "nginx-03-bat-de", "replicas": 1}
            ]
        },
        {"kind": "StatefulSet", "details": [
            {"name": "nginx-03-app-st", "replicas": 2},
            {"name": "nginx-03-bat-st", "replicas": 1}
            ]
        }
    ],
    "release-04": [
        {"kind": "Deployment", "details": [
            {"name": "nginx-04-app-de", "replicas": 2},
            {"name": "nginx-04-bat-de", "replicas": 1}
            ]
        },
        {"kind": "StatefulSet", "details": [
            {"name": "nginx-04-app-st", "replicas": 2},
            {"name": "nginx-04-bat-st", "replicas": 1}
            ]
        }
    ]
}

filename = '/home/obi/test/develop-code/python/kubernetes/scale_multiple_resource/ms.yaml'

file = Path(filename)

if file.exists():
    file.unlink()

def create_namespace(mslist):
    for namespace in mslist.keys():
        manifest = f'''---
apiVersion: v1
kind: Namespace
metadata:
  name: {namespace}
'''
        with file.open(mode='a') as f:
            f.write(manifest)


def create_manifest(mslist):
    for namespace, ms_data in mslist.items():
        for ms in ms_data:
            for detail in ms['details']:
                manifest=f'''---
apiVersion: apps/v1
kind: {ms['kind']}
metadata:
  name: {detail['name']}
  namespace: {namespace}
  labels:
    name: {detail['name']}
    app: {ms['kind'].lower()}
    type: ms
spec:
  selector:
    matchLabels:
      name: {detail['name']}
  replicas: {detail['replicas']}
  template:
    metadata:
      labels:
        name: {detail['name']}
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
'''
                with file.open(mode='a') as f:
                    f.write(manifest)

create_namespace(ms_data)
create_manifest(ms_data)
~~~
