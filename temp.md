~~~
for name in name_list:
    if name.startswith('/aws/'):
        modified_name.append(f"{(name.split('/')[2]).upper()}/{name.replace('/', '_')}")
    elif name.startswith('LG-'):
        modified_name.append(f"{name.split('-')[2]}/{name.replace('/', '_')}")
    elif name.startswith('aws-'):
        modified_name.append(f"{(name.split('-')[1]).upper()}/{name.replace('/', '_')}")

for name in modified_name:
    print(name)
~~~
