```


oc project default

oc get deploy,ds,pod -n instana-agent

oc delete -f instana-agent.yaml -n instana-agent


# Agentとk8sensorがないことを確認
oc get deploy,ds,pod -n instana-agent

oc delete -f https://github.com/instana/instana-agent-operator/releases/download/v2.2.14/instana-agent-operator.yaml

oc get project instana-agent

# Namespace 作成とポリシー設定
oc new-project instana-agent
oc adm policy add-scc-to-user privileged -z instana-agent -n instana-agent
oc adm policy add-scc-to-user anyuid -z instana-agent-remote -n instana-agent

oc apply -f instana-configuration.yaml

oc project instana-agent

oc get deploy,ds,pod

```
