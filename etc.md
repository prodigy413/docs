### pip
- Create requirements.txt

~~~
$ pip freeze > requirements.txt
~~~

### undefined

~~~
$ if [ -z "$(file test.py | grep -i crlf)" ] ; then echo "empty" ; fi
~~~
