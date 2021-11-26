### Install
https://nodejs.org/en/download/<br>
https://github.com/nodesource/distributions/blob/master/README.md

~~~
$ curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
$ sudo apt install -y nodejs
$ node --version
v14.17.6
~~~

### Install node using nvm
- Install nvm<br>
https://github.com/nvm-sh/nvm#install--update-script<br>

~~~
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

### ~/.zshrc, ~/.profile
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

nvm -v
0.39.0
~~~

- Install node
~~~
nvm install v14.17.0
nvm use v14.17.0
node -v
v14.17.0
~~~
