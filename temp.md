```
python3 -m venv venv
source venv/bin/activate
pip install openpyxl
deactivate
```

- [Installing the agent on Red Hat OpenShift](https://www.ibm.com/docs/en/instana-observability/1.0.305?topic=openshift-installing-agent-red-hat)
- [Release notes for Instana agent Helm chart](https://www.ibm.com/docs/en/instana-observability/1.0.309?topic=agent-helm-chart)
- [Release notes for Instana agent operator](https://www.ibm.com/docs/en/instana-observability/1.0.309?topic=agent-operator)
- [helm-charts](https://github.com/instana/helm-charts/tree/main/instana-agent)
-  InstanaAgent CR all fields
   - [instana_v1_extended_instanaagent.yaml(For operator)](https://github.com/instana/instana-agent-operator/blob/main/config/samples/instana_v1_extended_instanaagent.yaml)

## Openshift

### Image

```
curl https://icr.io/v2/instana/agent/tags/list | jq
```

```yaml
apiVersion: instana.io/v1
kind: InstanaAgent
metadata:
  name: instana-agent
  namespace: instana-agent
spec:
  zone:
    name: test-zone
  cluster:
      name: test-cluster
  agent:
    #keysSecret: instana-agent-key
    key: xxxxxx
    downloadKey: xxxxxx
    endpointHost: ingress-blue-saas.instana.io
    endpointPort: "443"
    image:
      #name: ""
      tag: "1.309.1"
    pod:
      nodeSelector:
        instana: enable
      requests:
        cpu: "0.5"
        memory: "512Mi"
      limits:
        cpu: "1.5"
        memory: "1Gi"
    proxyHost: "172.21.145.240"
    proxyPort: "3128"
    proxyProtocol: "http"
    #env:
    #  INSTANA_AGENT_PROXY_HOST: "172.21.145.240"
    #  INSTANA_AGENT_PROXY_PORT: "3128"
    #  INSTANA_AGENT_PROXY_PROTOCOL: "http"
    configuration_yaml: |
      com.instana.ignore:
        arguments:
          - '/opt/batch/properties/batch.prop'
          - '/opt/batch/properties/if.prop'
          - 'com.mobit.redis2ssh.LogTransfer'

```
