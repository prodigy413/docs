### Dataset sample
https://grouplens.org/datasets/movielens/

### Create curl for es

~~~shell
#!/bin/bash
/usr/bin/curl -H "Content-Type: application/json" "$@"
~~~

### Commands samples

~~~
PASSWORD=$(kubectl -n elastic-system get secret obi-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
curl -u "elastic:$PASSWORD" -k "https://es.test.local"
~~~

- Create mapping
~~~
curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XPUT -d @mapping.json -k "https://es.test.local/movies"

curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XGET -k "https://es.test.local/movies/_mapping"

curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XPUT -d @mapping2.json -k "https://es.test.local/movies"
~~~

- Add data
~~~
curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XPOST -d @movies.json -k "https://es.test.local/movies/_doc/109487"

curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XGET -k "https://es.test.local/movies/_search?pretty"
~~~

### Download bulk json file

~~~
wget http://media.sundog-soft.com/es7/movies.json
~~~

- Add a lot of data

~~~
curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XPUT  -k "https://es.test.local/_bulk?pretty" --data-binary @movies_bulk.json

curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XPUT  -k "https://es.test.local/_bulk?pretty" --data-binary @series.json

curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XGET -k "https://es.test.local/movies/_search?pretty"
~~~

### Update

~~~
curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XPUT  -k "https://es.test.local/movies/_doc/109487?pretty" -d @movies_update.json

curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XGET -k "https://es.test.local/movies/_doc/109487?pretty"


curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XPOST  -k "https://es.test.local/movies/_doc/109487/_update" -d @movies_update2.json

curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XGET -k "https://es.test.local/movies/_doc/109487?pretty"
~~~

- Solve concurrency problem

~~~
curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XPOST  -k "https://es.test.local/movies/_doc/109487/_update?retry_on_conflict=5" -d @movies_update2.json
~~~

### Delete

~~~
curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XGET -k "https://es.test.local/movies/_search?q=Dark"

curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XDELETE  -k "https://es.test.local/movies/_doc/58559?pretty"
~~~

- Delete index

~~~
curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XDELETE  -k "https://es.test.local/movies"
~~~

### Search

~~~
curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XGET -k "https://es.test.local/movies/_search?pretty" -d @search_word.json

curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XGET -k "https://es.test.local/movies/_search?pretty" -d @search_phrase.json

curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XGET -k "https://es.test.local/movies/_search?pretty" -d @search_keyword.json

curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XGET -k "https://es.test.local/movies/_search?pretty" -d @search_keyword_correct.json

~~~

### Download series json file

~~~
wget http://media.sundog-soft.com/es7/series.json
~~~

### Series

~~~
curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XPUT -k "https://es.test.local/series" -d @mapping_series.json

curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XGET -k "https://es.test.local/series/_search?pretty" -d @series_test.json

~~~

### Get cluster states

~~~
curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XGET -k "https://es.test.local/_cluster/state?pretty=true"
~~~

### Get Index

~~~
curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XGET -k "https://es.test.local/_cat/indices"
~~~

### Get Setting of Index

~~~
curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XGET -k "https://es.test.local/movies?pretty"
~~~

### Set analyser

~~~
curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XPUT -k "https://es.test.local/analyzer_test" -d @stop_sample.json

curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XPOST -k "https://es.test.local/analyzer_test/_analyze?pretty" -d @stop_test.json


### update

curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XGET -k "https://es.test.local/analyzer_test?pretty"

curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XPOST -k "https://es.test.local/analyzer_test/_close"

curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XPUT -k "https://es.test.local/analyzer_test/_settings" -d @stop_sample.json

curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XPOST -k "https://es.test.local/analyzer_test/_open"
~~~

~~~
curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XPUT  -k "https://es.test.local/_bulk?pretty" --data-binary @stop_data.json

curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XGET -k "https://es.test.local/analyzer_test/_search?pretty" -d @stop_search_word.json

curl -H "Content-Type: application/json" -u "elastic:$PASSWORD" -XPOST -k "hhttps://es.test.local/analyzer_test/_doc/5" -d '
~~~


https://tech-blog.rakus.co.jp/entry/20191002/elasticsearch<br>
https://medium.com/hello-elasticsearch/elasticsearch-833a0704e44b<br>
https://qiita.com/shin_hayata/items/41c07923dbf58f13eec4#ja_stop-token-filter<br>
https://www.elastic.co/guide/en/elasticsearch/reference/6.8/_testing_analyzers.html<br>
https://qiita.com/C_HERO/items/094af261db4725b4baa9<br>
https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-stop-analyzer.html<br>
https://qbox.io/blog/elasticsearch-stopwords-filtering-tutorial/<br>
https://qbox.io/blog/how-to-use-elasticsearch-remove-stopwords-from-query/<br>
https://stackoverflow.com/questions/26730349/can-i-specify-regexp-in-stopwords-for-stop-analyzer-in-elasticsearch<br>

### k8s API Reference
https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-api-reference.html
