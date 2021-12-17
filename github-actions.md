### Udemy github link
https://github.com/alialaa/github-actions-course

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

- Trigger setting<br>
https://docs.github.com/en/actions/reference/events-that-trigger-workflows

~~~yaml
on:
  pull_request:
    types: [closed, assigned]
~~~

- Trigger manually<br>
https://docs.github.com/en/rest/reference/repos#create-a-repository-dispatch-event

~~~shell
$ curl \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/prodigy413/action-test/dispatches \
  -d '{"event_type":"test-run","client_payload":{"env":"production"}}'

## Token
https://docs.github.com/en/rest/reference/actions#create-a-registration-token-for-a-repository--code-samples

$ curl \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/prodigy413/docs/actions/runners/registration-token
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
~~~

- Branches, Tags, Paths, cron<br>
Pattern Link: https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions#filter-pattern-cheat-sheet

~~~yaml
on:
  schedule:
    - cron: "0/5 * * * *"
  #   - cron: "0/6 * * * *" 
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

~~~yaml
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

~~~yaml
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

- Context<br>
Link: https://docs.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions

~~~yaml
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

- Function<br>
Link: https://docs.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#functions

~~~yaml
jobs:
  functions: 
    runs-on: ubuntu-16.04
    steps:
      - name: dump
        run: |
          echo ${{ contains( 'hello', '11' ) }}
          echo ${{ startsWith( 'hello', 'he' ) }}
          echo ${{ endsWith( 'hello', '1o' ) }}
          echo ${{ format( 'Hello {0} {1} {2}', 'World', '!', '!' ) }}
~~~

- If<br>
Link: https://docs.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#job-status-check-functions

~~~yaml
  one:
    runs-on: ubuntu-16.04
    if: github.event_name == 'push'
    steps:
      - name: Dump GitHub context
        env:
          GITHUB_CONTEXT: ${{ toJson(github) }}
        run: eccho "$GITHUB_CONTEXT"
      - name: Dump job context
        if: failure()
~~~

- Continue on error & Timeout<br>

~~~yaml
jobs:
  run-shell-command:
    runs-on: ubuntu-latest
    steps: 
      - name: echo a string
        run: echo "Hello World"
        timeout-minutes: 0 # Default: 360s
        continue-on-error: true
~~~

- Matrix

~~~yaml
### 3 OS & 3 Node version = will run 9 times
name: Matrix 
on: push 

jobs: 
  node-version:
    strategy: 
      matrix:
        os: [macos-latest, ubuntu-latest, windows-latest] 
        node_version: [6, 8, 10]
      #max-parallel: 2  
      #fail-fast: true # If one of them fails, all jobs will stop 
    runs-on: ${{ matrix.os }}
    steps: 
      - name: Log node version 
        run: node -v
      - uses: actions/setup-node@v1
        with:
          node-version: ${{ matrix.node_version }}
      - name: Log node version 
        run: node -v
~~~

~~~yaml
name: Matrix 
on: push 

jobs: 
  node-version:
    strategy: 
      matrix:
        os: [macos-latest, ubuntu-latest, windows-latest] 
        node_version: [6, 8, 10]
        include: 
          - os: ubuntu-latest # When os = ubuntu, verion 8, set variable(is_ubuntu_8: "true")
            node_version: 8
            is_ubuntu_8: "true"
        exclude:
          - os: ubuntu-latest # Skip when ubuntu and version 6
            node_version: 6
          - os: macos-latest
            node_version: 8
    runs-on: ${{ matrix.os }}
    env: 
      IS_UBUNTU_8: ${{ matrix.is_ubuntu_8 }}
    steps: 
      - name: Log node version 
        run: node -v
      - uses: actions/setup-node@v1
        with:
          node-version: ${{ matrix.node_version }}
      - name: Log node version 
        run:  | 
          node -v
          echo $IS_UBUNTU_8
~~~

- Docker<br>
Link: https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions#jobsjob_idcontainer

~~~yaml
name: Container
on: push

jobs: 
  node-docker:
    runs-on: ubuntu-latest
    container:
      image: node:13.5.0-alpine3.10
    steps:
      - name: Log node version  
        run: |
          node -v
          cat /etc/os-release
~~~

~~~yaml
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      app:
        image: prodigy413/test:1.0
        port:
          - 80:80
      db:
        image: sql
        ports:
          - 123:123
    steps:
      - name: Log node version  
        run: |
          node -v
          cat /etc/os-release
~~~

~~~yaml
jobs: 
  node-docker:
    runs-on: ubuntu-latest
    container:
      image: node:13.5.0-alpine3.10
    steps:
      - name: Log node version
        run: |
          node -v
          cat /etc/os-release
      - name: Step with docker
        uses: docker://node:12.14.1
        with:
          entrypoint: ['/bin/echo', 'Hello']
          #entrypoint: '/bin/echo'
          #args: 'Hello'
~~~

~~~yaml
jobs: 
  node-docker:
    runs-on: ubuntu-latest
    container:
      image: node:13.5.0-alpine3.10
    steps:
      - name: Log node version
        run: |
          node -v
          cat /etc/os-release
      - uses: actions/checkout@v1
      - name: Run a script
        uses: docker://node:12.14.1
        with:
          entrypoint: ./script.sh
~~~

- Slack

