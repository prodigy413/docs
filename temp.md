~~~
import os

basepath = "/home/obi/test/develop-code/python/file/test01"
all_filelist = []
for root, dirs, files in os.walk(basepath):
    for file in files:
        all_filelist.append(os.path.join(root,file))

for x in all_filelist:
    print(x)
    with open(x, 'r') as f:
        data = f.readlines()
        if len(data) > 1:
            last_line = len(data) - 1
            print(last_line)
            if not data[last_line].endswith('\n'):
                data[last_line] = f"{data[last_line]}\n"
    with open(x, 'w') as f:
        f.writelines(data)

~~~
