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

### 11 main git commands
- Link: https://dev.to/domagojvidovic/11-git-commands-i-use-every-day-43eo<br>

~~~
1. Checking out a new branch
Obviously, I must use a new branch for every task I start:
git checkout -b <new_branch_name>
This command creates a new branch and automatically sets it as active.

2. Selecting files for commit
This is one of the rare cases where I prefer GUI. In VS Code (or any other better IDE/text editor), you can easily see the updated files and select the ones you want to include in the commit.

But in case you want to do it with the CLI:
git add .
This command will stage all changed files.

If you want to select a single file:
git add <path/to/file>
3. Making a commit
After you stage some files, you need to commit them:
git commit -m "Some changes"
In case you have some pre-commit rules turned on which doesn't allow you to make a commit (like linting), you can override them by passing the --no-verify flag:
git commit -m "Some changes" --no-verify
4. Revert all changes
Sometimes, I experiment with the code. A bit later, I realize that it's not the right path and I need to undo all of my changes.

One simple command for that is:
git reset --hard
5. See the latest commits
I can easily see what's going on on my branch by typing:
git log
I can see the commit hashes, messages, authors, and dates.

6. Pulling the changes from the remote branch
When I checkout an already existing branch (usually main or development), I need to fetch and merge the latest changes.

There is a shorthand for that:
git pull
Sometimes, if you're in one of your newly created branches, you'll also need to specify the origin branch:
git pull origin/<branch_name>
7. Undoing a local, unpushed commit
I made a commit. Damn! Something's wrong here. I need to make one more change.

No worries:
git reset --soft HEAD~1
This command will revert your last commit and keep the changes you made.

HEAD~1 means that your head is pointing on one commit earlier than your current - exactly what you want.

8. Undoing a pushed commit
I made some changes and pushed them to remote. Then, I realized it's not what I want.

For this, I use:
git revert <commit_hash>
Be aware that this will be visible in your commit history.

9. Stashing my changes
I'm in the middle of the feature, and my teammate pings me for an urgent code review.

I obviously don't want to trash my changes, neither I want to commit them. I don't want to create a bunch of meaningless commits.

I only want to check his branch and return to my work.

To do so:
// stash your changes
git stash
// check out and review your teammate's branch
git checkout <your_teammates_branch>
... code reviewing
// check out your branch in progress
git checkout <your_branch>
// return the stashed changes
git stash pop
pop seems familiar here? Yep, this works like a stack.

Meaning, if you do git stash twice in a row without git stash pop in between, they will stack onto each other.

10. Reseting your branch to remote version
I messed something up. Some broken commits, some broken npm installs.

Whatever I do, my branch is not working well anymore.

The remote version is working fine. Let's make it the same!
git fetch origin
git reset --hard origin/<branch_name>
11. Picking commits from other branches
Sometimes, I want to apply the commits from the other branches. For this, I use:
git cherry-pick <commit_hash> 
If I want to pick a range:
git cherry-pick <oldest_commit_hash>^..<newest_commit_hash>
~~~

### Sample

~~~
$ git init
$ git remote add origin git@github.com:aaaaaa
$ git remote -v
~~~

### Set pre-commit
- Link:<br>
https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks<br>
https://qiita.com/ishim0226/items/7767ee6d0828d3c84122
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
- Link:<br>https://docs.github.com/en/rest/guides/getting-started-with-the-rest-api
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

$ curl -s https://api.github.com/users/prodigy413/repos | jq -r '.[].name'
20210602_test
cicd-test
.........

### You can check url like release, branch.....
$ curl -s https://api.github.com/users/prodigy413/repos
~~~

### branch setting

<b>Create rule for each branch</b><br>
Move to branch you want to set - [Settings] - [Branches] - Branch protection rules[Add rule]<br>
Set Branch name pattern<br>
Check [Require pull request reviews before merging] - [Dismiss....] - [Require....]<br>
Check [Require status checks to pass before merging] - [Require branc....] - set one more time after push or build.
Check [Include administrators]

### Code owners file

.github/CODEOWNERS
~~~
* @prodigy413
*.py  @prodigy413
/public/ @leonheart413
~~~

### Push symlink
~~~
$ mkdir share && cd share
$ echo "This is test" >> test.txt
$ cd ..
$ mkdir main && cd main
$ ln -s ../share/test.txt test.txt
$ ls -l
total 0
lrwxrwxrwx 1 obi obi 17  8月 13 17:05 test.txt -> ../share/test.txt
~~~

### Caching your GitHub credentials in Git
- Link:<br>
https://docs.github.com/en/get-started/getting-started-with-git/caching-your-github-credentials-in-git<br>
https://github.com/microsoft/Git-Credential-Manager-Core/releases/tag/v2.0.498<br>
https://github.com/microsoft/Git-Credential-Manager-Core/blob/main/docs/linuxcredstores.md

- Access Token<br>
https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token

~~~
$ sudo dpkg -i gcmcore-linux_amd64.2.0.498.54650.deb
$ git-credential-manager-core configure
$ git config --global credential.credentialStore plaintext

$ git clone https://xxxxxxx.git
Select access token
~~~

### github command
https://github.com/cli/cli<br>
https://github.com/cli/cli/releases<br>
https://cli.github.com/manual/<br>
https://github.com/cli/cli/blob/trunk/docs/install_linux.md<br>

~~~
$ wget https://github.com/cli/cli/releases/download/v2.2.0/gh_2.2.0_linux_amd64.tar.gz
$ tar xvf gh_2.2.0_linux_amd64.tar.gz
$ sudo cp gh_2.2.0_linux_amd64/bin/gh /usr/local/bin/
$ gh --version
gh version 2.2.0 (2021-10-25)
https://github.com/cli/cli/releases/tag/v2.2.0

$ gh auth login
? What account do you want to log into? GitHub.com
? What is your preferred protocol for Git operations? SSH
? Upload your SSH public key to your GitHub account? /home/obi/.ssh/github.pub
? How would you like to authenticate GitHub CLI? Paste an authentication token
Tip: you can generate a Personal Access Token here https://github.com/settings/tokens
The minimum required scopes are 'repo', 'read:org', 'admin:public_key'.
? Paste your authentication token: ****************************************
- gh config set -h github.com git_protocol ssh
✓ Configured git protocol
✓ Uploaded the SSH key to your GitHub account: /home/obi/.ssh/github.pub
✓ Logged in as obi
~~~

https://qiita.com/tippy/items/79ca3f7b7bcac1d92136<br>
https://docs.github.com/en/rest/reference/actions#list-workflow-runs<br>

~~~
gh api repos/user/terraform-test/actions/workflows
~~~
