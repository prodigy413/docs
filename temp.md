~~~
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  labels:
    release: test
  name: rule-container-ready
  namespace: monitoring
spec:
  groups:
  - name: kubernetes-resources
    rules:
    - alert: ContainerDown
      annotations:
        description: 'Target: {{ $labels.namespace }} / {{ $labels.pod }} /{{ $labels.container }}'
        runbook_url: https://runbooks.prometheus-operator.dev/runbooks/kubernetes/cputhrottlinghigh
        summary: Container Down
      expr: |-
        kube_pod_container_status_ready{namespace="default"} < 1
      for: 1m
      labels:
        cluster: test-cluster
~~~
