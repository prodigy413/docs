~~~python
from datetime import datetime
import subprocess
from time import sleep

print(datetime.now().strftime('%Y/%m/%d %H:%M:%S'))

kind_list = [
    "cronjobs",
    "csistoragecapacities",
    # "endpointslices" is created and managed by k8s.
    # "events" is created and managed by k8s.
    "flowschemas",
    "horizontalpodautoscalers",
    "poddisruptionbudgets",
    "podsecuritypolicy",
    "prioritylevelconfigurations",
    "runtimeclasses"
]

for kind in kind_list:
    data = subprocess.run(["kubectl", "get", kind, "-A"], capture_output=True, text=True)
    if data.returncode == 0:
        print(f"\n####################\nKind: {kind}\n####################")
        print(data.stdout)
    else:
        print(data.stderr)
        exit(1)

    sleep(1)
~~~
