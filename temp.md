- https://releases.hashicorp.com/terraform

```
curl -fsSL https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_${ARCH}.zip -o /tmp/terraform.zip
unzip -oq /tmp/terraform.zip terraform -d "$HOME/bin"
```
