### stress-ng
- Install

~~~
$ yum -y install stress-ng
$ sudo apt-get install -y stress-ng
$ stress-ng -V
~~~

- Sample Commands

~~~
### Use CPU 100%
$ stress-ng -c 1

### Use CPU 50%
$ stress-ng -c 1 -l 50

### Use Memory 1G for 10s, 1 process
$ stress-ng -m 1 --vm-bytes 1G --timeout 10

### Use Disk 2G
$ stress-ng -d 1 --hdd-bytes 2G
~~~
