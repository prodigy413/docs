~~~
import csv
from subprocess import run
import yaml

with open('list.csv') as f:
    reader = csv.reader(f)
    secret_list = [row for row in reader]

for data in secret_list:
    secret = run(["kubectl", "create", "secret", "generic", "test", f"--from-literal={data[0]}={data[1]}", "--dry-run=client", "-oyaml"], capture_output=True, text=True)
    secret_yaml = yaml.safe_load(secret.stdout)
    for k, v in secret_yaml['data'].items():
        print(f"{k}: {v}")

~~~
