# Github Guide
### Install git command
- Link: https://git-scm.com/downloads
- Install

~~~
$ sudo add-apt-repository ppa:git-core/ppa
$ sudo apt update
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

### Gtihub Actions
- Link: https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions
- Config

~~~
$ git clone xxxxxxxx
$ touch .github/workflows/test.yaml
~~~
