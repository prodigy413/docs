~~~
# https://docs.github.com/ja/actions/advanced-guides/using-github-cli-in-workflows
# https://cli.github.com/manual/gh_release_create

name: Release notes

on:
  push:
    branches:
      - main
env:
  TAGS: v1.3.0

jobs:
  release-notes:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Release notes
        run: |
          curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
          echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
          sudo apt update
          sudo apt install gh
          gh --version
          ls -l
          gh release create "$TAGS" --target main --generate-notes
#          tar cvfz all-files.tar.gz *
#          gh release create "$TAGS" --target main -F changelog.md ./all-files.tar.gz
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
~~~
