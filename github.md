# Github Guide
### Install git command
- Link: https://git-scm.com/downloads
- Install

~~~
$ sudo add-apt-repository ppa:git-core/ppa
$ sudo apt update
$ sudo apt install git
$ git --version
git version 2.32.0

~~~

### Set pre-commit
- Link: https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks
- Config

~~~
$ git clone xxxxxxxx
$ touch .git/hooks/pre-commit
$ chmod 775 .git/hooks/pre-commit
~~~

pre-commit

~~~sh
echo "Test"
~~~

### Github REST API
- Link: https://docs.github.com/en/rest/guides/getting-started-with-the-rest-api
- Samples

~~~
$ curl https://api.github.com/users/prodigy413
{
  "login": "prodigy413",
..........
}

$ curl -i https://api.github.com/users/prodigy413
HTTP/2 200 
..........

$ curl -s https://api.github.com/users/prodigy413/repos | jq '.[].name'
"20210602_test"
"cicd-test"
..........

~~~

### Gtihub Actions
- Link: https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions
- Config

~~~
$ git clone xxxxxxxx
$ touch .github/workflows/test.yaml
~~~
