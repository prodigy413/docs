### Notifications setting

Your account - [Settings] - [Notifications] - GitHub Actions[Email, Web check or uncheck]

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
