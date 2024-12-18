~~~
apiVersion: monitoring.coreos.com/v1
kind: Alertmanager
metadata:
  name: alertmanager
spec:
  alertmanagerConfigMatcherStrategy:
    type: None
  alertmanagerConfigSelector:
    matchLabels:
      alertmanager: enabled
  replicas: 2
  logFormat: json
  listenLocal: false
  retention: 168h
  securityContext:
    fsGroup: 2000
    runAsGroup: 2000
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  storage:
    volumeClaimTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        storageClassName: nks-block-storage
        resources:
          requests:
            storage: 1Gi




  alerting:
    alertmanagers:
    - apiVersion: v2
      name: test-kube-prometheus-stack-alertmanager
      namespace: monitoring
      pathPrefix: /
      port: http-web




apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig
metadata:
  name: notification-01
  labels:
    release: test
  namespace: monitoring
spec:
  route:
    groupBy: ['job']
    groupWait: 30s
    groupInterval: 5m
    repeatInterval: 12h
    receiver: "null"
    routes:
    - matchers:
      - name: cluster
        value: test-cluster
        matchType: "="
      receiver: slack01
  receivers:
  - name: "null"
  - name: "slack01"
    slackConfigs:
    - apiURL:
        name: webhook
        key: APIURL
      sendResolved: true
#      text: |-
#        {{ range .Alerts }}{{ .Annotations.description }}
#        {{ end }}
#      title: |-
#        {{ range .Alerts }}[{{ .Status | toUpper }}] {{ alertname }} - {{ .Annotations.summary }}
#        {{ end }}
      title: '[{{ .Status | toUpper }}] {{ .CommonLabels.alertname }}'
      text: '{{ .CommonAnnotations.description }}'
~~~
