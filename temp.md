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


- If target_ns ss empty, taget is all namespaces.
- If target_image is empty, taget is all images.

~~~
