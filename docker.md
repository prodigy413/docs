# Docker

### Documentation
https://docs.docker.com/

### Install
- Link:<br>https://docs.docker.com/engine/install/ubuntu/

~~~
$ sudo apt-get update
$ sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
$ echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
$ sudo apt-get update
$ sudo apt-get install docker-ce docker-ce-cli containerd.io
$ sudo docker -v
Docker version 20.10.7, build f0df350
~~~

### Set user/group

~~~
$ sudo groupadd docker
$ sudo usermod -aG docker $USER

$ groups obi
obi : obi adm cdrom sudo dip plugdev lpadmin lxd sambashare docker

$ getent group docker
docker:x:998:obi

### Reboot system
~~~

### Command summary

~~~
$ sudo docker build -t test:1.0 .
$ sudo docker pull test:1.0
$ sudo docker run --name test -d test:1.0 -v /host/test:/container/test
$ sudo docker run --name test -d test:1.0 -v /host/test:/container/test:ro
$ sudo docker exec -it test sh
$ sudo docker stop test
$ sudo docker rm test
$ sudo docker rmi test
~~~
