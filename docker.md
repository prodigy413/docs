### Command summary

~~~
$ sudo docker build -t test:1.0 .
$ sudo docker pull test:1.0
$ sudo docker run --name test -d test:1.0 -v /host/test:/container/test
$ sudo docker exec -it test sh
$ sudo docker stop test
$ sudo docker rm test
$ sudo docker rmi test
~~~
