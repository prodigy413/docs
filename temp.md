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
    keysSecret: instana-agent-key
    endpointHost: ingress-blue-saas.instana.io
    endpointPort: "443"
    image:
      tag: "1.310.7"
    pod:
      nodeSelector:
        instana: enable
      requests:
        cpu: "0.5"
        memory: "512Mi"
      limits:
        cpu: "1.5"
        memory: "1Gi"
    #proxyHost: "172.21.159.229"
    #proxyPort: "3128"
    #proxyProtocol: "http"
    env:
      INSTANA_AGENT_PROXY_HOST: "10.102.81.68"
      INSTANA_AGENT_PROXY_PORT: "3128"
      INSTANA_AGENT_PROXY_PROTOCOL: "http"
      INSTANA_AGENT_UPDATES_TIME: "12:00"
    configuration_yaml: |
      com.instana.ignore:
        arguments:
          - '/opt/batch/properties/batch.prop'
          - '/opt/batch/properties/if.prop'
          - 'com.mobit.redis2ssh.LogTransfer'
  k8s_sensor:
    image:
      tag: "1.2.13"
```
