```
helm install logs-agent oci://icr.io/ibm/observe/logs-agent-helm \
--version 1.4.2 --values logs-values_1_4_2.yaml -n ibm-observe --create-namespace

helm upgrade logs-agent oci://icr.io/ibm/observe/logs-agent-helm \
--version 1.5.2 --values logs-values_1_5_2.yaml -n ibm-observe --create-namespace

helm upgrade logs-agent oci://icr.io/ibm-observe/logs-agent-helm \
--version 1.6.3 --values logs-values_1_6_3.yaml -n ibm-observe --create-namespace

helm upgrade logs-agent oci://icr.io/ibm-observe/logs-agent-helm \
--version 1.7.1 --values logs-values_1_7_1.yaml -n ibm-observe --create-namespace

helm registry login icr.io \
  -u iambearer \
  -p "$(ibmcloud iam oauth-tokens --output json | jq -r '.iam_token' | cut -d' ' -f2)"
```
