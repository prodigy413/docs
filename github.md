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

$ curl -s https://api.github.com/users/prodigy413/repos | jq -r '.[].name'
20210602_test
cicd-test
.........
~~~

### Gtihub Actions
- Link: https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions
- Config

~~~
$ git clone xxxxxxxx
$ touch .github/workflows/test.yaml
~~~

- Enable DEBUG<br>
Add paramater as secrets<br>
`Name: ACTIONS_STEP_DEBUG, Value: true`

- Run different shell

~~~yaml
jobs:
  run1:
    runs-on: ubuntu-latest
    steps: 
      - name: python Command 
        run: |
          import platform 
          print(platform.processor())
        shell: python
  run2:
    runs-on: windows-latest
    steps:
      - name: Directory PowerShell
        run: Get-Location 
      - name: Directory Bash 
        run: pwd 
        shell: bash
~~~

- Set dependency<br>

~~~yaml
jobs:
  run1:
    ..........
  run2:
    needs: ["run1"]
    steps:
      ..........
~~~

- Set outputs(Set global variables)<br>
https://docs.github.com/en/actions/reference/workflow-commands-for-github-actions

~~~yaml
## I don't know where [time] is from.
      - name: Simple JS Action
        id: greet 
        uses: actions/hello-world-javascript-action@v1
        with: 
          who-to-greet: John
      - name: Log Greeting Time
        run: echo "${{ steps.greet.outputs.time }}"
~~~

~~~yaml
     - name: run1
       run: |
           hoge='bar'
           echo "::set-output name=FOO::${hoge}"
       id: run1
     - name: run2
       run: echo 'The FOO is' ${{ steps.run1.outputs.FOO }}
~~~

- Trigger manually<br>
https://docs.github.com/en/rest/reference/repos#create-a-repository-dispatch-event

~~~shell
$ curl \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/prodigy413/action-test/dispatches \
  -d '{"event_type":"test-run","client_payload":{"env":"production"}}'
~~~

~~~yaml
on:
  repository_dispatch:
    types: [test-run]
~~~

Create Github access token<br>
Check all repo scope<br>
https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token

- Branches, Tags, Paths, cron

~~~yaml
on:
  push:
    branches:
      - master
      - "feature/**" # matches featur/featA, feature/featB, doesn't match feature/feat/a
      - "!feature/featc"
    # branche-ignore:
    #   - test
    tags: 
      - v1.*
    paths: 
      - "**.js"
      - "!filename.js"
    # paths-ignore:
    # - 'docs/**'
  # repository_dispatch:
  #   types: [build]
  # schedule:
  #   - cron: "0/5 * * * *"
  #   - cron: "0/6 * * * *" 
  # push:
  # pull_request:
  #   types: [closed, assigned, opened, reopened]
~~~

- Variables

~~~yaml
name: ENV Variables 
on: push 
env: 
  WF_ENV: Available to all jobs 

jobs: 
  log-env:
    runs-on: ubuntu-latest
    env:
      JOB_ENV: Available to all steps in log-env jobs
    steps:
      - name: Log ENV Variables 
        env: 
          STEP_ENV: Available to only this step 
        run: |
          echo "WF_ENV: ${WF_ENV}"
          echo "JOB_ENV: ${JOB_ENV}"
          echo "STEP_ENV: ${STEP_ENV}"
  log-default-env: 
    runs-on: ubuntu-latest
    steps:
      - name: Default ENV Variables 
        run: |
          echo "HOME: ${HOME}"
          echo "GITHUB_WORKFLOW: ${GITHUB_WORKFLOW}"
          echo "GITHUB_ACTION: ${GITHUB_ACTION}"
          echo "GITHUB_ACTIONS: ${GITHUB_ACTIONS}"
          echo "GITHUB_ACTOR: ${GITHUB_ACTOR}"
          echo "GITHUB_REPOSITORY: ${GITHUB_REPOSITORY}"
          echo "GITHUB_EVENT_NAME: ${GITHUB_EVENT_NAME}"
          echo "GITHUB_WORKSPACE: ${GITHUB_WORKSPACE}"
          echo "GITHUB_SHA: ${GITHUB_SHA}"
          echo "GITHUB_REF: ${GITHUB_REF}"
          echo "WF_ENV: ${WF_ENV}"
          echo "JOB_ENV: ${JOB_ENV}"
          echo "STEP_ENV: ${STEP_ENV}"
~~~

~~~
jobs: 
  create_issue:
    runs-on: ubuntu-latest
    steps:
      - name: Push a random file
        run: |
          pwd 
          ls -a 
          git init
          git remote add origin "https://$GITHUB_ACTOR:${{ secrets.GITHUB_TOKEN }}@github.com/$GITHUB_REPOSITORY.git"
          git config --global user.email "my-bot@bot.com"
          git config --global user.name "my-bot"
          git fetch
          git checkout master
          git branch --set-upstream-to=origin/master
          git pull
          ls -a
          echo $RANDOM >> random.txt
          ls -a 
          git add -A
          git commit -m"Random file"
          git push
      - name: Create issue using REST API
        run: |
          curl --request POST \
          --url https://api.github.com/repos/${{ github.repository }}/issues \
          --header 'authorization: Bearer ${{ secrets.GITHUB_TOKEN }}' \
          --header 'content-type: application/json' \
          --data '{
            "title": "Automated issue for commit: ${{ github.sha }}",
            "body": "This issue was automatically created by the GitHub Action workflow **${{ github.workflow }}**. \n\n The commit hash was: _${{ github.sha }}_."
            }'
~~~

- Decrypt

~~~
jobs:
  decrypt:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v1
      - name: Decrypt
        run: gpg --quiet --batch --yes --decrypt --passphrase="$PASSPHRASE" --output $HOME/secret.json secret.json.gpg
        env: 
          PASSPHRASE: ${{ secrets.PASSPHRASE }}
      - name: Print our file content 
        run: cat $HOME/secret.json
~~~

- Context

~~~
jobs:
  one:
    runs-on: ubuntu-16.04
    steps:
      - name: Dump GitHub context
        env:
          GITHUB_CONTEXT: ${{ toJson(github) }}
        run: echo "$GITHUB_CONTEXT"
      - name: Dump job context
        env:
          JOB_CONTEXT: ${{ toJson(job) }}
        run: echo "$JOB_CONTEXT"
      - name: Dump steps context
        env:
          STEPS_CONTEXT: ${{ toJson(steps) }}
        run: echo "$STEPS_CONTEXT"
      - name: Dump runner context
        env:
          RUNNER_CONTEXT: ${{ toJson(runner) }}
        run: echo "$RUNNER_CONTEXT"
      - name: Dump strategy context
        env:
          STRATEGY_CONTEXT: ${{ toJson(strategy) }}
        run: echo "$STRATEGY_CONTEXT"
      - name: Dump matrix context
        env:
          MATRIX_CONTEXT: ${{ toJson(matrix) }}
        run: echo "$MATRIX_CONTEXT"
~~~



