~~~
sudo apt install mysql-client
~~~

~~~
mysql -h xxxxxxxxxxx.ap-northeast-1.rds.amazonaws.com -P 3306 -u admin -p
mysqldump -h xxxxxxx.ap-northeast-1.rds.amazonaws.com -u admin -p --port=3306 --single-transaction --routines --triggers --databases xxx > test.sql
~~~
