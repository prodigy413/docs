### Commands reference
- Link: https://hydrocul.github.io/wiki/commands/date.html

### zip

~~~
$ zip -r ubuntu_all_code_20210724.zip test
$ unzip ubuntu_all_code_20210724.zip
~~~

### Permission
- Link: https://blog.fenrir-inc.com/jp/2012/02/file_permission.html

### nkf
- Install

~~~
$ sudo apt update
$ sudo apt install nkf
$ nkf -v
Network Kanji Filter Version 2.1.5 (2018-12-15)
Copyright (C) 1987, FUJITSU LTD. (I.Ichikawa).
Copyright (C) 1996-2018, The nkf Project.
~~~

- sample commands

~~~
### Check file format
$ nkf --guess test.py

### Change file format(UTF-8/LF)
$ nkf -wd --overwrite test.py
~~~

### GPG

~~~
### Encrypt key.pem and set passphrase
$ gpg --symmetric --cipher-algo AES256 key.pem
$ ls -l 
key.pem
key.pem.gpg

### Decrypt
$ gpg --quiet --batch --yes --decrypt --passphrase="xxxx" --output $HOME/secrets/key.pem key.pem.gpg
~~~

### SSH
- Link:<br>
https://fixyacloud.wordpress.com/2020/01/26/can-i-automatically-add-a-new-host-to-known_hosts/

~~~
### Add host to known_hosts, login and exit 
$ ssh -i key.pem -o StrictHostKeyChecking=no root@192.168.123.123 exit
~~~

- Install

~~~
$ sudo apt install openssh-server
$ sudo systemctl enable ssh --now
$ sudo systemctl status ssh
$ sudo ufw allow ssh

## Client
$ sudo apt-get install openssh-client
~~~

### Shell
- Run command in string

~~~
$ echo "Start `date` End"
Start 2021年  7月 31日 土曜日 18:56:46 JST End
~~~

### Permission
- Link: https://crontab.guru

### Symbolic link
~~~
$ ln -s [directory or file] linkname
$ unlink linkname
~~~

### Record logs
~~~
$ script -a logs.txt

### Stop logging
$ exit
~~~

### Show pkgs
~~~
$ sudo apt list --installed
$ sudo dpkg-query -l
~~~

### zip
~~~
## ZIP is not deterministic.
## Hash is changed, Everytime it is created.
## When zip creates zip file, it includes permission, os, zip file creation time info.
## -X option removes external info, bu file creatin time.
$ zip -X test.zip test.txt

$ zip -r test.zip *
~~~

### npm
~~~
$ sudo apt install npm
$ npm --version
6.14.4
~~~

### Create random password
~~~
$ openssl rand -base64 8
~~~

### curl
~~~
$ curl -user USER_ID:PASSWORD http://www.example.com/
~~~

### Grep
~~~
## Search sub directories recursively using grep
grep -r 'word-to-search' *
grep -R 'word-to-search' *
grep -r '192.168.1.254' /etc/
~~~

### stress-ng
- Link: https://qiita.com/hana_shin/items/0a3a615274717c89c0a4<br>

~~~
sudo apt install stress-ng
stress-ng -V

## CPU100%
## -c is process count
stress-ng -c 1

## CPU50%
stress-ng -c 1 -l 50

## memory
## -m is process count
stress-ng -m 1 --vm-bytes 1G --timeout 10

## Disk
stress-ng -d 1 --hdd-bytes 2G
~~~

~~~
## write speed
## 10G file(1MiB*10000)
time dd if=/dev/zero of=zero.txt bs=1MiB count=10000; time sync
# 1G file(1MiB*1000)
time dd if=/dev/zero of=zero.txt bs=1MiB count=1000; time sync
# 1M file(1MiB*1)
time dd if=/dev/zero of=zero.txt bs=1MiB count=1; time sync
# 4k file(4KiB *1)
time dd if=/dev/zero of=zero.txt bs=4KiB count=1; time sync

## read speed
time dd if=zero.txt of=/dev/null
~~~

~~~bash
### -a and -o are not recommended
if { [ "$1" = "a" ] && [ "$2" != "b" ] } || { [ "$1" = "c" ] || [ "$1" = "d" ] }; then
  echo "test"
fi
~~~

### Ubuntu ssh

~~~
sudo apt install openssh-server
~~~

### bash dictionary
https://www.xmodulo.com/key-value-dictionary-bash.html<br>
https://qiita.com/sayama0402/items/6385b9019f37031eb2b9

### Commands reference
https://hydrocul.github.io/wiki/commands/date.html

