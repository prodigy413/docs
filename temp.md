~~~
####
## Output descriptions:
##


# Treasure Data (http://www.treasure-data.com/) provides cloud based data
# analytics platform, which easily stores and processes data from td-agent.
# FREE plan is also provided.
# @see http://docs.fluentd.org/articles/http-to-td
#
# This section matches events whose tag is td.DATABASE.TABLE
<match td.*.*>
  @type tdlog
  @id output_td
  apikey YOUR_API_KEY

  auto_create_table
  <buffer>
    @type file
    path /var/log/td-agent/buffer/td
  </buffer>

  <secondary>
    @type file
    path /var/log/td-agent/failed_records
  </secondary>
</match>

## match tag=debug.** and dump to console
<match debug.**>
  @type stdout
  @id output_stdout
</match>

####
## Source descriptions:
##

## built-in TCP input
## @see http://docs.fluentd.org/articles/in_forward
<source>
  @type forward
  @id input_forward
</source>

## built-in UNIX socket input
#<source>
#  type unix
#</source>

# HTTP input
# POST http://localhost:8888/<tag>?json=<json>
# POST http://localhost:8888/td.myapp.login?json={"user"%3A"me"}
# @see http://docs.fluentd.org/articles/in_http
<source>
  @type http
  @id input_http
  port 8888
</source>

## live debugging agent
<source>
  @type debug_agent
  @id input_debug_agent
  bind 127.0.0.1
  port 24230
</source>

####
## Examples:
##

## File input
## read apache logs continuously and tags td.apache.access
#<source>
#  @type tail
#  @id input_tail
#  <parse>
#    @type apache2
#  </parse>
#  path /var/log/httpd-access.log
#  tag td.apache.access
#</source>

## File output
## match tag=local.** and write to file
#<match local.**>
#  @type file
#  @id output_file
#  path /var/log/td-agent/access
#</match>

## Forwarding
## match tag=system.** and forward to another td-agent server
#<match system.**>
#  @type forward
#  @id output_system_forward
#
#  <server>
#    host 192.168.0.11
#  </server>
#  # secondary host is optional
#  <secondary>
#    <server>
#      host 192.168.0.12
#    </server>
#  </secondary>
#</match>

## Multiple output
## match tag=td.*.* and output to Treasure Data AND file
#<match td.*.*>
#  @type copy
#  @id output_copy
#  <store>
#    @type tdlog
#    apikey API_KEY
#    auto_create_table
#    <buffer>
#      @type file
#      path /var/log/td-agent/buffer/td
#    </buffer>
#  </store>
#  <store>
#    @type file
#    path /var/log/td-agent/td-%Y-%m-%d/%H.log
#  </store>
#</match>












<source>
  @type forward
  port 24224
  bind 0.0.0.0
  @label @logs
</source>

<label @logs>
  <match **>
    @type file
    path /LOG/logs/${tag}.log
    append true
    <buffer tag>
      @type memory
      flush_mode interval
      flush_interval 0s
      chunk_limit_size 1g
    </buffer>
    <format>
      #@type single_value
      @type json
    </format>
  </match>
</label>












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

    <label @FLUENT_LOG>
      <match fluent.**>
        @type null
        @id ignore_fluent_logs
      </match>
    </label>

    <filter kubernetes.var.log.containers.**.log>
      @type kubernetes_metadata
      skip_container_metadata
      skip_labels
      skip_master_url
      skip_namespace_metadata
    </filter>

    <match **>
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
    </match>

















### fluentd for daemonset

<https://github.com/fluent/fluentd-kubernetes-daemonset>

- Fluentd to Td agent
fluentd-daemonset-forward.yaml

### td agent

<https://docs.fluentd.org/installation/before-install>

~~~

~~~

<https://docs.fluentd.org/installation/install-by-deb>

~~~
curl -fsSL https://toolbelt.treasuredata.com/sh/install-ubuntu-jammy-td-agent4.sh | sh
$ sudo systemctl enable td-agent.service --now
$ systemctl status td-agent.service
~~~

- Check after install
~~~
$ curl -X POST -d 'json={"json":"message"}' http://localhost:8888/debug.test
$ tail -n 1 /var/log/td-agent/td-agent.log
2018-01-01 17:51:47 -0700 debug.test: {"json":"message"}
~~~

- Configuration<br>
`/etc/td-agent/td-agent.conf`
~~~

~~~

### Issue01

fluentd-daemonset-forward.yaml uses json type as default of file parse.<br>
But containerd default log format is not json type.<br>
Use cri parse to get json format.<br>
cri plugin is included in image for fluentd-daemonset-forward.yaml.

- fluent-plugin-parser-cri<br>
<https://github.com/fluent/fluent-plugin-parser-cri>

~~~
<source>
  @type tail
..........
  <parse>
    @type cri
  </parse>
</source>
~~~

### Issue02

If you set buffer with tag, path should has tag.

~~~
<match log.*>
  @type file
  path /data/${tag}/access.log
  <buffer tag>
..........
  </buffer>
</match>
~~~
~~~
