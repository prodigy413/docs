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

## Go to branch on last
$ git switch -
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

### Stash
~~~
## Scenario
## - You're working in current branch.
## - And you need to switch other branch.
## - But you can't. because you added some changes in current branch.
## Stash can save current status and undo temporarily.
$ git stash

## load current status
$ git stash pop

## Apply working status in other branch
## original status still remains until running pop command.
$ git stash apply

## multiple stash and list stash you saved
$ git stash list

## Call stash you saved
$ git stash apply stash@{2}

## Remove specific stash
$ git stash drop stash@{2}

## Remove all stash
$ git stash clear
~~~

### Update next time
~~~
## Go to specific commit
$ git checkout 34gfsdsdf

$ git checkout HEAD~1

## Discard changes
$ git checkout HEAD test.txt
$ git checkout -- test.txt
$ git restore test.txt

## Restore specific file / specific commit
$ git restore --source HEAD~1 test.txt

## Cancel add
$ git restore --staged test.txt

## Reset commit
## Reset removes commit
$ git reset 325gsfsd

## Revert commit
## Revert creates new commit
$ git revert 325gsfsd
~~~

### Github
~~~
## Add repo
$ git remote add <remote name(you can set whatever you want)> https://zzzzzzzzz
ex) $ git remote add origin https://zzzzzzzzz

## check
$ git remote -v

## Rename
$ git remote rename <old> <new>

## Remove
$ git remote remove <name>
~~~

~~~
## push
$ git push origin master
$ git push origin test-branch
$ git push origin pasta:spagheti

## push -u option
## Once you run [git push -u origin test],
## You can use [git push] => means [git push origin test]
~~~

### Gtihub workflow
1. Create a new empty repo on Github
2. Clone the Github repo to your local machine

### Main <=> Master
1. In your repo, click [Settings]
2. Click [Branches], change default branch

### Remote Tracking Branches
~~~
$ git branch -r
## If you commit several times locally,
                   main
commit1 - commit2 -commit3
origin/main

## This command back to origin/main
$ git checkout origin/main

## This command back to main
$ git switch -
$ git switch main
~~~

### Work with several branched locally
~~~
## After clone
$ git branch -r
$ git checkout --track origin/branch-name
or
$ git switch branch-name
~~~

### Fetch
~~~
## You're working in local
## Remote branch updated
## download updated info
## but not integrated
$ git fetch origin
$ git checkout origin/xxxx

~~~

### Pull
~~~
## Actually update
## git pull origin branch
~~~
