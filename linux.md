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

- GPG

~~~
### Encrypt key.pem and set passphrase
$ gpg --symmetric --cipher-algo AES256 key.pem
$ ls -l 
key.pem
key.pem.gpg

### Decrypt
$ gpg --quiet --batch --yes --decrypt --passphrase="xxxx" --output $HOME/secrets/key.pem key.pem.gpg
~~~