~~~yaml
jobs: 
  node-docker:
    runs-on: ubuntu-latest
    container:
      image: node:13.5.0-alpine3.10
    steps:
      - name: Send a slack message
        uses: docker://technosophos/slack-notify
        env:
          SLACK_WEBHOOK: 'https://hooks.slack.com/services/xxxxx' or ${{ secrets.SLACK_WEBHOOK }}
          SLACK_MESSAGE: "Test Message"
~~~

### Artifact
- Link:<br>
https://github.com/actions/upload-artifact<br>
https://github.com/actions/download-artifact<br>
https://docs.github.com/en/actions/guides/storing-workflow-data-as-artifacts

~~~yaml
jobs:
  test-1:
    runs-on: ubuntu-latest
    steps:
      - name: Run Test
        run: |
          echo hello > world.txt
          cat world.txt
      - name: Test artifact
        uses: actions/upload-artifact@v2 # Upload artifacts to github.
        with:
          name: world.txt
          path: ${{ github.workspace }}

  test-2:
    runs-on: ubuntu-latest
    steps:
      - name: Test artifact
        uses: actions/download-artifact@v2
        with:
          name: world.txt
          path: ${{ github.workspace }} # Download artifacts from github to directory on ubuntu.

      - name: Run Test
        run: |
          cat world.txt
~~~

~~~yaml
jobs:
  test-1:
    runs-on: ubuntu-latest
    steps:
      - name: Run Test
        run: |
          echo hello > /tmp/test-1/world.txt
          cat /tmp/test-1/world.txt
      - name: Test artifact
        uses: actions/upload-artifact@v2
        with:
          name: world.txt
          path: /tmp/test-1/world.txt

  test-2:
    runs-on: ubuntu-latest
    steps:
      - name: Test artifact
        uses: actions/download-artifact@v2
        with:
          name: world.txt
          path: /tmp/test-2/world.txt

      - name: Run Test
        run: |
          cat /tmp/test-2/world.txt
~~~

### Storage status check
Your account > [Settings] > [Billing & plans] : Storage for Actions and Packages

### Trigger manually
########<b>Default Branch must have yml workflow</b>#######<br><br>
https://docs.github.com/en/rest/reference/actions#create-a-workflow-dispatch-event<br>
https://docs.github.com/en/actions/learn-github-actions/events-that-trigger-workflows#workflow_dispatch<br>

~~~
name: Manually triggered workflow
on:
  workflow_dispatch:
    inputs:
      name:
        description: 'username'
        required: false
        default: 'Obi'

jobs:
  say_hello:
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "Hello ${{ github.event.inputs.name }}!"
~~~

~~~
gh api -X POST repos/prodigy413/20211113_github_actions_test/actions/workflows/test.yml/dispatches --input -<<< '{"ref":"main","inputs":{"name":"test"}}'
curl \
  -H "Authorization: token $TOKEN" \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/user/github_actions_test/actions/workflows/test.yml/dispatches \
  -d '{"ref":"main","inputs":{"name":"test"}}'
~~~

~~~
gh api repos/prodigy413/20211113_github_actions_test/actions/runs
curl \
  -H "Authorization: token $TOKEN" \
  -X GET \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/prodigy413/20211113_github_actions_test/actions/runs
~~~

~~~
### Get workflow list
gh -R github.com/prodigy413/20211113_github_actions_test workflow list

### Display detail
gh -R github.com/prodigy413/20211113_github_actions_test workflow view 2970

### Display latest 5 runs
gh -R github.com/prodigy413/20211113_github_actions_test run list -w test.yml -L 5

### Display detail
gh -R github.com/prodigy413/20211113_github_actions_test run view 1458114683

### Get job detail
gh -R github.com/prodigy413/20211113_github_actions_test run view --job 4198738474

### Get job log
gh -R github.com/prodigy413/20211113_github_actions_test run view --log --job 4198738474

### Run workflow
gh -R github.com/prodigy413/20211113_github_actions_test --ref main workflow run 'Manually triggered workflow' --json -<<< '{"name":"test"}'

### See runs
gh -R github.com/prodigy413/20211113_github_actions_test run list --workflow=test.yml

### Watch run
gh -R github.com/prodigy413/20211113_github_actions_test run watch --exit-status && notify-send "run is done!"
~~~

https://www.fixes.pub/program/314451.html<br>

### Self hosted runners
https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners<br>
https://testdriven.io/blog/github-actions-docker/<br>

- Install on linux

~~~
$ mkdir actions-runner && cd actions-runner# Download the latest runner package
$ curl -o actions-runner-linux-x64-2.285.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.285.1/actions-runner-linux-x64-2.285.1.tar.gz# 
$ echo "5fd98e1009ed13783d17cc73f13ea9a55f21b45ced915ed610d00668b165d3b2  actions-runner-linux-x64-2.285.1.tar.gz" | shasum -a 256 -c# Extract the installer
$ tar xzf ./actions-runner-linux-x64-2.285.1.tar.gz
$ ./config.sh --url https://github.com/prodigy413/docs --token ADFGQYWFBH5HKSBFXRNFBATBWXZRM# Last step, run it!
$ ./run.sh

# Run as a service
sudo ./svc.sh install

# Use this YAML in your workflow file for each job
runs-on: self-hosted
~~~

