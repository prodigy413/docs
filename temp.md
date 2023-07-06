~~~
docker run --name test-nginx -d -p 8080:80 nginx:1.25.1

obi@obi:~$ docker ps
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS          PORTS                                   NAMES
fba9062543c2   nginx:1.25.1   "/docker-entrypoint.…"   16 minutes ago   Up 16 minutes   0.0.0.0:8080->80/tcp, :::8080->80/tcp   test-nginx
obi@obi:~$ docker containers
docker: 'containers' is not a docker command.
See 'docker --help'
obi@obi:~$ docker container ls
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS          PORTS                                   NAMES
fba9062543c2   nginx:1.25.1   "/docker-entrypoint.…"   16 minutes ago   Up 16 minutes   0.0.0.0:8080->80/tcp, :::8080->80/tcp   test-nginx
obi@obi:~$ docker container ls -a
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS          PORTS                                   NAMES
fba9062543c2   nginx:1.25.1   "/docker-entrypoint.…"   16 minutes ago   Up 16 minutes   0.0.0.0:8080->80/tcp, :::8080->80/tcp   test-nginx
obi@obi:~$ docker container ls -a
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS          PORTS                                   NAMES
fba9062543c2   nginx:1.25.1   "/docker-entrypoint.…"   16 minutes ago   Up 16 minutes   0.0.0.0:8080->80/tcp, :::8080->80/tcp   test-nginx

obi@obi:~$ docker container ls -a
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS                     PORTS     NAMES
fba9062543c2   nginx:1.25.1   "/docker-entrypoint.…"   20 minutes ago   Exited (0) 9 seconds ago             test-nginx
obi@obi:~$ docker ps -a
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS                      PORTS     NAMES
fba9062543c2   nginx:1.25.1   "/docker-entrypoint.…"   20 minutes ago   Exited (0) 16 seconds ago             test-nginx

obi@obi:~$ docker stop test-nginx
test-nginx
obi@obi:~$ docker container ls
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
obi@obi:~$ docker container ls -a
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS                     PORTS     NAMES
fba9062543c2   nginx:1.25.1   "/docker-entrypoint.…"   20 minutes ago   Exited (0) 9 seconds ago             test-nginx
obi@obi:~$ docker ps -a
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS                      PORTS     NAMES
fba9062543c2   nginx:1.25.1   "/docker-entrypoint.…"   20 minutes ago   Exited (0) 16 seconds ago             test-nginx
obi@obi:~$ docker start test-nginx
test-nginx

obi@obi:~$ docker rm test-nginx
test-nginx

obi@obi:~$ docker rmi nginx:1.25.1
Untagged: nginx:1.25.1
Untagged: nginx@sha256:08bc36ad52474e528cc1ea3426b5e3f4bad8a130318e3140d6cfe29c8892c7ef
Deleted: sha256:021283c8eb95be02b23db0de7f609d603553c6714785e7a673c6594a624ffbda
Deleted: sha256:a9de33035096cdf7bbaf7f3e1291701c0620d2a0e66152228abef35a79002876
Deleted: sha256:d66c35807d98c6f37bd2a14c6506a42d27a40fbdb564e233f7a78aafdc636c59
Deleted: sha256:a4c423818ed6dc12a545c349d0dc36a5695446448e07229e96c7235a126c2520
Deleted: sha256:c04094edc9df98c870e281f3b947a7782ca6d542d8715814ac06786466af3659
Deleted: sha256:c9c467815e8fe87d99f0f500495cf7f4f9096cf6c116ef2782e84bb17a4a5e06
Deleted: sha256:4645f26713fbea51190f5de52b88fbe27b42efd61c0dba87c81fa16df9a8f649
Deleted: sha256:24839d45ca455f36659219281e0f2304520b92347eb536ad5cc7b4dbb8163588
obi@obi:~$ docker images
REPOSITORY               TAG       IMAGE ID       CREATED       SIZE
prodigy413/test-python   1.0       afb7b8b3218a   10 days ago   148MB


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


$ docker system df
$ docker volume prune => Remove all volumes except for running containers
$ docker volume ls
$ docker system prune => Remove all except for running containers
$ docker system prune --force

## Remove all containers
## -v: Remove all associated volumes
## -f: Forces the removal. Like, if any containers is running, you need -f to remove them.
$ docker rm -vf $(docker ps -a -q)

## Remove all images
## -a: for all containers, even not running, (or images)
## -q: to remove all the details other than the ID of containers (or images)
$ docker rmi -f $(docker images -a -q)
~~~
