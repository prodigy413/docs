- [Installing the agent on Red Hat OpenShift](https://www.ibm.com/docs/en/instana-observability/1.0.305?topic=openshift-installing-agent-red-hat)
- [Release notes for Instana agent Helm chart](https://www.ibm.com/docs/en/instana-observability/1.0.309?topic=agent-helm-chart)
- [Release notes for Instana agent operator](https://www.ibm.com/docs/en/instana-observability/1.0.309?topic=agent-operator)
- [helm-charts](https://github.com/instana/helm-charts/tree/main/instana-agent)
- [instana_v1_extended_instanaagent.yaml(For operator)](https://github.com/instana/instana-agent-operator/blob/main/config/samples/instana_v1_extended_instanaagent.yaml)

## Openshift

### Image

```
curl https://icr.io/v2/instana/agent/tags/list | jq
```

- Check

```
$ oc -n instana-agent get ds,deploy,svc,cm,secret
NAME                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR    AGE
daemonset.apps/instana-agent   1         1         1       1            1           instana=enable   3m42s

NAME                                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/instana-agent-controller-manager   1/1     1            1           3m46s
deployment.apps/instana-agent-k8sensor             3/3     3            3           3m41s

NAME                             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                                 AGE
service/instana-agent            ClusterIP   172.21.57.172   <none>        42699/TCP,4317/TCP,55680/TCP,4318/TCP   3m42s
service/instana-agent-headless   ClusterIP   None            <none>        42699/TCP,4317/TCP,55680/TCP,4318/TCP   3m42s

NAME                                 DATA   AGE
configmap/instana-agent-dependents   1      3m42s
configmap/instana-agent-k8sensor     1      3m41s
configmap/instana-agent-namespaces   1      3m41s
configmap/kube-root-ca.crt           1      4m20s
configmap/manager-config             1      3m46s
configmap/openshift-service-ca.crt   1      4m20s

NAME                                            TYPE                      DATA   AGE
secret/builder-dockercfg-dcfw7                  kubernetes.io/dockercfg   1      4m20s
secret/default-dockercfg-ptlqt                  kubernetes.io/dockercfg   1      4m20s
secret/deployer-dockercfg-d8mv8                 kubernetes.io/dockercfg   1      4m20s
secret/instana-agent                            Opaque                    2      3m41s
secret/instana-agent-config                     Opaque                    5      3m42s
secret/instana-agent-dockercfg-9hdzh            kubernetes.io/dockercfg   1      3m41s
secret/instana-agent-k8sensor-dockercfg-2tslf   kubernetes.io/dockercfg   1      3m41s
secret/instana-agent-operator-dockercfg-4rw2g   kubernetes.io/dockercfg   1      3m46s
secret/sh.helm.release.v1.instana-agent.v1      helm.sh/release.v1        1      3m46s


$ oc get pods -n instana-agent -l app.kubernetes.io/component=instana-agent \
  -o custom-columns="POD:.metadata.name,IMAGE:.spec.containers[*].image,NODESELECTOR:.spec.nodeSelector"
POD                   IMAGE                          NODESELECTOR
instana-agent-mk2zp   icr.io/instana/agent:1.309.1   map[instana:enable]
instana-agent-xq2bf   icr.io/instana/agent:1.309.1   map[instana:enable]
```

### Operator

```
oc apply -f https://github.com/instana/instana-agent-operator/releases/latest/download/instana-agent-operator.yaml
oc apply -f https://github.com/instana/instana-agent-operator/releases/download/v2.2.3/instana-agent-operator.yaml
```

- instana-agent.yaml

```
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
    key: xxxxxxx
    downloadKey: xxxxx
    endpointHost: xxxxxxx
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
    env:
      INSTANA_AGENT_PROXY_HOST: "172.21.145.240"
      INSTANA_AGENT_PROXY_PORT: "3128"
      INSTANA_AGENT_PROXY_PROTOCOL: "http"
    configuration_yaml: |
      com.instana.ignore:
        arguments:
          - '/opt/batch/properties/batch.prop'
          - '/opt/batch/properties/if.prop'
          - 'com.mobit.redis2ssh.LogTransfer'
```

- values.yaml

```
agent:
  key: EbuMpFEaRIm_3jCTZ_a9ag
  endpointHost: ingress-blue-saas.instana.io
  endpointPort: 443
  image:
    tag: 1.309.1
  pod:
    nodeSelector:
      instana: enable
  env:
    INSTANA_AGENT_PROXY_HOST: "172.21.145.240"
    INSTANA_AGENT_PROXY_PORT: 3128
    INSTANA_AGENT_PROXY_PROTOCOL: "http"
  resources:
    requests:
      cpu: "200m"
      memory: "512Mi"
    limits:
      cpu: 0.5
      memory: "1Gi"
cluster:
  name: test-cluster
zone:
  name: test-zone
```

# Lambda

<https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html>

# SCCWP

