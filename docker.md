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

### Where images are stored
`/var/lib/docker`

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
$ docker image ls
$ docker container ls -a
$ docker ps -a
$ docker build -t test:1.0 .
$ docker pull test:1.0

## [-d]: detach, [-P]: random port
$ docker run --name test -d test:1.0 -v /host/test:/container/test
$ docker run --name test -d test:1.0 -v /host/test:/container/test:ro
$ docker run --name test -d -P test:1.0
$ docker exec -it test sh
$ docker stop test
$ docker rm test
$ docker rmi test
$ docker inspect 13fdsf4f
$ docker run -e ENV_TEST=obiwan test env | grep ENV_TEST
$ docker logs efgsd3fg
$ docker run --name nginx -d -p 8080:80 nginx:1.21
$ docker run --name nginx -v /home/obi/test/html:/usr/share/nginx/html:ro -d -p 8080:80 nginx:1.21
$ docker tag xxxxxxxx test/nginx:1.0
$ docker rmi test/nginx:1.0
~~~

### Management

~~~
$ docker system df
$ docker volume prune => Remove all volumes except for running containers
$ docker volume ls
$ docker system prune => Remove all except for running containers
$ docker system prune --force
~~~
