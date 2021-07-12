# jq Guide
### Install jq command
- Link: https://stedolan.github.io/jq/download/
- Install

~~~
$ sudo apt-get install jq
$ jq --version
jq-1.6
~~~

### Samples

~~~
jq '.items[].name'
jq '.[]'
jq -r '.items[] | .name'
jq '[.items[].price] | add'

jq '.items[] | { name: .name, yen: .price }'
{
  "name": "すてきな雑貨",
  "yen": 2500
}
{
  "name": "格好いい置物",
  "yen": 4500
}

jq '.items | map({ name: .name, yen: .price })'
[
  {
    "name": "すてきな雑貨",
    "yen": 2500
  },
  {
    "name": "格好いい置物",
    "yen": 4500
  }
]


~~~

- Reference: https://qiita.com/takeshinoda@github/items/2dec7a72930ec1f658af
