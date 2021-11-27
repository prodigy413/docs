### MariaDB client Install
- It will install mysql and mysqldump commands<br>
https://mariadb.com/products/skysql/docs/clients/mariadb-clients/mariadb-client/

~~~
sudo apt install mariadb-client
~~~

### Mysql client install

~~~
sudo apt install mysql-client
~~~

~~~
mysql -h xxxxxxxxxxx.ap-northeast-1.rds.amazonaws.com -P 3306 -u admin -p
mysqldump -h xxxxxxx.ap-northeast-1.rds.amazonaws.com -u admin -p --port=3306 --single-transaction --routines --triggers --events xxx > test.sql
mysql -h xxxxxxxxxxx.ap-northeast-1.rds.amazonaws.com -P 3306 -u admin -p DBNAME < test.sql

## Schema only
mysqldump --no-data DBNAME > test.sql
~~~

### Access from docker
https://hub.docker.com/_/mysql

~~~
docker run -it --rm mysql mysql -h endpoint -u admin -P 3306 -p
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

show columns from test;

INSERT INTO test values(1);

SELECT * FROM test;

SELECT a FROM test WHERE a IS NULL;

UPDATE test SET a=11;

DELETE FROM test WHERE a=11;

DROP TABLE test;

## read only user
GRANT SELECT ON *.* TO 'test';
FLUSH PRIVILEGES;



### Get schema
mysqldump -h <RDSのエンドポイント> -u <ユーザ名> -p<パスワード> --single-transaction --no-data <DB名> > ddl.sql

### Apply schema
mysql -h <RDSのエンドポイント> -u <ユーザ名> -p<パスワード> <DB名> < ddl.sql
~~~

### mysqldump summary
https://qiita.com/PlanetMeron/items/3a41e14607a65bc9b60c

### user query history
 - When mariaDB, you need to set "general_log" = "1"<br>
https://aws.amazon.com/jp/blogs/news/monitor-amazon-rds-for-mysql-and-mariadb-logs-with-amazon-cloudwatch/<br>
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_LogAccess.Concepts.MariaDB.html

~~~
USE mysql;
SELECT event_time,user_host,command_type,argument FROM general_log WHERE user_host REGEXP '^admin' AND command_type='Query';
~~~

### REGEXP
https://www.dbonline.jp/mysql/select/index8.html<br>
https://dev.mysql.com/doc/refman/8.0/en/regexp.html<br>
