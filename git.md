### Commit
~~~
## Basic
$ git commit -m "test"

## Basic + Add
$ git commit -a -m "test"
~~~

### Branch
~~~
## List branches
$ git branch

## Show commit info
$ git branch -v

## Create branch
$ git branch test

## Switch branch
$ git switch test
$ git checkout test

## Create & Switch branch
$ git switch -c test
$ git checkout -b test

## Delete branch
$ git branch -d test

## Delete branch with force
$ git branch -D test

## Change branch name
$ git branch -m test1234
~~~

### Merge
~~~
## Basic
## In master branch, it will merge test => master
$ git merge test
~~~

### Log
~~~
## Show logs
$ git log

## Show simple logs
$ git log --oneline
~~~

### Diff
~~~
## Compare changes across branches
$ git diff master..test-branch

## Compare changes across commits
$ git log --oneline
$ git diff 234fsd..h5yhghg
~~~
