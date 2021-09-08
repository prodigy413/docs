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

### MariaDB create user
https://docs.cluvio.com/hc/en-us/articles/115000968069-Creating-a-read-only-user-in-the-database<br>
https://qiita.com/IysKG213/items/4a26bc419eea8f642b44<br>
https://mariadb.com/kb/en/create-database/<br>
https://www.dbonline.jp/mariadb/<br>

~~~
CREATE USER 'readonly' IDENTIFIED BY 'xxxxxxxxxx';

GRANT SELECT ON *.* TO 'readonly'@'%' IDENTIFIED BY 'xxxxxxxxxx';

GRANT SELECT ON *.* TO 'readonly'@'localhost' IDENTIFIED BY 'xxxxxxxxxx';

SELECT user,host FROM mysql.user;

SET PASSWORD FOR 'test' = PASSWORD('xxxxxxxxxx');

DROP USER test;

show databases;

CREATE DATABASE test;

DROP DATABASE test;

USE test;

CREATE TABLE test (a int);

show tables;

INSERT INTO test values(1);

SELECT * FROM test;

UPDATE test SET a=11;

DELETE FROM test WHERE a=11;

## read only user
GRANT SELECT ON *.* TO 'test';
FLUSH PRIVILEGES;
~~~

### mysqldump summary
https://qiita.com/PlanetMeron/items/3a41e14607a65bc9b60c
