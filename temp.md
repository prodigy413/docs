```
helm upgrade logs-agent oci://icr.io/ibm-observe/logs-agent-helm \
--version 1.6.3 --values logs-values.yaml -n ibm-observe

helm install logs-agent oci://icr.io/ibm-observe/logs-agent-helm \
--version 1.6.3 --values logs-values.yaml -n ibm-observe

helm rollback logs-agent -n ibm-observe
```

```yaml
on:
  push:
    branches:
    - super-linter
jobs:
  build:
    name: Lint
    runs-on: ubuntu-latest

    permissions:
      contents: read
      packages: read
      statuses: write
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v6
        with:
          fetch-depth: 0
          persist-credentials: false

      - name: Super-linter
        uses: super-linter/super-linter@v8.3.0
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          #VALIDATE_YAML: true
          VALIDATE_YAML_PRETTIER: true
          VALIDATE_ALL_CODEBASE: false
          #YAML_FILE_NAME: .yamllint.yml
          FILTER_REGEX_INCLUDE: "yaml/yaml02/.*"
```

https://prettier.io/docs/options
