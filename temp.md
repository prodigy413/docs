~~~python
from difflib import Differ

with open("test1.txt") as f1, open("test2.txt") as f2:
    file1 = f1.readlines()
    file2 = f2.readlines()
    d = Differ()
    difference = [d.replace('\n', '') for d in d.compare(file1, file2) if d[0] in ('+', '-')]

for d in difference:
    print(d)

~~~
