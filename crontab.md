# crontab

~~~text
## Create
$ crontab -e
*/1 * * * * touch test.txt

## List
$ crontab -l

## Remove
$ crontab -ri

## Logs
$ cat /var/log/syslog | grep -i cron

$ cat /var/spool/cron/crontabs/<USERNAME>
~~~
