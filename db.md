~~~
sudo apt install mysql-client
~~~

~~~
mysql -h xxxxxxxxxxx.ap-northeast-1.rds.amazonaws.com -P 3306 -u admin -p
mysqldump -h xxxxxxx.ap-northeast-1.rds.amazonaws.com -u admin -p --port=3306 --single-transaction --routines --triggers --databases xxx > test.sql
~~~

### Access from docker
https://hub.docker.com/_/mysql

~~~
docker run -it --rm mysql mysql:latest -hsome.mysql.host -uadmin -p
~~~

### mysqldump summary
https://qiita.com/PlanetMeron/items/3a41e14607a65bc9b60c
