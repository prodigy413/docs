~~~
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluentd
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: fluentd
rules:
- apiGroups:
  - ""
  resources:
  - pods
  - namespaces
  verbs:
  - get
  - list
  - watch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: fluentd
roleRef:
  kind: ClusterRole
  name: fluentd
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: fluentd
  namespace: kube-system
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: kube-system
  labels:
    k8s-app: fluentd-logging
    version: v1
spec:
  selector:
    matchLabels:
      k8s-app: fluentd-logging
      version: v1
  template:
    metadata:
      labels:
        k8s-app: fluentd-logging
        version: v1
    spec:
      serviceAccount: fluentd
      serviceAccountName: fluentd
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        effect: NoSchedule
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1-debian-forward
        env:
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name:  FLUENT_FOWARD_HOST
            value: "192.168.245.105"
          - name:  FLUENT_FOWARD_PORT
            value: "24224"
          - name:  FLUENT_CONTAINER_TAIL_EXCLUDE_PATH
            value: "/var/log/containers/fluent*"
          #- name: FLUENT_CONTAINER_TAIL_PARSER_TYPE
          #  value: /^(?<time>.+) (?<stream>stdout|stderr)( (?<logtag>.))? (?<log>.*)$/
          - name: FLUENT_CONTAINER_TAIL_PARSER_TIME_FORMAT
            value: "%Y-%m-%dT%H:%M:%S.%N%:z"
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        # When actual pod logs in /var/lib/docker/containers, the following lines should be used.
        # - name: dockercontainerlogdirectory
        #   mountPath: /var/lib/docker/containers
        #   readOnly: true
        # When actual pod logs in /var/log/pods, the following lines should be used.
        - name: dockercontainerlogdirectory
          mountPath: /var/log/pods
          readOnly: true
        - name: fluent-conf
          mountPath: /fluentd/etc/fluent.conf
          subPath: fluent.conf
      terminationGracePeriodSeconds: 30
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      # When actual pod logs in /var/lib/docker/containers, the following lines should be used.
      # - name: dockercontainerlogdirectory
      #   hostPath:
      #     path: /var/lib/docker/containers
      # When actual pod logs in /var/log/pods, the following lines should be used.
      - name: dockercontainerlogdirectory
        hostPath:
          path: /var/log/pods
      - name: fluent-conf
        configMap:
          name: fluentd-configmap
          items:
            - key: fluent.conf
              path: fluent.conf
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-configmap
  namespace: kube-system
data:
  fluent.conf: |2
    <system>
      emit_error_log_interval 60s
      <metrics>
        @type local
      </metrics>
    </system>
    <source>
      @type tail
      @id in_tail_container_logs
      path "#{ENV['FLUENT_CONTAINER_TAIL_PATH'] || '/var/log/containers/*.log'}"
      pos_file "#{File.join('/var/log/', ENV.fetch('FLUENT_POS_EXTRA_DIR', ''), 'containers.log.pos')}"
      tag "#{ENV['FLUENT_CONTAINER_TAIL_TAG'] || 'kubernetes.logs.*'}"
      exclude_path "#{ENV['FLUENT_CONTAINER_TAIL_EXCLUDE_PATH'] || use_default}"
      read_from_head false
      refresh_interval 5
      enable_stat_watcher false
      encoding UTF-8
      from_encoding UTF-8
      <parse>
        #@type cri
        @type multi_format
        <pattern>
          format regexp
          time_key time
          keep_time_key true
          time_format %Y-%m-%dT%H:%M:%S.%N%:z
          expression /^(?<time>\S+)\s+(?<stream>stdout|stderr) \b(?<containerd_prefix>F|P) (?<containerd_log>.*)$/
        </pattern>
      </parse>
    </source>

    <source>
      @type tail
      @id in_tail_kubelet
      multiline_flush_interval 5s
      path /var/log/kubelet.log
      pos_file "#{File.join('/var/log/', ENV.fetch('FLUENT_POS_EXTRA_DIR', ''), 'fluentd-kubelet.log.pos')}"
      tag kubelet
      format none
      read_from_head false
      enable_stat_watcher false
      encoding UTF-8
      #<parse>
      #  @type kubernetes
      #</parse>
    </source>

    <label @FLUENT_LOG>
      <match fluent.**>
        @type null
        @id ignore_fluent_logs
      </match>
    </label>

    <filter kubernetes.log.var.log.containers.**.log>
      @type kubernetes_metadata
      skip_container_metadata
      skip_labels
      skip_master_url
      skip_namespace_metadata
    </filter>

    <filter kubernetes.log.**>
      @type prometheus
      <metric>
        name fluentd_input_status_num_records_total
        type counter
        desc The total number of incoming records
        <labels>
          tag ${tag}
        </labels>
      </metric>
    </filter>

    <source>
      @type prometheus
      @id in_prometheus
      bind "0.0.0.0"
      port 24231
      metrics_path "/metrics"
    </source>

    <source>
      @type prometheus_monitor
      @id in_prometheus_monitor
    </source>

    <source>
      @type prometheus_tail_monitor
      @id prometheus_tail_monitor
    </source>

    <source>
      @type prometheus_output_monitor
      @id in_prometheus_output_monitor
    </source>

    #<match **>
    #  @type forward
    #  @id out_fwd
    #  @log_level info
    #  <server>
    #    host "#{ENV['FLUENT_FOWARD_HOST']}"
    #    port "#{ENV['FLUENT_FOWARD_PORT']}"
    #  </server>
    #  <buffer>
    #    flush_interval "#{ENV['FLUENT_FORWARD_FLUSH_INTERVAL'] || use_default}"
    #  </buffer>
    #</match>

    <match **>
      @type copy
      <store>
        @type forward
        @id out_fwd
        @log_level info
        <server>
          host "#{ENV['FLUENT_FOWARD_HOST']}"
          port "#{ENV['FLUENT_FOWARD_PORT']}"
        </server>
        <buffer>
          flush_interval "#{ENV['FLUENT_FORWARD_FLUSH_INTERVAL'] || use_default}"
        </buffer>
      </store>
      <store>
        @type prometheus
        <metric>
          name fluentd_output_status_num_records_total
          type counter
          desc The total number of outgoing records
          <labels>
            tag ${tag_parts[0]}
          </labels>
        </metric>      
      </store>
    </match>

# curl http://localhost:24231/metrics

~~~
