### Cypress Docs
https://docs.cypress.io/guides/overview/why-cypress

### Install
https://docs.cypress.io/guides/getting-started/installing-cypress#System-requirements

~~~
$ sudo apt install libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 libxtst6 xauth xvfb

$ mkdir cypress_test

$ cd cypress_test

$ npm init -y
Wrote to /home/obi/test/cypress_test/package.json:

{
  "name": "cypress_test",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}

$ npm install cypress

$ ./node_modules/.bin/cypress --version
Cypress package version: 8.3.1
Cypress binary version: 8.3.1
Electron version: 13.2.0
Bundled Node version: 14.16.0

$ ./node_modules/.bin/cypress open

$ ./node_modules/.bin/cypress

$ ./node_modules/.bin/cypress run --spec "./cypress/integration/2-advanced-examples/actions.spec.js"
~~~
