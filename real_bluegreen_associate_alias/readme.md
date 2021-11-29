~~~
aws s3 cp ./html1 s3://great-obi-s3-01 --recursive
aws s3 cp ./html2 s3://great-obi-s3-02 --recursive
aws s3 cp ./html_maintain s3://great-obi-s3-maintain --recursive

aws s3 rm s3://great-obi-s3-01 --recursive
aws s3 rm s3://great-obi-s3-02 --recursive
aws s3 rm s3://great-obi-s3-maintain --recursive
~~~
