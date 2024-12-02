~~~yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: grafana-pvc
  namespace: monitoring
spec:
  #storageClassName: openebs-hostpath
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: grafana
  name: grafana
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      securityContext:
        fsGroup: 472
        supplementalGroups:
          - 0
      containers:
        - name: grafana
          image: grafana/grafana:latest
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 3000
              name: http-grafana
              protocol: TCP
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /robots.txt
              port: 3000
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 30
            successThreshold: 1
            timeoutSeconds: 2
          livenessProbe:
            failureThreshold: 3
            initialDelaySeconds: 30
            periodSeconds: 10
            successThreshold: 1
            tcpSocket:
              port: 3000
            timeoutSeconds: 1
          resources:
            requests:
              cpu: 250m
              memory: 750Mi
          volumeMounts:
            - mountPath: /var/lib/grafana
              name: grafana-pv
            #- mountPath: /etc/grafana
            #  name: grafana-config
            #- mountPath: /etc/grafana/provisioning/datasources
            #  name: datasource
            #- mountPath: /etc/grafana/provisioning/alerting
            #  name: alerting
            #- name: grafana-ini
            #  mountPath: /etc/grafana/grafana.ini
            #  subPath: grafana.ini
      volumes:
        - name: grafana-pv
          persistentVolumeClaim:
            claimName: grafana-pvc
        #- name: grafana-config
        #  configMap:
        #    name: grafana-config
        #- name: datasource
        #  configMap:
        #    name: datasource
        #- name: alerting
        #  configMap:
        #    name: alerting
        #- name: grafana-ini
        #  configMap:
        #    name: grafana-ini
        #    items:
        #    - key: grafana.ini
        #      path: grafana.ini
---
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: monitoring
spec:
  ports:
    - port: 3000
      protocol: TCP
      targetPort: http-grafana
  selector:
    app: grafana
  sessionAffinity: None
---









apiVersion: v1
data:
  grafana.ini: "##################### Grafana Configuration Example #####################\n#\n#
    Everything has defaults so you only need to uncomment things you want to\n# change\n\n#
    possible values : production, development\n;app_mode = production\n\n# instance
    name, defaults to HOSTNAME environment variable value or hostname if HOSTNAME
    var is empty\n;instance_name = ${HOSTNAME}\n\n####################################
    Paths ####################################\n[paths]\n# Path to where grafana can
    store temp files, sessions, and the sqlite3 db (if that is used)\n;data = /var/lib/grafana\n\n#
    Temporary files in `data` directory older than given duration will be removed\n;temp_data_lifetime
    = 24h\n\n# Directory where grafana can store logs\n;logs = /var/log/grafana\n\n#
    Directory where grafana will automatically scan and look for plugins\n;plugins
    = /var/lib/grafana/plugins\n\n# folder that contains provisioning config files
    that grafana will apply on startup and while running.\n;provisioning = conf/provisioning\n\n####################################
    Server ####################################\n[server]\n# Protocol (http, https,
    h2, socket)\n;protocol = http\n\n# Minimum TLS version allowed. By default, this
    value is empty. Accepted values are: TLS1.2, TLS1.3. If nothing is set TLS1.2
    would be taken\n;min_tls_version = \"\"\n\n# The ip address to bind to, empty
    will bind to all interfaces\n;http_addr =\n\n# The http port to use\n;http_port
    = 80\n\n# The public facing domain name used to access grafana from a browser\n;domain
    = grafana.test.local\n\n# Redirect to correct domain if host header does not match
    domain\n# Prevents DNS rebinding attacks\n;enforce_domain = false\n\n# The full
    public facing url you use in browser, used for redirects and emails\n# If you
    use reverse proxy and sub path specify full url (with sub path)\nroot_url = https://humble-jaybird-partly.ngrok-free.app\n\n#
    Serve Grafana from subpath specified in `root_url` setting. By default it is set
    to `false` for compatibility reasons.\n;serve_from_sub_path = false\n\n# Log web
    requests\n;router_logging = false\n\n# the path relative working path\n;static_root_path
    = public\n\n# enable gzip\n;enable_gzip = false\n\n# https certs & key file\n;cert_file
    =\n;cert_key =\n\n# optional password to be used to decrypt key file\n;cert_pass
    =\n\n# Certificates file watch interval\n;certs_watch_interval =\n\n# Unix socket
    gid\n# Changing the gid of a file without privileges requires that the target
    group is in the group of the process and that the process is the file owner\n#
    It is recommended to set the gid as http server user gid\n# Not set when the value
    is -1\n;socket_gid =\n\n# Unix socket mode\n;socket_mode =\n\n# Unix socket path\n;socket
    =\n\n# CDN Url\n;cdn_url =\n\n# Sets the maximum time using a duration format
    (5s/5m/5ms) before timing out read of an incoming request and closing idle connections.\n#
    `0` means there is no timeout for reading the request.\n;read_timeout = 0\n\n#
    This setting enables you to specify additional headers that the server adds to
    HTTP(S) responses.\n[server.custom_response_headers]\n#exampleHeader1 = exampleValue1\n#exampleHeader2
    = exampleValue2\n\n[environment]\n# Sets whether the local file system is available
    for Grafana to use. Default is true for backward compatibility.\n;local_file_system_available
    = true\n\n#################################### GRPC Server #########################\n;[grpc_server]\n;network
    = \"tcp\"\n;address = \"127.0.0.1:10000\"\n;use_tls = false\n;cert_file =\n;key_file
    =\n;max_recv_msg_size =\n;max_send_msg_size =\n# this will log the request and
    response for each unary gRPC call\n;enable_logging = false\n\n####################################
    Database ####################################\n[database]\n# You can configure
    the database connection by specifying type, host, name, user and password\n# as
    separate properties or as on string using the url properties.\n\n# Either \"mysql\",
    \"postgres\" or \"sqlite3\", it's your choice\n;type = sqlite3\n;host = 127.0.0.1:3306\n;name
    = grafana\n;user = root\n# If the password contains # or ; you have to wrap it
    with triple quotes. Ex \"\"\"#password;\"\"\"\n;password =\n# Use either URL or
    the previous fields to configure the database\n# Example: mysql://user:secret@host:port/database\n;url
    =\n\n# Max idle conn setting default is 2\n;max_idle_conn = 2\n\n# Max conn setting
    default is 0 (mean not set)\n;max_open_conn =\n\n# Connection Max Lifetime default
    is 14400 (means 14400 seconds or 4 hours)\n;conn_max_lifetime = 14400\n\n# Set
    to true to log the sql calls and execution times.\n;log_queries =\n\n# For \"postgres\",
    use either \"disable\", \"require\" or \"verify-full\"\n# For \"mysql\", use either
    \"true\", \"false\", or \"skip-verify\".\n;ssl_mode = disable\n\n# For \"postgres\",
    use either \"1\" to enable or \"0\" to disable SNI\n;ssl_sni =\n\n# Database drivers
    may support different transaction isolation levels.\n# Currently, only \"mysql\"
    driver supports isolation levels.\n# If the value is empty - driver's default
    isolation level is applied.\n# For \"mysql\" use \"READ-UNCOMMITTED\", \"READ-COMMITTED\",
    \"REPEATABLE-READ\" or \"SERIALIZABLE\".\n;isolation_level =\n\n;ca_cert_path
    =\n;client_key_path =\n;client_cert_path =\n;server_cert_name =\n\n# For \"sqlite3\"
    only, path relative to data_path setting\n;path = grafana.db\n\n# For \"sqlite3\"
    only. cache mode setting used for connecting to the database. (private, shared)\n;cache_mode
    = private\n\n# For \"sqlite3\" only. Enable/disable Write-Ahead Logging, https://sqlite.org/wal.html.
    Default is false.\n;wal = false\n\n# For \"mysql\" and \"postgres\" only. Lock
    the database for the migrations, default is true.\n;migration_locking = true\n\n#
    For \"mysql\" and \"postgres\" only. How many seconds to wait before failing to
    lock the database for the migrations, default is 0.\n;locking_attempt_timeout_sec
    = 0\n\n# For \"sqlite\" only. How many times to retry query in case of database
    is locked failures. Default is 0 (disabled).\n;query_retries = 0\n\n# For \"sqlite\"
    only. How many times to retry transaction in case of database is locked failures.
    Default is 5.\n;transaction_retries = 5\n\n# Set to true to add metrics and tracing
    for database queries.\n;instrument_queries = false\n\n####################################
    Cache server #############################\n[remote_cache]\n# Either \"redis\",
    \"memcached\" or \"database\" default is \"database\"\n;type = database\n\n# cache
    connectionstring options\n# database: will use Grafana primary database.\n# redis:
    config like redis server e.g. `addr=127.0.0.1:6379,pool_size=100,db=0,ssl=false`.
    Only addr is required. ssl may be 'true', 'false', or 'insecure'.\n# memcache:
    127.0.0.1:11211\n;connstr =\n\n# prefix prepended to all the keys in the remote
    cache\n; prefix =\n\n# This enables encryption of values stored in the remote
    cache\n;encryption =\n\n#################################### Data proxy ###########################\n[dataproxy]\n\n#
    This enables data proxy logging, default is false\n;logging = false\n\n# How long
    the data proxy waits to read the headers of the response before timing out, default
    is 30 seconds.\n# This setting also applies to core backend HTTP data sources
    where query requests use an HTTP client with timeout set.\n;timeout = 30\n\n#
    How long the data proxy waits to establish a TCP connection before timing out,
    default is 10 seconds.\n;dialTimeout = 10\n\n# How many seconds the data proxy
    waits before sending a keepalive probe request.\n;keep_alive_seconds = 30\n\n#
    How many seconds the data proxy waits for a successful TLS Handshake before timing
    out.\n;tls_handshake_timeout_seconds = 10\n\n# How many seconds the data proxy
    will wait for a server's first response headers after\n# fully writing the request
    headers if the request has an \"Expect: 100-continue\"\n# header. A value of 0
    will result in the body being sent immediately, without\n# waiting for the server
    to approve.\n;expect_continue_timeout_seconds = 1\n\n# Optionally limits the total
    number of connections per host, including connections in the dialing,\n# active,
    and idle states. On limit violation, dials will block.\n# A value of zero (0)
    means no limit.\n;max_conns_per_host = 0\n\n# The maximum number of idle connections
    that Grafana will keep alive.\n;max_idle_connections = 100\n\n# How many seconds
    the data proxy keeps an idle connection open before timing out.\n;idle_conn_timeout_seconds
    = 90\n\n# If enabled and user is not anonymous, data proxy will add X-Grafana-User
    header with username into the request, default is false.\n;send_user_header =
    false\n\n# Limit the amount of bytes that will be read/accepted from responses
    of outgoing HTTP requests.\n;response_limit = 0\n\n# Limits the number of rows
    that Grafana will process from SQL data sources.\n;row_limit = 1000000\n\n# Sets
    a custom value for the `User-Agent` header for outgoing data proxy requests. If
    empty, the default value is `Grafana/<BuildVersion>` (for example `Grafana/9.0.0`).\n;user_agent
    =\n\n#################################### Analytics ####################################\n[analytics]\n#
    Server reporting, sends usage counters to stats.grafana.org every 24 hours.\n#
    No ip addresses are being tracked, only simple counters to track\n# running instances,
    dashboard and error counts. It is very helpful to us.\n# Change this option to
    false to disable reporting.\n;reporting_enabled = true\n\n# The name of the distributor
    of the Grafana instance. Ex hosted-grafana, grafana-labs\n;reporting_distributor
    = grafana-labs\n\n# Set to false to disable all checks to https://grafana.com\n#
    for new versions of grafana. The check is used\n# in some UI views to notify that
    a grafana update exists.\n# This option does not cause any auto updates, nor send
    any information\n# only a GET request to https://grafana.com/api/grafana/versions/stable
    to get the latest version.\n;check_for_updates = true\n\n# Set to false to disable
    all checks to https://grafana.com\n# for new versions of plugins. The check is
    used\n# in some UI views to notify that a plugin update exists.\n# This option
    does not cause any auto updates, nor send any information\n# only a GET request
    to https://grafana.com to get the latest versions.\n;check_for_plugin_updates
    = true\n\n# Google Analytics universal tracking code, only enabled if you specify
    an id here\n;google_analytics_ua_id =\n\n# Google Analytics 4 tracking code, only
    enabled if you specify an id here\n;google_analytics_4_id =\n\n# When Google Analytics
    4 Enhanced event measurement is enabled, we will try to avoid sending duplicate
    events and let Google Analytics 4 detect navigation changes, etc.\n;google_analytics_4_send_manual_page_views
    = false\n\n# Google Tag Manager ID, only enabled if you specify an id here\n;google_tag_manager_id
    =\n\n# Rudderstack write key, enabled only if rudderstack_data_plane_url is also
    set\n;rudderstack_write_key =\n\n# Rudderstack data plane url, enabled only if
    rudderstack_write_key is also set\n;rudderstack_data_plane_url =\n\n# Rudderstack
    SDK url, optional, only valid if rudderstack_write_key and rudderstack_data_plane_url
    is also set\n;rudderstack_sdk_url =\n\n# Rudderstack Config url, optional, used
    by Rudderstack SDK to fetch source config\n;rudderstack_config_url =\n\n# Rudderstack
    Integrations URL, optional. Only valid if you pass the SDK version 1.1 or higher\n;rudderstack_integrations_url
    =\n\n# Intercom secret, optional, used to hash user_id before passing to Intercom
    via Rudderstack\n;intercom_secret =\n\n# Application Insights connection string.
    Specify an URL string to enable this feature.\n;application_insights_connection_string
    =\n\n# Optional. Specifies an Application Insights endpoint URL where the endpoint
    string is wrapped in backticks ``.\n;application_insights_endpoint_url =\n\n#
    Controls if the UI contains any links to user feedback forms\n;feedback_links_enabled
    = true\n\n# Static context that is being added to analytics events\n;reporting_static_context
    = grafanaInstance=12, os=linux\n\n#################################### Security
    ####################################\n[security]\n# disable creation of admin
    user on first start of grafana\n;disable_initial_admin_creation = false\n\n# default
    admin user, created on startup\n;admin_user = admin\n\n# default admin password,
    can be changed before first start of grafana,  or in profile settings\n;admin_password
    = admin\n\n# default admin email, created on startup\n;admin_email = admin@localhost\n\n#
    used for signing\n;secret_key = SW2YcwTIb9zpOOhoPsMm\n\n# current key provider
    used for envelope encryption, default to static value specified by secret_key\n;encryption_provider
    = secretKey.v1\n\n# list of configured key providers, space separated (Enterprise
    only): e.g., awskms.v1 azurekv.v1\n;available_encryption_providers =\n\n# disable
    gravatar profile images\n;disable_gravatar = false\n\n# data source proxy whitelist
    (ip_or_domain:port separated by spaces)\n;data_source_proxy_whitelist =\n\n# disable
    protection against brute force login attempts\n;disable_brute_force_login_protection
    = false\n\n# set to true if you host Grafana behind HTTPS. default is false.\n;cookie_secure
    = false\n\n# set cookie SameSite attribute. defaults to `lax`. can be set to \"lax\",
    \"strict\", \"none\" and \"disabled\"\n;cookie_samesite = lax\n\n# set to true
    if you want to allow browsers to render Grafana in a <frame>, <iframe>, <embed>
    or <object>. default is false.\n;allow_embedding = false\n\n# Set to true if you
    want to enable http strict transport security (HSTS) response header.\n# HSTS
    tells browsers that the site should only be accessed using HTTPS.\n;strict_transport_security
    = false\n\n# Sets how long a browser should cache HSTS. Only applied if strict_transport_security
    is enabled.\n;strict_transport_security_max_age_seconds = 86400\n\n# Set to true
    if to enable HSTS preloading option. Only applied if strict_transport_security
    is enabled.\n;strict_transport_security_preload = false\n\n# Set to true if to
    enable the HSTS includeSubDomains option. Only applied if strict_transport_security
    is enabled.\n;strict_transport_security_subdomains = false\n\n# Set to true to
    enable the X-Content-Type-Options response header.\n# The X-Content-Type-Options
    response HTTP header is a marker used by the server to indicate that the MIME
    types advertised\n# in the Content-Type headers should not be changed and be followed.\n;x_content_type_options
    = true\n\n# Set to true to enable the X-XSS-Protection header, which tells browsers
    to stop pages from loading\n# when they detect reflected cross-site scripting
    (XSS) attacks.\n;x_xss_protection = true\n\n# Enable adding the Content-Security-Policy
    header to your requests.\n# CSP allows to control resources the user agent is
    allowed to load and helps prevent XSS attacks.\n;content_security_policy = false\n\n#
    Set Content Security Policy template used when adding the Content-Security-Policy
    header to your requests.\n# $NONCE in the template includes a random nonce.\n#
    $ROOT_PATH is server.root_url without the protocol.\n;content_security_policy_template
    = \"\"\"script-src 'self' 'unsafe-eval' 'unsafe-inline' 'strict-dynamic' $NONCE;object-src
    'none';font-src 'self';style-src 'self' 'unsafe-inline' blob:;img-src * data:;base-uri
    'self';connect-src 'self' grafana.com ws://$ROOT_PATH wss://$ROOT_PATH;manifest-src
    'self';media-src 'none';form-action 'self';\"\"\"\n\n# Enable adding the Content-Security-Policy-Report-Only
    header to your requests.\n# Allows you to monitor the effects of a policy without
    enforcing it.\n;content_security_policy_report_only = false\n\n# Set Content Security
    Policy Report Only template used when adding the Content-Security-Policy-Report-Only
    header to your requests.\n# $NONCE in the template includes a random nonce.\n#
    $ROOT_PATH is server.root_url without the protocol.\n;content_security_policy_report_only_template
    = \"\"\"script-src 'self' 'unsafe-eval' 'unsafe-inline' 'strict-dynamic' $NONCE;object-src
    'none';font-src 'self';style-src 'self' 'unsafe-inline' blob:;img-src * data:;base-uri
    'self';connect-src 'self' grafana.com ws://$ROOT_PATH wss://$ROOT_PATH;manifest-src
    'self';media-src 'none';form-action 'self';\"\"\"\n\n# Controls if old angular
    plugins are supported or not.\n;angular_support_enabled = false\n\n# List of additional
    allowed URLs to pass by the CSRF check, separated by spaces. Suggested when authentication
    comes from an IdP.\n;csrf_trusted_origins = example.com\n\n# List of allowed headers
    to be set by the user, separated by spaces. Suggested to use for if authentication
    lives behind reverse proxies.\n;csrf_additional_headers =\n\n# The CSRF check
    will be executed even if the request has no login cookie.\n;csrf_always_check
    = false\n\n# Comma-separated list of plugins ids that won't be loaded inside the
    frontend sandbox\n;disable_frontend_sandbox_for_plugins =\n\n# Comma-separated
    list of paths for POST/PUT URL in actions. Empty will allow anything that is not
    on the same origin\n;actions_allow_post_url =\n\n[security.encryption]\n# Defines
    the time-to-live (TTL) for decrypted data encryption keys stored in memory (cache).\n#
    Please note that small values may cause performance issues due to a high frequency
    decryption operations.\n;data_keys_cache_ttl = 15m\n\n# Defines the frequency
    of data encryption keys cache cleanup interval.\n# On every interval, decrypted
    data encryption keys that reached the TTL are removed from the cache.\n;data_keys_cache_cleanup_interval
    = 1m\n\n#################################### Snapshots ###########################\n[snapshots]\n#
    set to false to remove snapshot functionality\n;enabled = true\n\n# snapshot sharing
    options\n;external_enabled = true\n;external_snapshot_url = https://snapshots.raintank.io\n;external_snapshot_name
    = Publish to snapshots.raintank.io\n\n# Set to true to enable this Grafana instance
    act as an external snapshot server and allow unauthenticated requests for\n# creating
    and deleting snapshots.\n;public_mode = false\n\n####################################
    Dashboards ##################\n[dashboards]\n# Number dashboard versions to keep
    (per dashboard). Default: 20, Minimum: 1\n;versions_to_keep = 20\n\n# Minimum
    dashboard refresh interval. When set, this will restrict users to set the refresh
    interval of a dashboard lower than given interval. Per default this is 5 seconds.\n#
    The interval string is a possibly signed sequence of decimal numbers, followed
    by a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.\n;min_refresh_interval = 5s\n\n#
    Path to the default home dashboard. If this value is empty, then Grafana uses
    StaticRootPath + \"dashboards/home.json\"\n;default_home_dashboard_path =\n\n###################################
    Data sources #########################\n[datasources]\n# Upper limit of data sources
    that Grafana will return. This limit is a temporary configuration and it will
    be deprecated when pagination will be introduced on the list data sources API.\n;datasource_limit
    = 5000\n\n# Number of queries to be executed concurrently. Only for the datasource
    supports concurrency.\n# For now only Loki and InfluxDB (with influxql) are supporting
    concurrency behind the feature flags.\n# Check datasource documentations for enabling
    concurrency.\n;concurrent_query_count = 10\n\n###################################
    SQL Data Sources #####################\n[sql_datasources]\n# Default maximum number
    of open connections maintained in the connection pool\n# when connecting to SQL
    based data sources\n;max_open_conns_default = 100\n\n# Default maximum number
    of idle connections maintained in the connection pool\n# when connecting to SQL
    based data sources\n;max_idle_conns_default = 100\n\n# Default maximum connection
    lifetime used when connecting\n# to SQL based data sources.\n;max_conn_lifetime_default
    = 14400\n\n#################################### Users ###############################\n[users]\n#
    disable user signup / registration\n;allow_sign_up = true\n\n# Allow non admin
    users to create organizations\n;allow_org_create = true\n\n# Set to true to automatically
    assign new users to the default organization (id 1)\n;auto_assign_org = true\n\n#
    Set this value to automatically add new users to the provided organization (if
    auto_assign_org above is set to true)\n;auto_assign_org_id = 1\n\n# Default role
    new users will be automatically assigned\n;auto_assign_org_role = Viewer\n\n#
    Require email validation before sign up completes\n;verify_email_enabled = false\n\n#
    Redirect to default OrgId after login\n;login_default_org_id =\n\n# Background
    text for the user field on the login page\n;login_hint = email or username\n;password_hint
    = password\n\n# Default UI theme (\"dark\", \"light\" or \"system\")\n;default_theme
    = dark\n\n# Default UI language (supported IETF language tag, such as en-US)\n;default_language
    = en-US\n\n# Path to a custom home page. Users are only redirected to this if
    the default home dashboard is used. It should match a frontend route and contain
    a leading slash.\n;home_page =\n\n# External user management, these options affect
    the organization users view\n;external_manage_link_url =\n;external_manage_link_name
    =\n;external_manage_info =\n\n# Viewers can edit/inspect dashboard settings in
    the browser. But not save the dashboard.\n;viewers_can_edit = false\n\n# Editors
    can administrate dashboard, folders and teams they create\n;editors_can_admin
    = false\n\n# The duration in time a user invitation remains valid before expiring.
    This setting should be expressed as a duration. Examples: 6h (hours), 2d (days),
    1w (week). Default is 24h (24 hours). The minimum supported duration is 15m (15
    minutes).\n;user_invite_max_lifetime_duration = 24h\n\n# The duration in time
    a verification email, used to update the email address of a user, remains valid
    before expiring. This setting should be expressed as a duration. Examples: 6h
    (hours), 2d (days), 1w (week). Default is 1h (1 hour).\n;verification_email_max_lifetime_duration
    = 1h\n\n# Frequency of updating a user's last seen time. The minimum supported
    duration is 5m (5 minutes). The maximum supported duration is 1h (1 hour).\n;last_seen_update_interval
    = 15m\n\n# Enter a comma-separated list of users login to hide them in the Grafana
    UI. These users are shown to Grafana admins and themselves.\n; hidden_users =\n\n[secretscan]\n#
    Enable secretscan feature\n;enabled = false\n\n# Interval to check for token leaks\n;interval
    = 5m\n\n# base URL of the grafana token leak check service\n;base_url = https://secret-scanning.grafana.net\n\n#
    URL to send outgoing webhooks to in case of detection\n;oncall_url =\n\n# Whether
    to revoke the token if a leak is detected or just send a notification\n;revoke
    = true\n\n[service_accounts]\n# Service account maximum expiration date in days.\n#
    When set, Grafana will not allow the creation of tokens with expiry greater than
    this setting.\n; token_expiration_day_limit =\n\n[auth]\n# Login cookie name\n;login_cookie_name
    = grafana_session\n\n# Disable usage of Grafana build-in login solution.\n;disable_login
    = false\n\n# The maximum lifetime (duration) an authenticated user can be inactive
    before being required to login at next visit. Default is 7 days (7d). This setting
    should be expressed as a duration, e.g. 5m (minutes), 6h (hours), 10d (days),
    2w (weeks), 1M (month). The lifetime resets at each successful token rotation.\n;login_maximum_inactive_lifetime_duration
    =\n\n# The maximum lifetime (duration) an authenticated user can be logged in
    since login time before being required to login. Default is 30 days (30d). This
    setting should be expressed as a duration, e.g. 5m (minutes), 6h (hours), 10d
    (days), 2w (weeks), 1M (month).\n;login_maximum_lifetime_duration =\n\n# How often
    should auth tokens be rotated for authenticated users when being active. The default
    is each 10 minutes.\n;token_rotation_interval_minutes = 10\n\n# Set to true to
    disable (hide) the login form, useful if you use OAuth, defaults to false\n;disable_login_form
    = false\n\n# Set to true to disable the sign out link in the side menu. Useful
    if you use auth.proxy or auth.jwt, defaults to false\n;disable_signout_menu =
    false\n\n# URL to redirect the user to after sign out\n;signout_redirect_url =\n\n#
    Set to true to attempt login with OAuth automatically, skipping the login screen.\n#
    This setting is ignored if multiple OAuth providers are configured.\n# Deprecated,
    use auto_login option for specific provider instead.\n;oauth_auto_login = false\n\n#
    Sets a custom oAuth error message. This is useful if you need to point the users
    to a specific location for support.\n;oauth_login_error_message = oauth.login.error\n\n#
    OAuth state max age cookie duration in seconds. Defaults to 600 seconds.\n;oauth_state_cookie_max_age
    = 600\n\n# Minimum wait time in milliseconds for the server lock retry mechanism.\n#
    The server lock retry mechanism is used to prevent multiple Grafana instances
    from\n# simultaneously refreshing OAuth tokens. This mechanism waits at least
    this amount\n# of time before retrying to acquire the server lock. There are 5
    retries in total.\n# The wait time between retries is calculated as random(n,
    n + 500)\n; oauth_refresh_token_server_lock_min_wait_ms = 1000\n\n# limit of api_key
    seconds to live before expiration\n;api_key_max_seconds_to_live = -1\n\n# Set
    to true to enable SigV4 authentication option for HTTP-based datasources.\n;sigv4_auth_enabled
    = false\n\n# Set to true to enable verbose logging of SigV4 request signing\n;sigv4_verbose_logging
    = false\n\n# Set to true to enable Azure authentication option for HTTP-based
    datasources.\n;azure_auth_enabled = false\n\n# Use email lookup in addition to
    the unique ID provided by the IdP\n;oauth_allow_insecure_email_lookup = false\n\n#
    Set to true to include id of identity as a response header\n;id_response_header_enabled
    = false\n\n# Prefix used for the id response header, X-Grafana-Identity-Id\n;id_response_header_prefix
    = X-Grafana\n\n# List of identity namespaces to add id response headers for, separated
    by space.\n# Available namespaces are user, api-key and service-account.\n# The
    header value will encode the namespace (\"user:<id>\", \"api-key:<id>\", \"service-account:<id>\")\n;id_response_header_namespaces
    = user api-key service-account\n\n# Enables the use of managed service accounts
    for plugin authentication\n# This feature currently **only supports single-organization
    deployments**\n; managed_service_accounts_enabled = false\n\n####################################
    Anonymous Auth ######################\n[auth.anonymous]\n# enable anonymous access\n;enabled
    = false\n\n# specify organization name that should be used for unauthenticated
    users\n;org_name = Main Org.\n\n# specify role for unauthenticated users\n;org_role
    = Viewer\n\n# mask the Grafana version number for unauthenticated users\n;hide_version
    = false\n\n# number of devices in total\n;device_limit =\n\n####################################
    GitHub Auth ##########################\n[auth.github]\n;name = GitHub\n;icon =
    github\n;enabled = false\n;allow_sign_up = true\n;auto_login = false\n;client_id
    = some_id\n;client_secret = some_secret\n;scopes = user:email,read:org\n;auth_url
    = https://github.com/login/oauth/authorize\n;token_url = https://github.com/login/oauth/access_token\n;api_url
    = https://api.github.com/user\n;signout_redirect_url =\n;allowed_domains =\n;team_ids
    =\n;allowed_organizations =\n;role_attribute_path =\n;role_attribute_strict =
    false\n;org_mapping =\n;allow_assign_grafana_admin = false\n;skip_org_role_sync
    = false\n;tls_skip_verify_insecure = false\n;tls_client_cert =\n;tls_client_key
    =\n;tls_client_ca =\n# GitHub OAuth apps does not provide refresh tokens and the
    access tokens never expires.\n;use_refresh_token = false\n\n####################################
    GitLab Auth #########################\n[auth.gitlab]\n;name = GitLab\n;icon =
    gitlab\n;enabled = false\n;allow_sign_up = true\n;auto_login = false\n;client_id
    = some_id\n;client_secret = some_secret\n;scopes = openid email profile\n;auth_url
    = https://gitlab.com/oauth/authorize\n;token_url = https://gitlab.com/oauth/token\n;api_url
    = https://gitlab.com/api/v4\n;signout_redirect_url =\n;allowed_domains =\n;allowed_groups
    =\n;role_attribute_path =\n;role_attribute_strict = false\n;org_mapping =\n;allow_assign_grafana_admin
    = false\n;skip_org_role_sync = false\n;tls_skip_verify_insecure = false\n;tls_client_cert
    =\n;tls_client_key =\n;tls_client_ca =\n;use_pkce = true\n;use_refresh_token =
    true\n\n#################################### Google Auth ##########################\n[auth.google]\n;name
    = Google\n;icon = google\n;enabled = false\n;allow_sign_up = true\n;auto_login
    = false\n;client_id = some_client_id\n;client_secret = some_client_secret\n;scopes
    = openid email profile\n;auth_url = https://accounts.google.com/o/oauth2/v2/auth\n;token_url
    = https://oauth2.googleapis.com/token\n;api_url = https://openidconnect.googleapis.com/v1/userinfo\n;signout_redirect_url
    =\n;allowed_domains =\n;validate_hd =\n;hosted_domain =\n;allowed_groups =\n;role_attribute_path
    =\n;role_attribute_strict = false\n;org_mapping =\n;allow_assign_grafana_admin
    = false\n;skip_org_role_sync = false\n;tls_skip_verify_insecure = false\n;tls_client_cert
    =\n;tls_client_key =\n;tls_client_ca =\n;use_pkce = true\n;use_refresh_token =
    true\n\n#################################### Grafana.com Auth ####################\n[auth.grafana_com]\n;name
    = Grafana.com\n;icon = grafana\n;enabled = false\n;allow_sign_up = true\n;auto_login
    = false\n;client_id = some_id\n;client_secret = some_secret\n;scopes = user:email\n;allowed_organizations
    =\n;skip_org_role_sync = false\n;use_refresh_token = false\n\n####################################
    Azure AD OAuth #######################\n[auth.azuread]\n;name = Microsoft\n;icon
    = microsoft\n;enabled = false\n;allow_sign_up = true\n;auto_login = false\n;client_id
    = some_client_id\n;client_secret = some_client_secret\n;scopes = openid email
    profile\n;auth_url = https://login.microsoftonline.com/<tenant-id>/oauth2/v2.0/authorize\n;token_url
    = https://login.microsoftonline.com/<tenant-id>/oauth2/v2.0/token\n;signout_redirect_url
    =\n;allowed_domains =\n;allowed_groups =\n;allowed_organizations =\n;role_attribute_strict
    = false\n;org_mapping =\n;allow_assign_grafana_admin = false\n;use_pkce = true\n#
    prevent synchronizing users organization roles\n;skip_org_role_sync = false\n;use_refresh_token
    = true\n\n#################################### Okta OAuth #######################\n[auth.okta]\n;name
    = Okta\n;enabled = false\n;allow_sign_up = true\n;auto_login = false\n;client_id
    = some_id\n;client_secret = some_secret\n;scopes = openid profile email groups\n;auth_url
    = https://<tenant-id>.okta.com/oauth2/v1/authorize\n;token_url = https://<tenant-id>.okta.com/oauth2/v1/token\n;api_url
    = https://<tenant-id>.okta.com/oauth2/v1/userinfo\n;signout_redirect_url =\n;allowed_domains
    =\n;allowed_groups =\n;role_attribute_path =\n;role_attribute_strict = false\n;
    org_attribute_path =\n; org_mapping =\n;allow_assign_grafana_admin = false\n;skip_org_role_sync
    = false\n;tls_skip_verify_insecure = false\n;tls_client_cert =\n;tls_client_key
    =\n;tls_client_ca =\n;use_pkce = true\n;use_refresh_token = true\n\n####################################
    Generic OAuth ##########################\n[auth.generic_oauth]\nname = OAuth\n;icon
    = signin\nenabled = true\nallow_sign_up = true\n;auto_login = false\nclient_id
    = b4c5f47c-793a-4b25-8f61-931d0d05c9b8\nclient_secret = 8eaecfd6-0fc9-4440-90c5-17a980f39db8\nscopes
    = openid,groups\n;scopes = user:email,read:org\n;empty_scopes = false\n;email_attribute_name
    = email:primary\n;email_attribute_path =\n;login_attribute_path =\nname_attribute_path
    = user_name\n;role_attribute_path =\n;role_attribute_strict = false\n;groups_attribute_path
    =\n;id_token_attribute_name =\n;team_ids_attribute_path\nauth_url = https://sso.ncloud.com/tenants/f11a0c29-c754-4866-82bd-8f9f7f947db2/oauth2/authorize\ntoken_url
    = https://sso.ncloud.com/tenants/f11a0c29-c754-4866-82bd-8f9f7f947db2/oauth2/token\napi_url
    = https://sso.ncloud.com/tenants/f11a0c29-c754-4866-82bd-8f9f7f947db2/oauth2/userinfo\n;signout_redirect_url
    =\n;teams_url =\n;allowed_domains =\n;team_ids =\n;allowed_organizations =\n;org_attribute_path
    =\n;org_mapping =\n;team_ids_attribute_path =\n;tls_skip_verify_insecure = false\n;tls_client_cert
    =\n;tls_client_key =\n;tls_client_ca =\n;use_pkce = false\n;auth_style =\n;allow_assign_grafana_admin
    = false\n;skip_org_role_sync = false\n;use_refresh_token = false\n\n####################################
    Basic Auth ##########################\n[auth.basic]\n;enabled = true\n;password_policy
    = false\n\n#################################### Auth Proxy ##########################\n[auth.proxy]\n;enabled
    = false\n;header_name = X-WEBAUTH-USER\n;header_property = username\n;auto_sign_up
    = true\n;sync_ttl = 60\n;whitelist = 192.168.1.1, 192.168.2.1\n;headers = Email:X-User-Email,
    Name:X-User-Name\n# Non-ASCII strings in header values are encoded using quoted-printable
    encoding\n;headers_encoded = false\n# Read the auth proxy docs for details on
    what the setting below enables\n;enable_login_token = false\n\n####################################
    Auth JWT ##########################\n[auth.jwt]\n;enabled = true\n;enable_login_token
    = false\n;header_name = X-JWT-Assertion\n;email_claim = sub\n;username_claim =
    sub\n;email_attribute_path = jmespath.email\n;username_attribute_path = jmespath.username\n;jwk_set_url
    = https://foo.bar/.well-known/jwks.json\n;jwk_set_file = /path/to/jwks.json\n;cache_ttl
    = 60m\n;expect_claims = {\"aud\": [\"foo\", \"bar\"]}\n;key_file = /path/to/key/file\n#
    Use in conjunction with key_file in case the JWT token's header specifies a key
    ID in \"kid\" field\n;key_id = some-key-id\n;role_attribute_path =\n;role_attribute_strict
    = false\n;groups_attribute_path =\n;auto_sign_up = false\n;url_login = false\n;allow_assign_grafana_admin
    = false\n;skip_org_role_sync = false\n;signout_redirect_url =\n\n####################################
    Auth LDAP ##########################\n[auth.ldap]\n;enabled = false\n;config_file
    = /etc/grafana/ldap.toml\n;allow_sign_up = true\n# prevent synchronizing ldap
    users organization roles\n;skip_org_role_sync = false\n\n# LDAP background sync
    (Enterprise only)\n# At 1 am every day\n;sync_cron = \"0 1 * * *\"\n;active_sync_enabled
    = true\n\n#################################### AWS ###########################\n[aws]\n#
    Enter a comma-separated list of allowed AWS authentication providers.\n# Options
    are: default (AWS SDK Default), keys (Access && secret key), credentials (Credentials
    field), ec2_iam_role (EC2 IAM Role)\n; allowed_auth_providers = default,keys,credentials\n\n#
    Allow AWS users to assume a role using temporary security credentials.\n# If true,
    assume role will be enabled for all AWS authentication providers that are specified
    in aws_auth_providers\n; assume_role_enabled = true\n\n# Specify max no of pages
    to be returned by the ListMetricPages API\n; list_metrics_page_limit = 500\n\n#
    Experimental, for use in Grafana Cloud only. Please do not set.\n; external_id
    =\n\n# Sets the expiry duration of an assumed role.\n# This setting should be
    expressed as a duration. Examples: 6h (hours), 10d (days), 2w (weeks), 1M (month).\n;
    session_duration = \"15m\"\n\n# Set the plugins that will receive AWS settings
    for each request (via plugin context)\n# By default this will include all Grafana
    Labs owned AWS plugins, or those that make use of AWS settings (ElasticSearch,
    Prometheus).\n; forward_settings_to_plugins = cloudwatch, grafana-athena-datasource,
    grafana-redshift-datasource, grafana-x-ray-datasource, grafana-timestream-datasource,
    grafana-iot-sitewise-datasource, grafana-iot-twinmaker-app, grafana-opensearch-datasource,
    aws-datasource-provisioner, elasticsearch, prometheus\n\n####################################
    Azure ###############################\n[azure]\n# Azure cloud environment where
    Grafana is hosted\n# Possible values are AzureCloud, AzureChinaCloud, AzureUSGovernment
    and AzureGermanCloud\n# Default value is AzureCloud (i.e. public cloud)\n;cloud
    = AzureCloud\n\n# A customized list of Azure cloud settings and properties, used
    by data sources which need this information when run in non-standard azure environments\n#
    When specified, this list will replace the default cloud list of AzureCloud, AzureChinaCloud,
    AzureUSGovernment and AzureGermanCloud\n;clouds_config = `[\n;\t\t{\n;\t\t\t\"name\":\"CustomCloud1\",\n;\t\t\t\"displayName\":\"Custom
    Cloud 1\",\n;\t\t\t\"aadAuthority\":\"https://login.cloud1.contoso.com/\",\n;\t\t\t\"properties\":{\n;\t\t\t\t\"azureDataExplorerSuffix\":
    \".kusto.windows.cloud1.contoso.com\",\n;\t\t\t\t\"logAnalytics\":            \"https://api.loganalytics.cloud1.contoso.com\",\n;\t\t\t\t\"portal\":
    \                 \"https://portal.azure.cloud1.contoso.com\",\n;\t\t\t\t\"prometheusResourceId\":
    \   \"https://prometheus.monitor.azure.cloud1.contoso.com\",\n;\t\t\t\t\"resourceManager\":
    \        \"https://management.azure.cloud1.contoso.com\"\n;\t\t\t}\n;\t\t}]`\n\n#
    Specifies whether Grafana hosted in Azure service with Managed Identity configured
    (e.g. Azure Virtual Machines instance)\n# If enabled, the managed identity can
    be used for authentication of Grafana in Azure services\n# Disabled by default,
    needs to be explicitly enabled\n;managed_identity_enabled = false\n\n# Client
    ID to use for user-assigned managed identity\n# Should be set for user-assigned
    identity and should be empty for system-assigned identity\n;managed_identity_client_id
    =\n\n# Specifies whether Azure AD Workload Identity authentication should be enabled
    in datasources that support it\n# For more documentation on Azure AD Workload
    Identity, review this documentation:\n# https://azure.github.io/azure-workload-identity/docs/\n#
    Disabled by default, needs to be explicitly enabled\n;workload_identity_enabled
    = false\n\n# Tenant ID of the Azure AD Workload Identity\n# Allows to override
    default tenant ID of the Azure AD identity associated with the Kubernetes service
    account\n;workload_identity_tenant_id =\n\n# Client ID of the Azure AD Workload
    Identity\n# Allows to override default client ID of the Azure AD identity associated
    with the Kubernetes service account\n;workload_identity_client_id =\n\n# Custom
    path to token file for the Azure AD Workload Identity\n# Allows to set a custom
    path to the projected service account token file\n;workload_identity_token_file
    =\n\n# Specifies whether user identity authentication (on behalf of currently
    signed-in user) should be enabled in datasources\n# that support it (requires
    AAD authentication)\n# Disabled by default, needs to be explicitly enabled\n;user_identity_enabled
    = false\n\n# Specifies whether user identity authentication fallback credentials
    should be enabled in data sources\n# Enabling this allows data source creators
    to provide fallback credentials for backend initiated requests\n# e.g. alerting,
    recorded queries etc.\n# Enabled by default, needs to be explicitly disabled\n#
    Will not have any effect if user identity is disabled above\n;user_identity_fallback_credentials_enabled
    = true\n\n# Override token URL for Azure Active Directory\n# By default is the
    same as token URL configured for AAD authentication settings\n;user_identity_token_url
    =\n\n# Override ADD application ID which would be used to exchange users token
    to an access token for the datasource\n# By default is the same as used in AAD
    authentication or can be set to another application (for OBO flow)\n;user_identity_client_id
    =\n\n# Override the AAD application client secret\n# By default is the same as
    used in AAD authentication or can be set to another application (for OBO flow)\n;user_identity_client_secret
    =\n\n# Allows the usage of a custom token request assertion when Grafana is behind
    an authentication proxy\n# In most cases this will not need to be used. To enable
    this set the value to \"username\"\n# The default is empty and any other value
    will not enable this functionality\n;username_assertion =\n\n# Set the plugins
    that will receive Azure settings for each request (via plugin context)\n# By default
    this will include all Grafana Labs owned Azure plugins, or those that make use
    of Azure settings (Azure Monitor, Azure Data Explorer, Prometheus, MSSQL).\n;forward_settings_to_plugins
    = grafana-azure-monitor-datasource, prometheus, grafana-azure-data-explorer-datasource,
    mssql\n\n# Specifies whether Entra password auth can be used for the MSSQL data
    source\n# Disabled by default, needs to be explicitly enabled\n;azure_entra_password_credentials_enabled
    = false\n\n#################################### Role-based Access Control ###########\n[rbac]\n;permission_cache
    = true\n\n# Reset basic roles permissions on boot\n# Warning left to true, basic
    roles permissions will be reset on every boot\n#reset_basic_roles = false\n\n#
    Validate permissions' action and scope on role creation and update\n; permission_validation_enabled
    = true\n\n#################################### SMTP / Emailing ##########################\n[smtp]\n;enabled
    = false\n;host = localhost:25\n;user =\n# If the password contains # or ; you
    have to wrap it with triple quotes. Ex \"\"\"#password;\"\"\"\n;password =\n;cert_file
    =\n;key_file =\n;skip_verify = false\n;from_address = admin@grafana.localhost\n;from_name
    = Grafana\n# EHLO identity in SMTP dialog (defaults to instance_name)\n;ehlo_identity
    = dashboard.example.com\n# SMTP startTLS policy (defaults to 'OpportunisticStartTLS')\n;startTLS_policy
    = NoStartTLS\n# Enable trace propagation in e-mail headers, using the 'traceparent',
    'tracestate' and (optionally) 'baggage' fields (defaults to false)\n;enable_tracing
    = false\n\n[smtp.static_headers]\n# Include custom static headers in all outgoing
    emails\n;Foo-Header = bar\n;Foo = bar\n\n[emails]\n;welcome_email_on_sign_up =
    false\n;templates_pattern = emails/*.html, emails/*.txt\n;content_types = text/html\n\n####################################
    Logging ##########################\n[log]\n# Either \"console\", \"file\", \"syslog\".
    Default is console and  file\n# Use space to separate multiple modes, e.g. \"console
    file\"\n;mode = console file\n\n# Either \"debug\", \"info\", \"warn\", \"error\",
    \"critical\", default is \"info\"\n;level = info\n\n# optional settings to set
    different levels for specific loggers. Ex filters = sqlstore:debug\n;filters =\nfilters
    = oauth.generic_oauth:debug\n# Set the default error message shown to users. This
    message is displayed instead of sensitive backend errors which should be obfuscated.
    Default is the same as the sample value.\n;user_facing_default_error = \"please
    inspect Grafana server log for details\"\n\n# For \"console\" mode only\n[log.console]\n;level
    =\n\n# log line format, valid options are text, console and json\n;format = console\n\n#
    For \"file\" mode only\n[log.file]\n;level =\n\n# log line format, valid options
    are text, console and json\n;format = text\n\n# This enables automated log rotate(switch
    of following options), default is true\n;log_rotate = true\n\n# Max line number
    of single file, default is 1000000\n;max_lines = 1000000\n\n# Max size shift of
    single file, default is 28 means 1 << 28, 256MB\n;max_size_shift = 28\n\n# Segment
    log daily, default is true\n;daily_rotate = true\n\n# Expired days of log file(delete
    after max days), default is 7\n;max_days = 7\n\n[log.syslog]\n;level =\n\n# log
    line format, valid options are text, console and json\n;format = text\n\n# Syslog
    network type and address. This can be udp, tcp, or unix. If left blank, the default
    unix endpoints will be used.\n;network =\n;address =\n\n# Syslog facility. user,
    daemon and local0 through local7 are valid.\n;facility =\n\n# Syslog tag. By default,
    the process' argv[0] is used.\n;tag =\n\n[log.frontend]\n# Should Faro javascript
    agent be initialized\n;enabled = false\n\n# Custom HTTP endpoint to send events
    to. Default will log the events to stdout.\n;custom_endpoint = /log-grafana-javascript-agent\n\n#
    Requests per second limit enforced an extended period, for Grafana backend log
    ingestion endpoint (/log).\n;log_endpoint_requests_per_second_limit = 3\n\n# Max
    requests accepted per short interval of time for Grafana backend log ingestion
    endpoint (/log).\n;log_endpoint_burst_limit = 15\n\n# Should error instrumentation
    be enabled, only affects Grafana Javascript Agent\n;instrumentations_errors_enabled
    = true\n\n# Should console instrumentation be enabled, only affects Grafana Javascript
    Agent\n;instrumentations_console_enabled = false\n\n# Should webvitals instrumentation
    be enabled, only affects Grafana Javascript Agent\n;instrumentations_webvitals_enabled
    = false\n\n# Should tracing instrumentation be enabled, only affects Grafana Javascript
    Agent\n;instrumentations_tracing_enabled = false\n\n# Api Key, only applies to
    Grafana Javascript Agent provider\n;api_key = testApiKey\n\n####################################
    Usage Quotas ########################\n[quota]\n; enabled = false\n\n#### set
    quotas to -1 to make unlimited. ####\n# limit number of users per Org.\n; org_user
    = 10\n\n# limit number of dashboards per Org.\n; org_dashboard = 100\n\n# limit
    number of data_sources per Org.\n; org_data_source = 10\n\n# limit number of api_keys
    per Org.\n; org_api_key = 10\n\n# limit number of alerts per Org.\n;org_alert_rule
    = 100\n\n# limit number of orgs a user can create.\n; user_org = 10\n\n# Global
    limit of users.\n; global_user = -1\n\n# global limit of orgs.\n; global_org =
    -1\n\n# global limit of dashboards\n; global_dashboard = -1\n\n# global limit
    of api_keys\n; global_api_key = -1\n\n# global limit on number of logged in users.\n;
    global_session = -1\n\n# global limit of alerts\n;global_alert_rule = -1\n\n#
    global limit of files uploaded to the SQL DB\n;global_file = 1000\n\n# global
    limit of correlations\n; global_correlations = -1\n\n# Limit of the number of
    alert rules per rule group.\n# This is not strictly enforced yet, but will be
    enforced over time.\n;alerting_rule_group_rules = 100\n\n# Limit the number of
    query evaluation results per alert rule.\n# If the condition query of an alert
    rule produces more results than this limit,\n# the evaluation results in an error.\n;alerting_rule_evaluation_results
    = -1\n\n#################################### Unified Alerting ####################\n[unified_alerting]\n#Enable
    the Unified Alerting sub-system and interface. When enabled we'll migrate all
    of your alert rules and notification channels to the new system. New alert rules
    will be created and your notification channels will be converted into an Alertmanager
    configuration. Previous data is preserved to enable backwards compatibility but
    new data is removed.```\n;enabled = true\n\n# Comma-separated list of organization
    IDs for which to disable unified alerting. Only supported if unified alerting
    is enabled.\n;disabled_orgs =\n\n# Specify how long to wait for the alerting service
    to initialize\n;initialization_timeout = 30s\n\n# Specify the frequency of polling
    for admin config changes.\n# The interval string is a possibly signed sequence
    of decimal numbers, followed by a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.\n;admin_config_poll_interval
    = 60s\n\n# Specify the frequency of polling for Alertmanager config changes.\n#
    The interval string is a possibly signed sequence of decimal numbers, followed
    by a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.\n;alertmanager_config_poll_interval
    = 60s\n\n\n# Maximum number of active and pending silences that a tenant can have
    at once. Default: 0 (no limit).\n;alertmanager_max_silences_count =\n\n# Maximum
    silence size in bytes. Default: 0 (no limit).\n;alertmanager_max_silence_size_bytes
    =\n\n# Set to true when using redis in cluster mode.\n;ha_redis_cluster_mode_enabled
    = false\n\n# The redis server address(es) that should be connected to.\n# Can
    either be a single address, or if using redis in cluster mode,\n# the cluster
    configuration address or a comma-separated list of addresses.\n;ha_redis_address
    =\n\n# The username that should be used to authenticate with the redis server.\n;ha_redis_username
    =\n\n# The password that should be used to authenticate with the redis server.\n;ha_redis_password
    =\n\n# The redis database, by default it's 0.\n;ha_redis_db =\n\n# A prefix that
    is used for every key or channel that is created on the redis server\n# as part
    of HA for alerting.\n;ha_redis_prefix =\n\n# The name of the cluster peer that
    will be used as identifier. If none is\n# provided, a random one will be generated.\n;ha_redis_peer_name
    =\n\n# The maximum number of simultaneous redis connections.\n# ha_redis_max_conns
    = 5\n\n# Enable TLS on the client used to communicate with the redis server. This
    should be set to true\n# if using any of the other ha_redis_tls_* fields.\n# ha_redis_tls_enabled
    = false\n\n# Path to the PEM-encoded TLS client certificate file used to authenticate
    with the redis server.\n# Required if using Mutual TLS.\n# ha_redis_tls_cert_path
    =\n\n# Path to the PEM-encoded TLS private key file. Also requires the client
    certificate to be configured.\n# Required if using Mutual TLS.\n# ha_redis_tls_key_path
    =\n\n# Path to the PEM-encoded CA certificates file. If not set, the host's root
    CA certificates are used.\n# ha_redis_tls_ca_path =\n\n# Overrides the expected
    name of the redis server certificate.\n# ha_redis_tls_server_name =\n\n# Skips
    validating the redis server certificate.\n# ha_redis_tls_insecure_skip_verify
    =\n\n# Overrides the default TLS cipher suite list.\n# ha_redis_tls_cipher_suites
    =\n\n# Overrides the default minimum TLS version.\n# Allowed values: VersionTLS10,
    VersionTLS11, VersionTLS12, VersionTLS13\n# ha_redis_tls_min_version =\n\n# Listen
    address/hostname and port to receive unified alerting messages for other Grafana
    instances. The port is used for both TCP and UDP. It is assumed other Grafana
    instances are also running on the same port. The default value is `0.0.0.0:9094`.\n;ha_listen_address
    = \"0.0.0.0:9094\"\n\n# Listen address/hostname and port to receive unified alerting
    messages for other Grafana instances. The port is used for both TCP and UDP. It
    is assumed other Grafana instances are also running on the same port. The default
    value is `0.0.0.0:9094`.\n;ha_advertise_address = \"\"\n\n# Comma-separated list
    of initial instances (in a format of host:port) that will form the HA cluster.
    Configuring this setting will enable High Availability mode for alerting.\n;ha_peers
    = \"\"\n\n# Time to wait for an instance to send a notification via the Alertmanager.
    In HA, each Grafana instance will\n# be assigned a position (e.g. 0, 1). We then
    multiply this position with the timeout to indicate how long should\n# each instance
    wait before sending the notification to take into account replication lag.\n#
    The interval string is a possibly signed sequence of decimal numbers, followed
    by a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.\n;ha_peer_timeout = \"15s\"\n\n#
    The label is an optional string to include on each packet and stream.\n# It uniquely
    identifies the cluster and prevents cross-communication\n# issues when sending
    gossip messages in an enviromenet with multiple clusters.\n;ha_label =\n\n# The
    interval between sending gossip messages. By lowering this value (more frequent)
    gossip messages are propagated\n# across cluster more quickly at the expense of
    increased bandwidth usage.\n# The interval string is a possibly signed sequence
    of decimal numbers, followed by a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.\n;ha_gossip_interval
    = \"200ms\"\n\n# Length of time to attempt to reconnect to a lost peer. Recommended
    to be short (<15m) when Grafana is running in a Kubernetes cluster.\n# The string
    is a possibly signed sequence of decimal numbers, followed by a unit suffix (ms,
    s, m, h, d), e.g. 30s or 1m.\n;ha_reconnect_timeout = 6h\n\n# The interval between
    gossip full state syncs. Setting this interval lower (more frequent) will increase
    convergence speeds\n# across larger clusters at the expense of increased bandwidth
    usage.\n# The interval string is a possibly signed sequence of decimal numbers,
    followed by a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.\n;ha_push_pull_interval
    = \"60s\"\n\n# Enable or disable alerting rule execution. The alerting UI remains
    visible.\n;execute_alerts = true\n\n# Alert evaluation timeout when fetching data
    from the datasource.\n# The timeout string is a possibly signed sequence of decimal
    numbers, followed by a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.\n;evaluation_timeout
    = 30s\n\n# Number of times we'll attempt to evaluate an alert rule before giving
    up on that evaluation. The default value is 1.\n;max_attempts = 1\n\n# Minimum
    interval to enforce between rule evaluations. Rules will be adjusted if they are
    less than this value  or if they are not multiple of the scheduler interval (10s).
    Higher values can help with resource management as we'll schedule fewer evaluations
    over time.\n# The interval string is a possibly signed sequence of decimal numbers,
    followed by a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.\n;min_interval = 10s\n\n#
    This is an experimental option to add parallelization to saving alert states in
    the database.\n# It configures the maximum number of concurrent queries per rule
    evaluated. The default value is 1\n# (concurrent queries per rule disabled).\n;max_state_save_concurrency
    = 1\n\n# If the feature flag 'alertingSaveStatePeriodic' is enabled, this is the
    interval that is used to persist the alerting instances to the database.\n# The
    interval string is a possibly signed sequence of decimal numbers, followed by
    a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.\n;state_periodic_save_interval
    = 5m\n\n# Disables the smoothing of alert evaluations across their evaluation
    window.\n# Rules will evaluate in sync.\n;disable_jitter = false\n\n# Retention
    period for Alertmanager notification log entries.\n;notification_log_retention
    = 5d\n\n# Duration for which a resolved alert state transition will continue to
    be sent to the Alertmanager.\n;resolved_alert_retention = 15m\n\n# Defines the
    limit of how many alert rule versions\n# should be stored in the database for
    each alert rule in an organization including the current one.\n# 0 value means
    no limit\n;rule_version_record_limit= 0\n\n[unified_alerting.screenshots]\n# Enable
    screenshots in notifications. You must have either installed the Grafana image
    rendering\n# plugin, or set up Grafana to use a remote rendering service.\n# For
    more information on configuration options, refer to [rendering].\n;capture = false\n\n#
    The timeout for capturing screenshots. If a screenshot cannot be captured within
    the timeout then\n# the notification is sent without a screenshot. The maximum
    duration is 30 seconds. This timeout\n# should be less than the minimum Interval
    of all Evaluation Groups to avoid back pressure on alert\n# rule evaluation.\n;capture_timeout
    = 10s\n\n# The maximum number of screenshots that can be taken at the same time.
    This option is different from\n# concurrent_render_request_limit as max_concurrent_screenshots
    sets the number of concurrent screenshots\n# that can be taken at the same time
    for all firing alerts where as concurrent_render_request_limit sets\n# the total
    number of concurrent screenshots across all Grafana services.\n;max_concurrent_screenshots
    = 5\n\n# Uploads screenshots to the local Grafana server or remote storage such
    as Azure, S3 and GCS. Please\n# see [external_image_storage] for further configuration
    options. If this option is false then\n# screenshots will be persisted to disk
    for up to temp_data_lifetime.\n;upload_external_image_storage = false\n\n[unified_alerting.reserved_labels]\n#
    Comma-separated list of reserved labels added by the Grafana Alerting engine that
    should be disabled.\n# For example: `disabled_labels=grafana_folder`\ndisabled_labels
    =\n\n\n[unified_alerting.reserved_labels]\n# Comma-separated list of reserved
    labels added by the Grafana Alerting engine that should be disabled.\n# For example:
    `disabled_labels=grafana_folder`\n;disabled_labels =\n\n[unified_alerting.state_history]\n#
    Enable the state history functionality in Unified Alerting. The previous states
    of alert rules will be visible in panels and in the UI.\n; enabled = true\n\n#
    Select which pluggable state history backend to use. Either \"annotations\", \"loki\",
    or \"multiple\"\n# \"loki\" writes state history to an external Loki instance.
    \"multiple\" allows history to be written to multiple backends at once.\n# Defaults
    to \"annotations\".\n; backend = \"multiple\"\n\n# For \"multiple\" only.\n# Indicates
    the main backend used to serve state history queries.\n# Either \"annotations\"
    or \"loki\"\n; primary = \"loki\"\n\n# For \"multiple\" only.\n# Comma-separated
    list of additional backends to write state history data to.\n; secondaries = \"annotations\"\n\n#
    For \"loki\" only.\n# URL of the external Loki instance.\n# Either \"loki_remote_url\",
    or both of \"loki_remote_read_url\" and \"loki_remote_write_url\" is required
    for the \"loki\" backend.\n; loki_remote_url = \"http://loki:3100\"\n\n# For \"loki\"
    only.\n# URL of the external Loki's read path. To be used in configurations where
    Loki has separated read and write URLs.\n# Either \"loki_remote_url\", or both
    of \"loki_remote_read_url\" and \"loki_remote_write_url\" is required for the
    \"loki\" backend.\n; loki_remote_read_url = \"http://loki-querier:3100\"\n\n#
    For \"loki\" only.\n# URL of the external Loki's write path. To be used in configurations
    where Loki has separated read and write URLs.\n# Either \"loki_remote_url\", or
    both of \"loki_remote_read_url\" and \"loki_remote_write_url\" is required for
    the \"loki\" backend.\n; loki_remote_write_url = \"http://loki-distributor:3100\"\n\n#
    For \"loki\" only.\n# Optional tenant ID to attach to requests sent to Loki.\n;
    loki_tenant_id = 123\n\n# For \"loki\" only.\n# Optional username for basic authentication
    on requests sent to Loki. Can be left blank to disable basic auth.\n; loki_basic_auth_username
    = \"myuser\"\n\n# For \"loki\" only.\n# Optional password for basic authentication
    on requests sent to Loki. Can be left blank.\n; loki_basic_auth_password = \"mypass\"\n\n#
    For \"loki\" only.\n# Optional max query length for queries sent to Loki. Default
    is 721h which matches the default Loki value.\n; loki_max_query_length = 360h\n\n#
    For \"loki\" only.\n# Maximum size in bytes for queries sent to Loki. This limit
    is applied to user provided filters as well as system defined ones, e.g. applied
    by access control.\n# If filter exceeds the limit, API returns error with code
    \"alerting.state-history.loki.requestTooLong\".\n# Default is 64kb\n;loki_max_query_size
    = 65536\n\n[unified_alerting.state_history.external_labels]\n# Optional extra
    labels to attach to outbound state history records or log streams.\n# Any number
    of label key-value-pairs can be provided.\n; mylabelkey = mylabelvalue\n\n[unified_alerting.state_history.annotations]\n#
    This section controls retention of annotations automatically created while evaluating
    alert rules\n# when alerting state history backend is configured to be annotations
    (a setting [unified_alerting.state_history].backend\n\n# Configures for how long
    alert annotations are stored. Default is 0, which keeps them forever.\n# This
    setting should be expressed as an duration. Ex 6h (hours), 10d (days), 2w (weeks),
    1M (month).\nmax_age =\n\n# Configures max number of alert annotations that Grafana
    stores. Default value is 0, which keeps all alert annotations.\nmax_annotations_to_keep
    =\n\n#################################### Recording Rules #####################\n[recording_rules]\n#
    Enable recording rules. You must provide write credentials below.\nenabled = false\n\n#
    Target URL (including write path) for recording rules.\nurl =\n\n# Optional username
    for basic authentication on recording rule write requests. Can be left blank to
    disable basic auth\nbasic_auth_username =\n\n# Optional assword for basic authentication
    on recording rule write requests. Can be left blank.\nbasic_auth_password =\n\n#
    Request timeout for recording rule writes.\ntimeout = 30s\n\n# Optional custom
    headers to include in recording rule write requests.\n[recording_rules.custom_headers]\n#
    exampleHeader = exampleValue\n\n#################################### Annotations
    #########################\n[annotations]\n# Configures the batch size for the
    annotation clean-up job. This setting is used for dashboard, API, and alert annotations.\n;cleanupjob_batchsize
    = 100\n\n# Enforces the maximum allowed length of the tags for any newly introduced
    annotations. It can be between 500 and 4096 inclusive (which is the respective's
    column length). Default value is 500.\n# Setting it to a higher value would impact
    performance therefore is not recommended.\n;tags_length = 500\n\n[annotations.dashboard]\n#
    Dashboard annotations means that annotations are associated with the dashboard
    they are created on.\n\n# Configures how long dashboard annotations are stored.
    Default is 0, which keeps them forever.\n# This setting should be expressed as
    a duration. Examples: 6h (hours), 10d (days), 2w (weeks), 1M (month).\n;max_age
    =\n\n# Configures max number of dashboard annotations that Grafana stores. Default
    value is 0, which keeps all dashboard annotations.\n;max_annotations_to_keep =\n\n[annotations.api]\n#
    API annotations means that the annotations have been created using the API without
    any\n# association with a dashboard.\n\n# Configures how long Grafana stores API
    annotations. Default is 0, which keeps them forever.\n# This setting should be
    expressed as a duration. Examples: 6h (hours), 10d (days), 2w (weeks), 1M (month).\n;max_age
    =\n\n# Configures max number of API annotations that Grafana keeps. Default value
    is 0, which keeps all API annotations.\n;max_annotations_to_keep =\n\n####################################
    Explore #############################\n[explore]\n# Enable the Explore section\n;enabled
    = true\n\n#################################### Help #############################\n[help]\n#
    Enable the Help section\n;enabled = true\n\n####################################
    Profile #############################\n[profile]\n# Enable the Profile section\n;enabled
    = true\n\n#################################### News #############################\n[news]\n#
    Enable the news feed section\n; news_feed_enabled = true\n\n####################################
    Query #############################\n[query]\n# Set the number of data source
    queries that can be executed concurrently in mixed queries. Default is the number
    of CPUs.\n;concurrent_query_limit =\n\n#################################### Query
    History #############################\n[query_history]\n# Enable the Query history\n;enabled
    = true\n\n#################################### Short Links #############################\n[short_links]\n#
    Short links which are never accessed will be deleted as cleanup. Time is in days.
    Default is 7 days. Max is 365. 0 means they will be deleted approximately every
    10 minutes.\n;expire_time = 7\n\n#################################### Internal
    Grafana Metrics ##########################\n# Metrics available at HTTP URL /metrics
    and /metrics/plugins/:pluginId\n[metrics]\n# Disable / Enable internal metrics\n;enabled
    \          = true\n# Graphite Publish interval\n;interval_seconds  = 10\n# Disable
    total stats (stat_totals_*) metrics to be generated\n;disable_total_stats = false\n#
    The interval at which the total stats collector will update the stats. Default
    is 1800 seconds.\n;total_stats_collector_interval_seconds = 1800\n\n#If both are
    set, basic auth will be required for the metrics endpoints.\n; basic_auth_username
    =\n; basic_auth_password =\n\n# Metrics environment info adds dimensions to the
    `grafana_environment_info` metric, which\n# can expose more information about
    the Grafana instance.\n[metrics.environment_info]\n#exampleLabel1 = exampleValue1\n#exampleLabel2
    = exampleValue2\n\n# Send internal metrics to Graphite\n[metrics.graphite]\n#
    Enable by setting the address setting (ex localhost:2003)\n;address =\n;prefix
    = prod.grafana.%(instance_name)s.\n\n#################################### Grafana.com
    integration  ##########################\n# Url used to import dashboards directly
    from Grafana.com\n[grafana_com]\n;url = https://grafana.com\n;api_url = https://grafana.com/api\n#
    Grafana instance - Grafana.com integration SSO API token\n;sso_api_token = \"\"\n\n####################################
    Distributed tracing ############\n# Opentracing is deprecated use opentelemetry
    instead\n[tracing.jaeger]\n# Enable by setting the address sending traces to jaeger
    (ex localhost:6831)\n;address = localhost:6831\n# Tag that will always be included
    in when creating new spans. ex (tag1:value1,tag2:value2)\n;always_included_tag
    = tag1:value1\n# Type specifies the type of the sampler: const, probabilistic,
    rateLimiting, or remote\n;sampler_type = const\n# jaeger samplerconfig param\n#
    for \"const\" sampler, 0 or 1 for always false/true respectively\n# for \"probabilistic\"
    sampler, a probability between 0 and 1\n# for \"rateLimiting\" sampler, the number
    of spans per second\n# for \"remote\" sampler, param is the same as for \"probabilistic\"\n#
    and indicates the initial sampling rate before the actual one\n# is received from
    the mothership\n;sampler_param = 1\n# sampling_server_url is the URL of a sampling
    manager providing a sampling strategy.\n;sampling_server_url =\n# Whether or not
    to use Zipkin propagation (x-b3- HTTP headers).\n;zipkin_propagation = false\n#
    Setting this to true disables shared RPC spans.\n# Not disabling is the most common
    setting when using Zipkin elsewhere in your infrastructure.\n;disable_shared_zipkin_spans
    = false\n\n[tracing.opentelemetry]\n# attributes that will always be included
    in when creating new spans. ex (key1:value1,key2:value2)\n;custom_attributes =
    key1:value1,key2:value2\n# Type specifies the type of the sampler: const, probabilistic,
    rateLimiting, or remote\n; sampler_type = remote\n# Sampler configuration parameter\n#
    for \"const\" sampler, 0 or 1 for always false/true respectively\n# for \"probabilistic\"
    sampler, a probability between 0.0 and 1.0\n# for \"rateLimiting\" sampler, the
    number of spans per second\n# for \"remote\" sampler, param is the same as for
    \"probabilistic\"\n#   and indicates the initial sampling rate before the actual
    one\n#   is received from the sampling server (set at sampling_server_url)\n;
    sampler_param = 0.5\n# specifies the URL of the sampling server when sampler_type
    is remote\n; sampling_server_url = http://localhost:5778/sampling\n\n[tracing.opentelemetry.jaeger]\n#
    jaeger destination (ex http://localhost:14268/api/traces)\n; address = http://localhost:14268/api/traces\n#
    Propagation specifies the text map propagation format: w3c, jaeger\n; propagation
    = jaeger\n\n# This is a configuration for OTLP exporter with GRPC protocol\n[tracing.opentelemetry.otlp]\n#
    otlp destination (ex localhost:4317)\n; address = localhost:4317\n# Propagation
    specifies the text map propagation format: w3c, jaeger\n; propagation = w3c\n\n####################################
    External image storage ##########################\n[external_image_storage]\n#
    Used for uploading images to public servers so they can be included in slack/email
    messages.\n# you can choose between (s3, webdav, gcs, azure_blob, local)\n;provider
    =\n\n[external_image_storage.s3]\n;endpoint =\n;path_style_access =\n;bucket =\n;region
    =\n;path =\n;access_key =\n;secret_key =\n\n[external_image_storage.webdav]\n;url
    =\n;username =\n;password =\n;public_url =\n\n[external_image_storage.gcs]\n;key_file
    =\n;bucket =\n;path =\n;enable_signed_urls = false\n;signed_url_expiration =\n\n[external_image_storage.azure_blob]\n;account_name
    =\n;account_key =\n;container_name =\n;sas_token_expiration_days =\n\n[external_image_storage.local]\n#
    does not require any configuration\n\n[rendering]\n# Options to configure a remote
    HTTP image rendering service, e.g. using https://github.com/grafana/grafana-image-renderer.\n#
    URL to a remote HTTP image renderer service, e.g. http://localhost:8081/render,
    will enable Grafana to render panels and dashboards to PNG-images using HTTP requests
    to an external service.\n;server_url =\n# If the remote HTTP image renderer service
    runs on a different server than the Grafana server you may have to configure this
    to a URL where Grafana is reachable, e.g. http://grafana.domain/.\n;callback_url
    =\n# An auth token that will be sent to and verified by the renderer. The renderer
    will deny any request without an auth token matching the one configured on the
    renderer side.\n;renderer_token = -\n# Concurrent render request limit affects
    when the /render HTTP endpoint is used. Rendering many images at the same time
    can overload the server,\n# which this setting can help protect against by only
    allowing a certain amount of concurrent requests.\n;concurrent_render_request_limit
    = 30\n# Determines the lifetime of the render key used by the image renderer to
    access and render Grafana.\n# This setting should be expressed as a duration.
    Examples: 10s (seconds), 5m (minutes), 2h (hours).\n# Default is 5m. This should
    be more than enough for most deployments.\n# Change the value only if image rendering
    is failing and you see `Failed to get the render key from cache` in Grafana logs.\n;render_key_lifetime
    = 5m\n# Default width for panel screenshot\n;default_image_width = 1000\n# Default
    height for panel screenshot\n;default_image_height = 500\n# Default scale for
    panel screenshot\n;default_image_scale = 1\n\n[panels]\n# If set to true Grafana
    will allow script tags in text panels. Not recommended as it enable XSS vulnerabilities.\n;disable_sanitize_html
    = false\n\n[plugins]\n;enable_alpha = false\n;app_tls_skip_verify_insecure = false\n#
    Enter a comma-separated list of plugin identifiers to identify plugins to load
    even if they are unsigned. Plugins with modified signatures are never loaded.\n;allow_loading_unsigned_plugins
    =\n# Enable or disable installing / uninstalling / updating plugins directly from
    within Grafana.\n;plugin_admin_enabled = false\n;plugin_admin_external_manage_enabled
    = false\n;plugin_catalog_url = https://grafana.com/grafana/plugins/\n# Enter a
    comma-separated list of plugin identifiers to hide in the plugin catalog.\n;plugin_catalog_hidden_plugins
    =\n# Log all backend requests for core and external plugins.\n;log_backend_requests
    = false\n# Disable download of the public key for verifying plugin signature.\n;
    public_key_retrieval_disabled = false\n# Force download of the public key for
    verifying plugin signature on startup. If disabled, the public key will be retrieved
    every 10 days.\n# Requires public_key_retrieval_disabled to be false to have any
    effect.\n; public_key_retrieval_on_startup = false\n# Enter a comma-separated
    list of plugin identifiers to avoid loading (including core plugins). These plugins
    will be hidden in the catalog.\n; disable_plugins =\n\n####################################
    Grafana Live ##########################################\n[live]\n# max_connections
    to Grafana Live WebSocket endpoint per Grafana server instance. See Grafana Live
    docs\n# if you are planning to make it higher than default 100 since this can
    require some OS and infrastructure\n# tuning. 0 disables Live, -1 means unlimited
    connections.\n;max_connections = 100\n\n# allowed_origins is a comma-separated
    list of origins that can establish connection with Grafana Live.\n# If not set
    then origin will be matched over root_url. Supports wildcard symbol \"*\".\n;allowed_origins
    =\n\n# engine defines an HA (high availability) engine to use for Grafana Live.
    By default no engine used - in\n# this case Live features work only on a single
    Grafana server. Available options: \"redis\".\n# Setting ha_engine is an EXPERIMENTAL
    feature.\n;ha_engine =\n\n# ha_engine_address sets a connection address for Live
    HA engine. Depending on engine type address format can differ.\n# For now we only
    support Redis connection address in \"host:port\" format.\n# This option is EXPERIMENTAL.\n;ha_engine_address
    = \"127.0.0.1:6379\"\n\n# ha_engine_password allows setting an optional password
    to authenticate with the engine\n;ha_engine_password = \"\"\n\n# ha_prefix is
    a prefix for keys in the HA engine. It's used to separate keys for different Grafana
    instances.\n;ha_prefix =\n\n#################################### Grafana Image
    Renderer Plugin ##########################\n[plugin.grafana-image-renderer]\n#
    Instruct headless browser instance to use a default timezone when not provided
    by Grafana, e.g. when rendering panel image of alert.\n# See ICU’s metaZones.txt
    (https://cs.chromium.org/chromium/src/third_party/icu/source/data/misc/metaZones.txt)
    for a list of supported\n# timezone IDs. Fallbacks to TZ environment variable
    if not set.\n;rendering_timezone =\n\n# Instruct headless browser instance to
    use a default language when not provided by Grafana, e.g. when rendering panel
    image of alert.\n# Please refer to the HTTP header Accept-Language to understand
    how to format this value, e.g. 'fr-CH, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5'.\n;rendering_language
    =\n\n# Instruct headless browser instance to use a default device scale factor
    when not provided by Grafana, e.g. when rendering panel image of alert.\n# Default
    is 1. Using a higher value will produce more detailed images (higher DPI), but
    will require more disk space to store an image.\n;rendering_viewport_device_scale_factor
    =\n\n# Instruct headless browser instance whether to ignore HTTPS errors during
    navigation. Per default HTTPS errors are not ignored. Due to\n# the security risk
    it's not recommended to ignore HTTPS errors.\n;rendering_ignore_https_errors =\n\n#
    Instruct headless browser instance whether to capture and log verbose information
    when rendering an image. Default is false and will\n# only capture and log error
    messages. When enabled, debug messages are captured and logged as well.\n# For
    the verbose information to be included in the Grafana server log you have to adjust
    the rendering log level to debug, configure\n# [log].filter = rendering:debug.\n;rendering_verbose_logging
    =\n\n# Instruct headless browser instance whether to output its debug and error
    messages into running process of remote rendering service.\n# Default is false.
    This can be useful to enable (true) when troubleshooting.\n;rendering_dumpio =\n\n#
    Instruct headless browser instance whether to register metrics for the duration
    of every rendering step. Default is false.\n# This can be useful to enable (true)
    when optimizing the rendering mode settings to improve the plugin performance
    or when troubleshooting.\n;rendering_timing_metrics =\n\n# Additional arguments
    to pass to the headless browser instance. Default is --no-sandbox. The list of
    Chromium flags can be found\n# here (https://peter.sh/experiments/chromium-command-line-switches/).
    Multiple arguments is separated with comma-character.\n;rendering_args =\n\n#
    You can configure the plugin to use a different browser binary instead of the
    pre-packaged version of Chromium.\n# Please note that this is not recommended,
    since you may encounter problems if the installed version of Chrome/Chromium is
    not\n# compatible with the plugin.\n;rendering_chrome_bin =\n\n# Instruct how
    headless browser instances are created. Default is 'default' and will create a
    new browser instance on each request.\n# Mode 'clustered' will make sure that
    only a maximum of browsers/incognito pages can execute concurrently.\n# Mode 'reusable'
    will have one browser instance and will create a new incognito page on each request.\n;rendering_mode
    =\n\n# When rendering_mode = clustered, you can instruct how many browsers or
    incognito pages can execute concurrently. Default is 'browser'\n# and will cluster
    using browser instances.\n# Mode 'context' will cluster using incognito pages.\n;rendering_clustering_mode
    =\n# When rendering_mode = clustered, you can define the maximum number of browser
    instances/incognito pages that can execute concurrently. Default is '5'.\n;rendering_clustering_max_concurrency
    =\n# When rendering_mode = clustered, you can specify the duration a rendering
    request can take before it will time out. Default is `30` seconds.\n;rendering_clustering_timeout
    =\n\n# Limit the maximum viewport width, height and device scale factor that can
    be requested.\n;rendering_viewport_max_width =\n;rendering_viewport_max_height
    =\n;rendering_viewport_max_device_scale_factor =\n\n# Change the listening host
    and port of the gRPC server. Default host is 127.0.0.1 and default port is 0 and
    will automatically assign\n# a port not in use.\n;grpc_host =\n;grpc_port =\n\n[enterprise]\n#
    Path to a valid Grafana Enterprise license.jwt file\n;license_path =\n\n[feature_toggles]\n#
    there are currently two ways to enable feature toggles in the `grafana.ini`.\n#
    you can either pass an array of feature you want to enable to the `enable` field
    or\n# configure each toggle by setting the name of the toggle to true/false. Toggles
    set to true/false\n# will take presidence over toggles in the `enable` list.\n\n;enable
    = feature1,feature2\n\n;feature1 = true\n;feature2 = false\n\n[date_formats]\n#
    For information on what formatting patterns that are supported https://momentjs.com/docs/#/displaying/\n\n#
    Default system date format used in time range picker and other places where full
    time is displayed\n;full_date = YYYY-MM-DD HH:mm:ss\n\n# Used by graph and other
    places where we only show small intervals\n;interval_second = HH:mm:ss\n;interval_minute
    = HH:mm\n;interval_hour = MM/DD HH:mm\n;interval_day = MM/DD\n;interval_month
    = YYYY-MM\n;interval_year = YYYY\n\n# Experimental feature\n;use_browser_locale
    = false\n\n# Default timezone for user preferences. Options are 'browser' for
    the browser local timezone or a timezone name from IANA Time Zone database, e.g.
    'UTC' or 'Europe/Amsterdam' etc.\n;default_timezone = browser\n\n[expressions]\n#
    Enable or disable the expressions functionality.\n;enabled = true\n\n[geomap]\n#
    Set the JSON configuration for the default basemap\n;default_baselayer_config
    = `{\n;  \"type\": \"xyz\",\n;  \"config\": {\n;    \"attribution\": \"Open street
    map\",\n;    \"url\": \"https://tile.openstreetmap.org/{z}/{x}/{y}.png\"\n;  }\n;}`\n\n#
    Enable or disable loading other base map layers\n;enable_custom_baselayers = true\n\n####################################
    Support Bundles #####################################\n[support_bundles]\n# Enable
    support bundle creation (default: true)\n#enabled = true\n# Only server admins
    can generate and view support bundles (default: true)\n#server_admin_only = true\n#
    If set, bundles will be encrypted with the provided public keys separated by whitespace\n#public_keys
    = \"\"\n\n# Move an app plugin referenced by its id (including all its pages)
    to a specific navigation section\n[navigation.app_sections]\n# The following will
    move an app plugin with the id of `my-app-id` under the `cfg` section\n# my-app-id
    = cfg\n\n# Move a specific app plugin page (referenced by its `path` field) to
    a specific navigation section\n[navigation.app_standalone_pages]\n# The following
    will move the page with the path \"/a/my-app-id/my-page\" from `my-app-id` to
    the `cfg` section\n# /a/my-app-id/my-page = cfg\n\n####################################
    Secure Socks5 Datasource Proxy #####################################\n[secure_socks_datasource_proxy]\n;
    enabled = false\n; root_ca_cert =\n; client_key =\n; client_cert =\n; server_name
    =\n# The address of the socks5 proxy datasources should connect to\n; proxy_address
    =\n; show_ui = true\n; allow_insecure = false\n\n##################################
    Feature Management ##############################################\n[feature_management]\n#
    Options to configure the experimental Feature Toggle Admin Page feature, which
    is behind the `featureToggleAdminPage` feature toggle. Use at your own risk.\n#
    Allow editing of feature toggles in the feature management page\n;allow_editing
    = false\n# Allow customization of URL for the controller that manages feature
    toggles\n;update_webhook =\n# Allow configuring an auth token for feature management
    update requests\n;update_webhook_token =\n# Hide specific feature toggles from
    the feature management page\n;hidden_toggles =\n# Disable updating specific feature
    toggles in the feature management page\n;read_only_toggles =\n\n####################################
    Public Dashboards #####################################\n[public_dashboards]\n#
    Set to false to disable public dashboards\n;enabled = true\n\n######################################
    Cloud Migration ######################################\n[cloud_migration]\n# Set
    to true to enable target-side migration UI\n;is_target = false\n# Token used to
    send requests to grafana com\n;gcom_api_token = \"\"\n# How long to wait for a
    request sent to gms to start a snapshot to complete\n;start_snapshot_timeout =
    5s\n# How long to wait for a request sent to gms to validate a key to complete\n;validate_key_timeout
    = 5s\n# How long to wait for a request sent to gms to get a snapshot status to
    complete\n;get_snapshot_status_timeout = 5s\n# How long to wait for a request
    sent to gms to create a presigned upload url\n;create_upload_url_timeout = 5s\n#
    How long to wait for a request sent to gms to report an event\n;report_event_timeout
    = 5s\n# How long to wait for a request to fetch an instance to complete\n;fetch_instance_timeout
    = 5s\n# How long to wait for a request to create an access policy to complete\n;create_access_policy_timeout
    = 5s\n# How long to wait for a request to create to fetch an access policy to
    complete\n;fetch_access_policy_timeout = 5s\n# How long to wait for a request
    to create to delete an access policy to complete\n;delete_access_policy_timeout
    = 5s\n# The domain name used to access cms\n;domain = grafana-dev.net\n# Folder
    used to store snapshot files. Defaults to the home dir\n;snapshot_folder = \"\"\n#
    Link to form to give feedback on the feature\n;feedback_url = \"\"\n# How frequently
    should the frontend UI poll for changes while resources are migrating\n;frontend_poll_interval
    = 2s\n\n################################## Frontend development configuration
    ###################################\n# Warning! Any settings placed in this section
    will be available on `process.env.frontend_dev_{foo}` within frontend code\n#
    Any values placed here may be accessible to the UI. Do not place sensitive information
    here.\n[frontend_dev]\n# Should UI tests fail when console log/warn/erroring?\n#
    Does not affect the result when running on CI - only for allowing devs to choose
    this behaviour locally\n; fail_tests_on_console = true\n"
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: grafana-ini
  namespace: monitoring
~~~

~~~
##################### Grafana Configuration Example #####################
#
# Everything has defaults so you only need to uncomment things you want to
# change

# possible values : production, development
;app_mode = production

# instance name, defaults to HOSTNAME environment variable value or hostname if HOSTNAME var is empty
;instance_name = ${HOSTNAME}

#################################### Paths ####################################
[paths]
# Path to where grafana can store temp files, sessions, and the sqlite3 db (if that is used)
;data = /var/lib/grafana

# Temporary files in `data` directory older than given duration will be removed
;temp_data_lifetime = 24h

# Directory where grafana can store logs
;logs = /var/log/grafana

# Directory where grafana will automatically scan and look for plugins
;plugins = /var/lib/grafana/plugins

# folder that contains provisioning config files that grafana will apply on startup and while running.
;provisioning = conf/provisioning

#################################### Server ####################################
[server]
# Protocol (http, https, h2, socket)
;protocol = http

# Minimum TLS version allowed. By default, this value is empty. Accepted values are: TLS1.2, TLS1.3. If nothing is set TLS1.2 would be taken
;min_tls_version = ""

# The ip address to bind to, empty will bind to all interfaces
;http_addr =

# The http port to use
;http_port = 80

# The public facing domain name used to access grafana from a browser
;domain = grafana.test.local

# Redirect to correct domain if host header does not match domain
# Prevents DNS rebinding attacks
;enforce_domain = false

# The full public facing url you use in browser, used for redirects and emails
# If you use reverse proxy and sub path specify full url (with sub path)
;root_url = https://humble-jaybird-partly.ngrok-free.app

# Serve Grafana from subpath specified in `root_url` setting. By default it is set to `false` for compatibility reasons.
;serve_from_sub_path = false

# Log web requests
;router_logging = false

# the path relative working path
;static_root_path = public

# enable gzip
;enable_gzip = false

# https certs & key file
;cert_file =
;cert_key =

# optional password to be used to decrypt key file
;cert_pass =

# Certificates file watch interval
;certs_watch_interval =

# Unix socket gid
# Changing the gid of a file without privileges requires that the target group is in the group of the process and that the process is the file owner
# It is recommended to set the gid as http server user gid
# Not set when the value is -1
;socket_gid =

# Unix socket mode
;socket_mode =

# Unix socket path
;socket =

# CDN Url
;cdn_url =

# Sets the maximum time using a duration format (5s/5m/5ms) before timing out read of an incoming request and closing idle connections.
# `0` means there is no timeout for reading the request.
;read_timeout = 0

# This setting enables you to specify additional headers that the server adds to HTTP(S) responses.
[server.custom_response_headers]
#exampleHeader1 = exampleValue1
#exampleHeader2 = exampleValue2

[environment]
# Sets whether the local file system is available for Grafana to use. Default is true for backward compatibility.
;local_file_system_available = true

#################################### GRPC Server #########################
;[grpc_server]
;network = "tcp"
;address = "127.0.0.1:10000"
;use_tls = false
;cert_file =
;key_file =
;max_recv_msg_size =
;max_send_msg_size =
# this will log the request and response for each unary gRPC call
;enable_logging = false

#################################### Database ####################################
[database]
# You can configure the database connection by specifying type, host, name, user and password
# as separate properties or as on string using the url properties.

# Either "mysql", "postgres" or "sqlite3", it's your choice
;type = sqlite3
;host = 127.0.0.1:3306
;name = grafana
;user = root
# If the password contains # or ; you have to wrap it with triple quotes. Ex """#password;"""
;password =
# Use either URL or the previous fields to configure the database
# Example: mysql://user:secret@host:port/database
;url =

# Max idle conn setting default is 2
;max_idle_conn = 2

# Max conn setting default is 0 (mean not set)
;max_open_conn =

# Connection Max Lifetime default is 14400 (means 14400 seconds or 4 hours)
;conn_max_lifetime = 14400

# Set to true to log the sql calls and execution times.
;log_queries =

# For "postgres", use either "disable", "require" or "verify-full"
# For "mysql", use either "true", "false", or "skip-verify".
;ssl_mode = disable

# For "postgres", use either "1" to enable or "0" to disable SNI
;ssl_sni =

# Database drivers may support different transaction isolation levels.
# Currently, only "mysql" driver supports isolation levels.
# If the value is empty - driver's default isolation level is applied.
# For "mysql" use "READ-UNCOMMITTED", "READ-COMMITTED", "REPEATABLE-READ" or "SERIALIZABLE".
;isolation_level =

;ca_cert_path =
;client_key_path =
;client_cert_path =
;server_cert_name =

# For "sqlite3" only, path relative to data_path setting
;path = grafana.db

# For "sqlite3" only. cache mode setting used for connecting to the database. (private, shared)
;cache_mode = private

# For "sqlite3" only. Enable/disable Write-Ahead Logging, https://sqlite.org/wal.html. Default is false.
;wal = false

# For "mysql" and "postgres" only. Lock the database for the migrations, default is true.
;migration_locking = true

# For "mysql" and "postgres" only. How many seconds to wait before failing to lock the database for the migrations, default is 0.
;locking_attempt_timeout_sec = 0

# For "sqlite" only. How many times to retry query in case of database is locked failures. Default is 0 (disabled).
;query_retries = 0

# For "sqlite" only. How many times to retry transaction in case of database is locked failures. Default is 5.
;transaction_retries = 5

# Set to true to add metrics and tracing for database queries.
;instrument_queries = false

#################################### Cache server #############################
[remote_cache]
# Either "redis", "memcached" or "database" default is "database"
;type = database

# cache connectionstring options
# database: will use Grafana primary database.
# redis: config like redis server e.g. `addr=127.0.0.1:6379,pool_size=100,db=0,ssl=false`. Only addr is required. ssl may be 'true', 'false', or 'insecure'.
# memcache: 127.0.0.1:11211
;connstr =

# prefix prepended to all the keys in the remote cache
; prefix =

# This enables encryption of values stored in the remote cache
;encryption =

#################################### Data proxy ###########################
[dataproxy]

# This enables data proxy logging, default is false
;logging = false

# How long the data proxy waits to read the headers of the response before timing out, default is 30 seconds.
# This setting also applies to core backend HTTP data sources where query requests use an HTTP client with timeout set.
;timeout = 30

# How long the data proxy waits to establish a TCP connection before timing out, default is 10 seconds.
;dialTimeout = 10

# How many seconds the data proxy waits before sending a keepalive probe request.
;keep_alive_seconds = 30

# How many seconds the data proxy waits for a successful TLS Handshake before timing out.
;tls_handshake_timeout_seconds = 10

# How many seconds the data proxy will wait for a server's first response headers after
# fully writing the request headers if the request has an "Expect: 100-continue"
# header. A value of 0 will result in the body being sent immediately, without
# waiting for the server to approve.
;expect_continue_timeout_seconds = 1

# Optionally limits the total number of connections per host, including connections in the dialing,
# active, and idle states. On limit violation, dials will block.
# A value of zero (0) means no limit.
;max_conns_per_host = 0

# The maximum number of idle connections that Grafana will keep alive.
;max_idle_connections = 100

# How many seconds the data proxy keeps an idle connection open before timing out.
;idle_conn_timeout_seconds = 90

# If enabled and user is not anonymous, data proxy will add X-Grafana-User header with username into the request, default is false.
;send_user_header = false

# Limit the amount of bytes that will be read/accepted from responses of outgoing HTTP requests.
;response_limit = 0

# Limits the number of rows that Grafana will process from SQL data sources.
;row_limit = 1000000

# Sets a custom value for the `User-Agent` header for outgoing data proxy requests. If empty, the default value is `Grafana/<BuildVersion>` (for example `Grafana/9.0.0`).
;user_agent =

#################################### Analytics ####################################
[analytics]
# Server reporting, sends usage counters to stats.grafana.org every 24 hours.
# No ip addresses are being tracked, only simple counters to track
# running instances, dashboard and error counts. It is very helpful to us.
# Change this option to false to disable reporting.
;reporting_enabled = true

# The name of the distributor of the Grafana instance. Ex hosted-grafana, grafana-labs
;reporting_distributor = grafana-labs

# Set to false to disable all checks to https://grafana.com
# for new versions of grafana. The check is used
# in some UI views to notify that a grafana update exists.
# This option does not cause any auto updates, nor send any information
# only a GET request to https://grafana.com/api/grafana/versions/stable to get the latest version.
;check_for_updates = true

# Set to false to disable all checks to https://grafana.com
# for new versions of plugins. The check is used
# in some UI views to notify that a plugin update exists.
# This option does not cause any auto updates, nor send any information
# only a GET request to https://grafana.com to get the latest versions.
;check_for_plugin_updates = true

# Google Analytics universal tracking code, only enabled if you specify an id here
;google_analytics_ua_id =

# Google Analytics 4 tracking code, only enabled if you specify an id here
;google_analytics_4_id =

# When Google Analytics 4 Enhanced event measurement is enabled, we will try to avoid sending duplicate events and let Google Analytics 4 detect navigation changes, etc.
;google_analytics_4_send_manual_page_views = false

# Google Tag Manager ID, only enabled if you specify an id here
;google_tag_manager_id =

# Rudderstack write key, enabled only if rudderstack_data_plane_url is also set
;rudderstack_write_key =

# Rudderstack data plane url, enabled only if rudderstack_write_key is also set
;rudderstack_data_plane_url =

# Rudderstack SDK url, optional, only valid if rudderstack_write_key and rudderstack_data_plane_url is also set
;rudderstack_sdk_url =

# Rudderstack Config url, optional, used by Rudderstack SDK to fetch source config
;rudderstack_config_url =

# Rudderstack Integrations URL, optional. Only valid if you pass the SDK version 1.1 or higher
;rudderstack_integrations_url =

# Intercom secret, optional, used to hash user_id before passing to Intercom via Rudderstack
;intercom_secret =

# Application Insights connection string. Specify an URL string to enable this feature.
;application_insights_connection_string =

# Optional. Specifies an Application Insights endpoint URL where the endpoint string is wrapped in backticks ``.
;application_insights_endpoint_url =

# Controls if the UI contains any links to user feedback forms
;feedback_links_enabled = true

# Static context that is being added to analytics events
;reporting_static_context = grafanaInstance=12, os=linux

#################################### Security ####################################
[security]
# disable creation of admin user on first start of grafana
;disable_initial_admin_creation = false

# default admin user, created on startup
;admin_user = admin

# default admin password, can be changed before first start of grafana,  or in profile settings
;admin_password = admin

# default admin email, created on startup
;admin_email = admin@localhost

# used for signing
;secret_key = SW2YcwTIb9zpOOhoPsMm

# current key provider used for envelope encryption, default to static value specified by secret_key
;encryption_provider = secretKey.v1

# list of configured key providers, space separated (Enterprise only): e.g., awskms.v1 azurekv.v1
;available_encryption_providers =

# disable gravatar profile images
;disable_gravatar = false

# data source proxy whitelist (ip_or_domain:port separated by spaces)
;data_source_proxy_whitelist =

# disable protection against brute force login attempts
;disable_brute_force_login_protection = false

# set to true if you host Grafana behind HTTPS. default is false.
;cookie_secure = false

# set cookie SameSite attribute. defaults to `lax`. can be set to "lax", "strict", "none" and "disabled"
;cookie_samesite = lax

# set to true if you want to allow browsers to render Grafana in a <frame>, <iframe>, <embed> or <object>. default is false.
;allow_embedding = false

# Set to true if you want to enable http strict transport security (HSTS) response header.
# HSTS tells browsers that the site should only be accessed using HTTPS.
;strict_transport_security = false

# Sets how long a browser should cache HSTS. Only applied if strict_transport_security is enabled.
;strict_transport_security_max_age_seconds = 86400

# Set to true if to enable HSTS preloading option. Only applied if strict_transport_security is enabled.
;strict_transport_security_preload = false

# Set to true if to enable the HSTS includeSubDomains option. Only applied if strict_transport_security is enabled.
;strict_transport_security_subdomains = false

# Set to true to enable the X-Content-Type-Options response header.
# The X-Content-Type-Options response HTTP header is a marker used by the server to indicate that the MIME types advertised
# in the Content-Type headers should not be changed and be followed.
;x_content_type_options = true

# Set to true to enable the X-XSS-Protection header, which tells browsers to stop pages from loading
# when they detect reflected cross-site scripting (XSS) attacks.
;x_xss_protection = true

# Enable adding the Content-Security-Policy header to your requests.
# CSP allows to control resources the user agent is allowed to load and helps prevent XSS attacks.
;content_security_policy = false

# Set Content Security Policy template used when adding the Content-Security-Policy header to your requests.
# $NONCE in the template includes a random nonce.
# $ROOT_PATH is server.root_url without the protocol.
;content_security_policy_template = """script-src 'self' 'unsafe-eval' 'unsafe-inline' 'strict-dynamic' $NONCE;object-src 'none';font-src 'self';style-src 'self' 'unsafe-inline' blob:;img-src * data:;base-uri 'self';connect-src 'self' grafana.com ws://$ROOT_PATH wss://$ROOT_PATH;manifest-src 'self';media-src 'none';form-action 'self';"""

# Enable adding the Content-Security-Policy-Report-Only header to your requests.
# Allows you to monitor the effects of a policy without enforcing it.
;content_security_policy_report_only = false

# Set Content Security Policy Report Only template used when adding the Content-Security-Policy-Report-Only header to your requests.
# $NONCE in the template includes a random nonce.
# $ROOT_PATH is server.root_url without the protocol.
;content_security_policy_report_only_template = """script-src 'self' 'unsafe-eval' 'unsafe-inline' 'strict-dynamic' $NONCE;object-src 'none';font-src 'self';style-src 'self' 'unsafe-inline' blob:;img-src * data:;base-uri 'self';connect-src 'self' grafana.com ws://$ROOT_PATH wss://$ROOT_PATH;manifest-src 'self';media-src 'none';form-action 'self';"""

# Controls if old angular plugins are supported or not.
;angular_support_enabled = false

# List of additional allowed URLs to pass by the CSRF check, separated by spaces. Suggested when authentication comes from an IdP.
;csrf_trusted_origins = example.com

# List of allowed headers to be set by the user, separated by spaces. Suggested to use for if authentication lives behind reverse proxies.
;csrf_additional_headers =

# The CSRF check will be executed even if the request has no login cookie.
;csrf_always_check = false

# Comma-separated list of plugins ids that won't be loaded inside the frontend sandbox
;disable_frontend_sandbox_for_plugins =

# Comma-separated list of paths for POST/PUT URL in actions. Empty will allow anything that is not on the same origin
;actions_allow_post_url =

[security.encryption]
# Defines the time-to-live (TTL) for decrypted data encryption keys stored in memory (cache).
# Please note that small values may cause performance issues due to a high frequency decryption operations.
;data_keys_cache_ttl = 15m

# Defines the frequency of data encryption keys cache cleanup interval.
# On every interval, decrypted data encryption keys that reached the TTL are removed from the cache.
;data_keys_cache_cleanup_interval = 1m

#################################### Snapshots ###########################
[snapshots]
# set to false to remove snapshot functionality
;enabled = true

# snapshot sharing options
;external_enabled = true
;external_snapshot_url = https://snapshots.raintank.io
;external_snapshot_name = Publish to snapshots.raintank.io

# Set to true to enable this Grafana instance act as an external snapshot server and allow unauthenticated requests for
# creating and deleting snapshots.
;public_mode = false

#################################### Dashboards ##################
[dashboards]
# Number dashboard versions to keep (per dashboard). Default: 20, Minimum: 1
;versions_to_keep = 20

# Minimum dashboard refresh interval. When set, this will restrict users to set the refresh interval of a dashboard lower than given interval. Per default this is 5 seconds.
# The interval string is a possibly signed sequence of decimal numbers, followed by a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.
;min_refresh_interval = 5s

# Path to the default home dashboard. If this value is empty, then Grafana uses StaticRootPath + "dashboards/home.json"
;default_home_dashboard_path =

################################### Data sources #########################
[datasources]
# Upper limit of data sources that Grafana will return. This limit is a temporary configuration and it will be deprecated when pagination will be introduced on the list data sources API.
;datasource_limit = 5000

# Number of queries to be executed concurrently. Only for the datasource supports concurrency.
# For now only Loki and InfluxDB (with influxql) are supporting concurrency behind the feature flags.
# Check datasource documentations for enabling concurrency.
;concurrent_query_count = 10

################################### SQL Data Sources #####################
[sql_datasources]
# Default maximum number of open connections maintained in the connection pool
# when connecting to SQL based data sources
;max_open_conns_default = 100

# Default maximum number of idle connections maintained in the connection pool
# when connecting to SQL based data sources
;max_idle_conns_default = 100

# Default maximum connection lifetime used when connecting
# to SQL based data sources.
;max_conn_lifetime_default = 14400

#################################### Users ###############################
[users]
# disable user signup / registration
;allow_sign_up = true

# Allow non admin users to create organizations
;allow_org_create = true

# Set to true to automatically assign new users to the default organization (id 1)
;auto_assign_org = true

# Set this value to automatically add new users to the provided organization (if auto_assign_org above is set to true)
;auto_assign_org_id = 1

# Default role new users will be automatically assigned
;auto_assign_org_role = Viewer

# Require email validation before sign up completes
;verify_email_enabled = false

# Redirect to default OrgId after login
;login_default_org_id =

# Background text for the user field on the login page
;login_hint = email or username
;password_hint = password

# Default UI theme ("dark", "light" or "system")
;default_theme = dark

# Default UI language (supported IETF language tag, such as en-US)
;default_language = en-US

# Path to a custom home page. Users are only redirected to this if the default home dashboard is used. It should match a frontend route and contain a leading slash.
;home_page =

# External user management, these options affect the organization users view
;external_manage_link_url =
;external_manage_link_name =
;external_manage_info =

# Viewers can edit/inspect dashboard settings in the browser. But not save the dashboard.
;viewers_can_edit = false

# Editors can administrate dashboard, folders and teams they create
;editors_can_admin = false

# The duration in time a user invitation remains valid before expiring. This setting should be expressed as a duration. Examples: 6h (hours), 2d (days), 1w (week). Default is 24h (24 hours). The minimum supported duration is 15m (15 minutes).
;user_invite_max_lifetime_duration = 24h

# The duration in time a verification email, used to update the email address of a user, remains valid before expiring. This setting should be expressed as a duration. Examples: 6h (hours), 2d (days), 1w (week). Default is 1h (1 hour).
;verification_email_max_lifetime_duration = 1h

# Frequency of updating a user's last seen time. The minimum supported duration is 5m (5 minutes). The maximum supported duration is 1h (1 hour).
;last_seen_update_interval = 15m

# Enter a comma-separated list of users login to hide them in the Grafana UI. These users are shown to Grafana admins and themselves.
; hidden_users =

[secretscan]
# Enable secretscan feature
;enabled = false

# Interval to check for token leaks
;interval = 5m

# base URL of the grafana token leak check service
;base_url = https://secret-scanning.grafana.net

# URL to send outgoing webhooks to in case of detection
;oncall_url =

# Whether to revoke the token if a leak is detected or just send a notification
;revoke = true

[service_accounts]
# Service account maximum expiration date in days.
# When set, Grafana will not allow the creation of tokens with expiry greater than this setting.
; token_expiration_day_limit =

[auth]
# Login cookie name
;login_cookie_name = grafana_session

# Disable usage of Grafana build-in login solution.
;disable_login = false

# The maximum lifetime (duration) an authenticated user can be inactive before being required to login at next visit. Default is 7 days (7d). This setting should be expressed as a duration, e.g. 5m (minutes), 6h (hours), 10d (days), 2w (weeks), 1M (month). The lifetime resets at each successful token rotation.
;login_maximum_inactive_lifetime_duration =

# The maximum lifetime (duration) an authenticated user can be logged in since login time before being required to login. Default is 30 days (30d). This setting should be expressed as a duration, e.g. 5m (minutes), 6h (hours), 10d (days), 2w (weeks), 1M (month).
;login_maximum_lifetime_duration =

# How often should auth tokens be rotated for authenticated users when being active. The default is each 10 minutes.
;token_rotation_interval_minutes = 10

# Set to true to disable (hide) the login form, useful if you use OAuth, defaults to false
;disable_login_form = false

# Set to true to disable the sign out link in the side menu. Useful if you use auth.proxy or auth.jwt, defaults to false
;disable_signout_menu = false

# URL to redirect the user to after sign out
;signout_redirect_url =

# Set to true to attempt login with OAuth automatically, skipping the login screen.
# This setting is ignored if multiple OAuth providers are configured.
# Deprecated, use auto_login option for specific provider instead.
;oauth_auto_login = false

# Sets a custom oAuth error message. This is useful if you need to point the users to a specific location for support.
;oauth_login_error_message = oauth.login.error

# OAuth state max age cookie duration in seconds. Defaults to 600 seconds.
;oauth_state_cookie_max_age = 600

# Minimum wait time in milliseconds for the server lock retry mechanism.
# The server lock retry mechanism is used to prevent multiple Grafana instances from
# simultaneously refreshing OAuth tokens. This mechanism waits at least this amount
# of time before retrying to acquire the server lock. There are 5 retries in total.
# The wait time between retries is calculated as random(n, n + 500)
; oauth_refresh_token_server_lock_min_wait_ms = 1000

# limit of api_key seconds to live before expiration
;api_key_max_seconds_to_live = -1

# Set to true to enable SigV4 authentication option for HTTP-based datasources.
;sigv4_auth_enabled = false

# Set to true to enable verbose logging of SigV4 request signing
;sigv4_verbose_logging = false

# Set to true to enable Azure authentication option for HTTP-based datasources.
;azure_auth_enabled = false

# Use email lookup in addition to the unique ID provided by the IdP
;oauth_allow_insecure_email_lookup = false

# Set to true to include id of identity as a response header
;id_response_header_enabled = false

# Prefix used for the id response header, X-Grafana-Identity-Id
;id_response_header_prefix = X-Grafana

# List of identity namespaces to add id response headers for, separated by space.
# Available namespaces are user, api-key and service-account.
# The header value will encode the namespace ("user:<id>", "api-key:<id>", "service-account:<id>")
;id_response_header_namespaces = user api-key service-account

# Enables the use of managed service accounts for plugin authentication
# This feature currently **only supports single-organization deployments**
; managed_service_accounts_enabled = false

#################################### Anonymous Auth ######################
[auth.anonymous]
# enable anonymous access
;enabled = false

# specify organization name that should be used for unauthenticated users
;org_name = Main Org.

# specify role for unauthenticated users
;org_role = Viewer

# mask the Grafana version number for unauthenticated users
;hide_version = false

# number of devices in total
;device_limit =

#################################### GitHub Auth ##########################
[auth.github]
;name = GitHub
;icon = github
;enabled = false
;allow_sign_up = true
;auto_login = false
;client_id = some_id
;client_secret = some_secret
;scopes = user:email,read:org
;auth_url = https://github.com/login/oauth/authorize
;token_url = https://github.com/login/oauth/access_token
;api_url = https://api.github.com/user
;signout_redirect_url =
;allowed_domains =
;team_ids =
;allowed_organizations =
;role_attribute_path =
;role_attribute_strict = false
;org_mapping =
;allow_assign_grafana_admin = false
;skip_org_role_sync = false
;tls_skip_verify_insecure = false
;tls_client_cert =
;tls_client_key =
;tls_client_ca =
# GitHub OAuth apps does not provide refresh tokens and the access tokens never expires.
;use_refresh_token = false

#################################### GitLab Auth #########################
[auth.gitlab]
;name = GitLab
;icon = gitlab
;enabled = false
;allow_sign_up = true
;auto_login = false
;client_id = some_id
;client_secret = some_secret
;scopes = openid email profile
;auth_url = https://gitlab.com/oauth/authorize
;token_url = https://gitlab.com/oauth/token
;api_url = https://gitlab.com/api/v4
;signout_redirect_url =
;allowed_domains =
;allowed_groups =
;role_attribute_path =
;role_attribute_strict = false
;org_mapping =
;allow_assign_grafana_admin = false
;skip_org_role_sync = false
;tls_skip_verify_insecure = false
;tls_client_cert =
;tls_client_key =
;tls_client_ca =
;use_pkce = true
;use_refresh_token = true

#################################### Google Auth ##########################
[auth.google]
;name = Google
;icon = google
;enabled = false
;allow_sign_up = true
;auto_login = false
;client_id = some_client_id
;client_secret = some_client_secret
;scopes = openid email profile
;auth_url = https://accounts.google.com/o/oauth2/v2/auth
;token_url = https://oauth2.googleapis.com/token
;api_url = https://openidconnect.googleapis.com/v1/userinfo
;signout_redirect_url =
;allowed_domains =
;validate_hd =
;hosted_domain =
;allowed_groups =
;role_attribute_path =
;role_attribute_strict = false
;org_mapping =
;allow_assign_grafana_admin = false
;skip_org_role_sync = false
;tls_skip_verify_insecure = false
;tls_client_cert =
;tls_client_key =
;tls_client_ca =
;use_pkce = true
;use_refresh_token = true

#################################### Grafana.com Auth ####################
[auth.grafana_com]
;name = Grafana.com
;icon = grafana
;enabled = false
;allow_sign_up = true
;auto_login = false
;client_id = some_id
;client_secret = some_secret
;scopes = user:email
;allowed_organizations =
;skip_org_role_sync = false
;use_refresh_token = false

#################################### Azure AD OAuth #######################
[auth.azuread]
;name = Microsoft
;icon = microsoft
;enabled = false
;allow_sign_up = true
;auto_login = false
;client_id = some_client_id
;client_secret = some_client_secret
;scopes = openid email profile
;auth_url = https://login.microsoftonline.com/<tenant-id>/oauth2/v2.0/authorize
;token_url = https://login.microsoftonline.com/<tenant-id>/oauth2/v2.0/token
;signout_redirect_url =
;allowed_domains =
;allowed_groups =
;allowed_organizations =
;role_attribute_strict = false
;org_mapping =
;allow_assign_grafana_admin = false
;use_pkce = true
# prevent synchronizing users organization roles
;skip_org_role_sync = false
;use_refresh_token = true

#################################### Okta OAuth #######################
[auth.okta]
;name = Okta
;enabled = false
;allow_sign_up = true
;auto_login = false
;client_id = some_id
;client_secret = some_secret
;scopes = openid profile email groups
;auth_url = https://<tenant-id>.okta.com/oauth2/v1/authorize
;token_url = https://<tenant-id>.okta.com/oauth2/v1/token
;api_url = https://<tenant-id>.okta.com/oauth2/v1/userinfo
;signout_redirect_url =
;allowed_domains =
;allowed_groups =
;role_attribute_path =
;role_attribute_strict = false
; org_attribute_path =
; org_mapping =
;allow_assign_grafana_admin = false
;skip_org_role_sync = false
;tls_skip_verify_insecure = false
;tls_client_cert =
;tls_client_key =
;tls_client_ca =
;use_pkce = true
;use_refresh_token = true

#################################### Generic OAuth ##########################
[auth.generic_oauth]
name = OAuth
;icon = signin
enabled = true
allow_sign_up = true
;auto_login = false
client_id = b4c5f47c-793a-4b25-8f61-931d0d05c9b8
client_secret = 8eaecfd6-0fc9-4440-90c5-17a980f39db8
scopes = openid,groups
;scopes = user:email,read:org
;empty_scopes = false
;email_attribute_name = email:primary
;email_attribute_path =
;login_attribute_path =
name_attribute_path = user_name
;role_attribute_path =
;role_attribute_strict = false
;groups_attribute_path =
;id_token_attribute_name =
;team_ids_attribute_path
auth_url = https://sso.ncloud.com/tenants/f11a0c29-c754-4866-82bd-8f9f7f947db2/oauth2/authorize
token_url = https://sso.ncloud.com/tenants/f11a0c29-c754-4866-82bd-8f9f7f947db2/oauth2/token
api_url = https://sso.ncloud.com/tenants/f11a0c29-c754-4866-82bd-8f9f7f947db2/oauth2/userinfo
;signout_redirect_url =
;teams_url =
;allowed_domains =
;team_ids =
;allowed_organizations =
;org_attribute_path =
;org_mapping =
;team_ids_attribute_path =
;tls_skip_verify_insecure = false
;tls_client_cert =
;tls_client_key =
;tls_client_ca =
;use_pkce = false
;auth_style =
;allow_assign_grafana_admin = false
;skip_org_role_sync = false
use_refresh_token = true

#################################### Basic Auth ##########################
[auth.basic]
;enabled = true
;password_policy = false

#################################### Auth Proxy ##########################
[auth.proxy]
;enabled = false
;header_name = X-WEBAUTH-USER
;header_property = username
;auto_sign_up = true
;sync_ttl = 60
;whitelist = 192.168.1.1, 192.168.2.1
;headers = Email:X-User-Email, Name:X-User-Name
# Non-ASCII strings in header values are encoded using quoted-printable encoding
;headers_encoded = false
# Read the auth proxy docs for details on what the setting below enables
;enable_login_token = false

#################################### Auth JWT ##########################
[auth.jwt]
;enabled = true
;enable_login_token = false
;header_name = X-JWT-Assertion
;email_claim = sub
;username_claim = sub
;email_attribute_path = jmespath.email
;username_attribute_path = jmespath.username
;jwk_set_url = https://foo.bar/.well-known/jwks.json
;jwk_set_file = /path/to/jwks.json
;cache_ttl = 60m
;expect_claims = {"aud": ["foo", "bar"]}
;key_file = /path/to/key/file
# Use in conjunction with key_file in case the JWT token's header specifies a key ID in "kid" field
;key_id = some-key-id
;role_attribute_path =
;role_attribute_strict = false
;groups_attribute_path =
;auto_sign_up = false
;url_login = false
;allow_assign_grafana_admin = false
;skip_org_role_sync = false
;signout_redirect_url =

#################################### Auth LDAP ##########################
[auth.ldap]
;enabled = false
;config_file = /etc/grafana/ldap.toml
;allow_sign_up = true
# prevent synchronizing ldap users organization roles
;skip_org_role_sync = false

# LDAP background sync (Enterprise only)
# At 1 am every day
;sync_cron = "0 1 * * *"
;active_sync_enabled = true

#################################### AWS ###########################
[aws]
# Enter a comma-separated list of allowed AWS authentication providers.
# Options are: default (AWS SDK Default), keys (Access && secret key), credentials (Credentials field), ec2_iam_role (EC2 IAM Role)
; allowed_auth_providers = default,keys,credentials

# Allow AWS users to assume a role using temporary security credentials.
# If true, assume role will be enabled for all AWS authentication providers that are specified in aws_auth_providers
; assume_role_enabled = true

# Specify max no of pages to be returned by the ListMetricPages API
; list_metrics_page_limit = 500

# Experimental, for use in Grafana Cloud only. Please do not set.
; external_id =

# Sets the expiry duration of an assumed role.
# This setting should be expressed as a duration. Examples: 6h (hours), 10d (days), 2w (weeks), 1M (month).
; session_duration = "15m"

# Set the plugins that will receive AWS settings for each request (via plugin context)
# By default this will include all Grafana Labs owned AWS plugins, or those that make use of AWS settings (ElasticSearch, Prometheus).
; forward_settings_to_plugins = cloudwatch, grafana-athena-datasource, grafana-redshift-datasource, grafana-x-ray-datasource, grafana-timestream-datasource, grafana-iot-sitewise-datasource, grafana-iot-twinmaker-app, grafana-opensearch-datasource, aws-datasource-provisioner, elasticsearch, prometheus

#################################### Azure ###############################
[azure]
# Azure cloud environment where Grafana is hosted
# Possible values are AzureCloud, AzureChinaCloud, AzureUSGovernment and AzureGermanCloud
# Default value is AzureCloud (i.e. public cloud)
;cloud = AzureCloud

# A customized list of Azure cloud settings and properties, used by data sources which need this information when run in non-standard azure environments
# When specified, this list will replace the default cloud list of AzureCloud, AzureChinaCloud, AzureUSGovernment and AzureGermanCloud
;clouds_config = `[
;		{
;			"name":"CustomCloud1",
;			"displayName":"Custom Cloud 1",
;			"aadAuthority":"https://login.cloud1.contoso.com/",
;			"properties":{
;				"azureDataExplorerSuffix": ".kusto.windows.cloud1.contoso.com",
;				"logAnalytics":            "https://api.loganalytics.cloud1.contoso.com",
;				"portal":                  "https://portal.azure.cloud1.contoso.com",
;				"prometheusResourceId":    "https://prometheus.monitor.azure.cloud1.contoso.com",
;				"resourceManager":         "https://management.azure.cloud1.contoso.com"
;			}
;		}]`

# Specifies whether Grafana hosted in Azure service with Managed Identity configured (e.g. Azure Virtual Machines instance)
# If enabled, the managed identity can be used for authentication of Grafana in Azure services
# Disabled by default, needs to be explicitly enabled
;managed_identity_enabled = false

# Client ID to use for user-assigned managed identity
# Should be set for user-assigned identity and should be empty for system-assigned identity
;managed_identity_client_id =

# Specifies whether Azure AD Workload Identity authentication should be enabled in datasources that support it
# For more documentation on Azure AD Workload Identity, review this documentation:
# https://azure.github.io/azure-workload-identity/docs/
# Disabled by default, needs to be explicitly enabled
;workload_identity_enabled = false

# Tenant ID of the Azure AD Workload Identity
# Allows to override default tenant ID of the Azure AD identity associated with the Kubernetes service account
;workload_identity_tenant_id =

# Client ID of the Azure AD Workload Identity
# Allows to override default client ID of the Azure AD identity associated with the Kubernetes service account
;workload_identity_client_id =

# Custom path to token file for the Azure AD Workload Identity
# Allows to set a custom path to the projected service account token file
;workload_identity_token_file =

# Specifies whether user identity authentication (on behalf of currently signed-in user) should be enabled in datasources
# that support it (requires AAD authentication)
# Disabled by default, needs to be explicitly enabled
;user_identity_enabled = false

# Specifies whether user identity authentication fallback credentials should be enabled in data sources
# Enabling this allows data source creators to provide fallback credentials for backend initiated requests
# e.g. alerting, recorded queries etc.
# Enabled by default, needs to be explicitly disabled
# Will not have any effect if user identity is disabled above
;user_identity_fallback_credentials_enabled = true

# Override token URL for Azure Active Directory
# By default is the same as token URL configured for AAD authentication settings
;user_identity_token_url =

# Override ADD application ID which would be used to exchange users token to an access token for the datasource
# By default is the same as used in AAD authentication or can be set to another application (for OBO flow)
;user_identity_client_id =

# Override the AAD application client secret
# By default is the same as used in AAD authentication or can be set to another application (for OBO flow)
;user_identity_client_secret =

# Allows the usage of a custom token request assertion when Grafana is behind an authentication proxy
# In most cases this will not need to be used. To enable this set the value to "username"
# The default is empty and any other value will not enable this functionality
;username_assertion =

# Set the plugins that will receive Azure settings for each request (via plugin context)
# By default this will include all Grafana Labs owned Azure plugins, or those that make use of Azure settings (Azure Monitor, Azure Data Explorer, Prometheus, MSSQL).
;forward_settings_to_plugins = grafana-azure-monitor-datasource, prometheus, grafana-azure-data-explorer-datasource, mssql

# Specifies whether Entra password auth can be used for the MSSQL data source
# Disabled by default, needs to be explicitly enabled
;azure_entra_password_credentials_enabled = false

#################################### Role-based Access Control ###########
[rbac]
;permission_cache = true

# Reset basic roles permissions on boot
# Warning left to true, basic roles permissions will be reset on every boot
#reset_basic_roles = false

# Validate permissions' action and scope on role creation and update
; permission_validation_enabled = true

#################################### SMTP / Emailing ##########################
[smtp]
;enabled = false
;host = localhost:25
;user =
# If the password contains # or ; you have to wrap it with triple quotes. Ex """#password;"""
;password =
;cert_file =
;key_file =
;skip_verify = false
;from_address = admin@grafana.localhost
;from_name = Grafana
# EHLO identity in SMTP dialog (defaults to instance_name)
;ehlo_identity = dashboard.example.com
# SMTP startTLS policy (defaults to 'OpportunisticStartTLS')
;startTLS_policy = NoStartTLS
# Enable trace propagation in e-mail headers, using the 'traceparent', 'tracestate' and (optionally) 'baggage' fields (defaults to false)
;enable_tracing = false

[smtp.static_headers]
# Include custom static headers in all outgoing emails
;Foo-Header = bar
;Foo = bar

[emails]
;welcome_email_on_sign_up = false
;templates_pattern = emails/*.html, emails/*.txt
;content_types = text/html

#################################### Logging ##########################
[log]
# Either "console", "file", "syslog". Default is console and  file
# Use space to separate multiple modes, e.g. "console file"
;mode = console file

# Either "debug", "info", "warn", "error", "critical", default is "info"
;level = info

# optional settings to set different levels for specific loggers. Ex filters = sqlstore:debug
;filters =
filters = oauth.generic_oauth:debug
# Set the default error message shown to users. This message is displayed instead of sensitive backend errors which should be obfuscated. Default is the same as the sample value.
;user_facing_default_error = "please inspect Grafana server log for details"

# For "console" mode only
[log.console]
;level =

# log line format, valid options are text, console and json
;format = console

# For "file" mode only
[log.file]
;level =

# log line format, valid options are text, console and json
;format = text

# This enables automated log rotate(switch of following options), default is true
;log_rotate = true

# Max line number of single file, default is 1000000
;max_lines = 1000000

# Max size shift of single file, default is 28 means 1 << 28, 256MB
;max_size_shift = 28

# Segment log daily, default is true
;daily_rotate = true

# Expired days of log file(delete after max days), default is 7
;max_days = 7

[log.syslog]
;level =

# log line format, valid options are text, console and json
;format = text

# Syslog network type and address. This can be udp, tcp, or unix. If left blank, the default unix endpoints will be used.
;network =
;address =

# Syslog facility. user, daemon and local0 through local7 are valid.
;facility =

# Syslog tag. By default, the process' argv[0] is used.
;tag =

[log.frontend]
# Should Faro javascript agent be initialized
;enabled = false

# Custom HTTP endpoint to send events to. Default will log the events to stdout.
;custom_endpoint = /log-grafana-javascript-agent

# Requests per second limit enforced an extended period, for Grafana backend log ingestion endpoint (/log).
;log_endpoint_requests_per_second_limit = 3

# Max requests accepted per short interval of time for Grafana backend log ingestion endpoint (/log).
;log_endpoint_burst_limit = 15

# Should error instrumentation be enabled, only affects Grafana Javascript Agent
;instrumentations_errors_enabled = true

# Should console instrumentation be enabled, only affects Grafana Javascript Agent
;instrumentations_console_enabled = false

# Should webvitals instrumentation be enabled, only affects Grafana Javascript Agent
;instrumentations_webvitals_enabled = false

# Should tracing instrumentation be enabled, only affects Grafana Javascript Agent
;instrumentations_tracing_enabled = false

# Api Key, only applies to Grafana Javascript Agent provider
;api_key = testApiKey

#################################### Usage Quotas ########################
[quota]
; enabled = false

#### set quotas to -1 to make unlimited. ####
# limit number of users per Org.
; org_user = 10

# limit number of dashboards per Org.
; org_dashboard = 100

# limit number of data_sources per Org.
; org_data_source = 10

# limit number of api_keys per Org.
; org_api_key = 10

# limit number of alerts per Org.
;org_alert_rule = 100

# limit number of orgs a user can create.
; user_org = 10

# Global limit of users.
; global_user = -1

# global limit of orgs.
; global_org = -1

# global limit of dashboards
; global_dashboard = -1

# global limit of api_keys
; global_api_key = -1

# global limit on number of logged in users.
; global_session = -1

# global limit of alerts
;global_alert_rule = -1

# global limit of files uploaded to the SQL DB
;global_file = 1000

# global limit of correlations
; global_correlations = -1

# Limit of the number of alert rules per rule group.
# This is not strictly enforced yet, but will be enforced over time.
;alerting_rule_group_rules = 100

# Limit the number of query evaluation results per alert rule.
# If the condition query of an alert rule produces more results than this limit,
# the evaluation results in an error.
;alerting_rule_evaluation_results = -1

#################################### Unified Alerting ####################
[unified_alerting]
#Enable the Unified Alerting sub-system and interface. When enabled we'll migrate all of your alert rules and notification channels to the new system. New alert rules will be created and your notification channels will be converted into an Alertmanager configuration. Previous data is preserved to enable backwards compatibility but new data is removed.```
;enabled = true

# Comma-separated list of organization IDs for which to disable unified alerting. Only supported if unified alerting is enabled.
;disabled_orgs =

# Specify how long to wait for the alerting service to initialize
;initialization_timeout = 30s

# Specify the frequency of polling for admin config changes.
# The interval string is a possibly signed sequence of decimal numbers, followed by a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.
;admin_config_poll_interval = 60s

# Specify the frequency of polling for Alertmanager config changes.
# The interval string is a possibly signed sequence of decimal numbers, followed by a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.
;alertmanager_config_poll_interval = 60s


# Maximum number of active and pending silences that a tenant can have at once. Default: 0 (no limit).
;alertmanager_max_silences_count =

# Maximum silence size in bytes. Default: 0 (no limit).
;alertmanager_max_silence_size_bytes =

# Set to true when using redis in cluster mode.
;ha_redis_cluster_mode_enabled = false

# The redis server address(es) that should be connected to.
# Can either be a single address, or if using redis in cluster mode,
# the cluster configuration address or a comma-separated list of addresses.
;ha_redis_address =

# The username that should be used to authenticate with the redis server.
;ha_redis_username =

# The password that should be used to authenticate with the redis server.
;ha_redis_password =

# The redis database, by default it's 0.
;ha_redis_db =

# A prefix that is used for every key or channel that is created on the redis server
# as part of HA for alerting.
;ha_redis_prefix =

# The name of the cluster peer that will be used as identifier. If none is
# provided, a random one will be generated.
;ha_redis_peer_name =

# The maximum number of simultaneous redis connections.
# ha_redis_max_conns = 5

# Enable TLS on the client used to communicate with the redis server. This should be set to true
# if using any of the other ha_redis_tls_* fields.
# ha_redis_tls_enabled = false

# Path to the PEM-encoded TLS client certificate file used to authenticate with the redis server.
# Required if using Mutual TLS.
# ha_redis_tls_cert_path =

# Path to the PEM-encoded TLS private key file. Also requires the client certificate to be configured.
# Required if using Mutual TLS.
# ha_redis_tls_key_path =

# Path to the PEM-encoded CA certificates file. If not set, the host's root CA certificates are used.
# ha_redis_tls_ca_path =

# Overrides the expected name of the redis server certificate.
# ha_redis_tls_server_name =

# Skips validating the redis server certificate.
# ha_redis_tls_insecure_skip_verify =

# Overrides the default TLS cipher suite list.
# ha_redis_tls_cipher_suites =

# Overrides the default minimum TLS version.
# Allowed values: VersionTLS10, VersionTLS11, VersionTLS12, VersionTLS13
# ha_redis_tls_min_version =

# Listen address/hostname and port to receive unified alerting messages for other Grafana instances. The port is used for both TCP and UDP. It is assumed other Grafana instances are also running on the same port. The default value is `0.0.0.0:9094`.
;ha_listen_address = "0.0.0.0:9094"

# Listen address/hostname and port to receive unified alerting messages for other Grafana instances. The port is used for both TCP and UDP. It is assumed other Grafana instances are also running on the same port. The default value is `0.0.0.0:9094`.
;ha_advertise_address = ""

# Comma-separated list of initial instances (in a format of host:port) that will form the HA cluster. Configuring this setting will enable High Availability mode for alerting.
;ha_peers = ""

# Time to wait for an instance to send a notification via the Alertmanager. In HA, each Grafana instance will
# be assigned a position (e.g. 0, 1). We then multiply this position with the timeout to indicate how long should
# each instance wait before sending the notification to take into account replication lag.
# The interval string is a possibly signed sequence of decimal numbers, followed by a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.
;ha_peer_timeout = "15s"

# The label is an optional string to include on each packet and stream.
# It uniquely identifies the cluster and prevents cross-communication
# issues when sending gossip messages in an enviromenet with multiple clusters.
;ha_label =

# The interval between sending gossip messages. By lowering this value (more frequent) gossip messages are propagated
# across cluster more quickly at the expense of increased bandwidth usage.
# The interval string is a possibly signed sequence of decimal numbers, followed by a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.
;ha_gossip_interval = "200ms"

# Length of time to attempt to reconnect to a lost peer. Recommended to be short (<15m) when Grafana is running in a Kubernetes cluster.
# The string is a possibly signed sequence of decimal numbers, followed by a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.
;ha_reconnect_timeout = 6h

# The interval between gossip full state syncs. Setting this interval lower (more frequent) will increase convergence speeds
# across larger clusters at the expense of increased bandwidth usage.
# The interval string is a possibly signed sequence of decimal numbers, followed by a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.
;ha_push_pull_interval = "60s"

# Enable or disable alerting rule execution. The alerting UI remains visible.
;execute_alerts = true

# Alert evaluation timeout when fetching data from the datasource.
# The timeout string is a possibly signed sequence of decimal numbers, followed by a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.
;evaluation_timeout = 30s

# Number of times we'll attempt to evaluate an alert rule before giving up on that evaluation. The default value is 1.
;max_attempts = 1

# Minimum interval to enforce between rule evaluations. Rules will be adjusted if they are less than this value  or if they are not multiple of the scheduler interval (10s). Higher values can help with resource management as we'll schedule fewer evaluations over time.
# The interval string is a possibly signed sequence of decimal numbers, followed by a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.
;min_interval = 10s

# This is an experimental option to add parallelization to saving alert states in the database.
# It configures the maximum number of concurrent queries per rule evaluated. The default value is 1
# (concurrent queries per rule disabled).
;max_state_save_concurrency = 1

# If the feature flag 'alertingSaveStatePeriodic' is enabled, this is the interval that is used to persist the alerting instances to the database.
# The interval string is a possibly signed sequence of decimal numbers, followed by a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.
;state_periodic_save_interval = 5m

# Disables the smoothing of alert evaluations across their evaluation window.
# Rules will evaluate in sync.
;disable_jitter = false

# Retention period for Alertmanager notification log entries.
;notification_log_retention = 5d

# Duration for which a resolved alert state transition will continue to be sent to the Alertmanager.
;resolved_alert_retention = 15m

# Defines the limit of how many alert rule versions
# should be stored in the database for each alert rule in an organization including the current one.
# 0 value means no limit
;rule_version_record_limit= 0

[unified_alerting.screenshots]
# Enable screenshots in notifications. You must have either installed the Grafana image rendering
# plugin, or set up Grafana to use a remote rendering service.
# For more information on configuration options, refer to [rendering].
;capture = false

# The timeout for capturing screenshots. If a screenshot cannot be captured within the timeout then
# the notification is sent without a screenshot. The maximum duration is 30 seconds. This timeout
# should be less than the minimum Interval of all Evaluation Groups to avoid back pressure on alert
# rule evaluation.
;capture_timeout = 10s

# The maximum number of screenshots that can be taken at the same time. This option is different from
# concurrent_render_request_limit as max_concurrent_screenshots sets the number of concurrent screenshots
# that can be taken at the same time for all firing alerts where as concurrent_render_request_limit sets
# the total number of concurrent screenshots across all Grafana services.
;max_concurrent_screenshots = 5

# Uploads screenshots to the local Grafana server or remote storage such as Azure, S3 and GCS. Please
# see [external_image_storage] for further configuration options. If this option is false then
# screenshots will be persisted to disk for up to temp_data_lifetime.
;upload_external_image_storage = false

[unified_alerting.reserved_labels]
# Comma-separated list of reserved labels added by the Grafana Alerting engine that should be disabled.
# For example: `disabled_labels=grafana_folder`
disabled_labels =


[unified_alerting.reserved_labels]
# Comma-separated list of reserved labels added by the Grafana Alerting engine that should be disabled.
# For example: `disabled_labels=grafana_folder`
;disabled_labels =

[unified_alerting.state_history]
# Enable the state history functionality in Unified Alerting. The previous states of alert rules will be visible in panels and in the UI.
; enabled = true

# Select which pluggable state history backend to use. Either "annotations", "loki", or "multiple"
# "loki" writes state history to an external Loki instance. "multiple" allows history to be written to multiple backends at once.
# Defaults to "annotations".
; backend = "multiple"

# For "multiple" only.
# Indicates the main backend used to serve state history queries.
# Either "annotations" or "loki"
; primary = "loki"

# For "multiple" only.
# Comma-separated list of additional backends to write state history data to.
; secondaries = "annotations"

# For "loki" only.
# URL of the external Loki instance.
# Either "loki_remote_url", or both of "loki_remote_read_url" and "loki_remote_write_url" is required for the "loki" backend.
; loki_remote_url = "http://loki:3100"

# For "loki" only.
# URL of the external Loki's read path. To be used in configurations where Loki has separated read and write URLs.
# Either "loki_remote_url", or both of "loki_remote_read_url" and "loki_remote_write_url" is required for the "loki" backend.
; loki_remote_read_url = "http://loki-querier:3100"

# For "loki" only.
# URL of the external Loki's write path. To be used in configurations where Loki has separated read and write URLs.
# Either "loki_remote_url", or both of "loki_remote_read_url" and "loki_remote_write_url" is required for the "loki" backend.
; loki_remote_write_url = "http://loki-distributor:3100"

# For "loki" only.
# Optional tenant ID to attach to requests sent to Loki.
; loki_tenant_id = 123

# For "loki" only.
# Optional username for basic authentication on requests sent to Loki. Can be left blank to disable basic auth.
; loki_basic_auth_username = "myuser"

# For "loki" only.
# Optional password for basic authentication on requests sent to Loki. Can be left blank.
; loki_basic_auth_password = "mypass"

# For "loki" only.
# Optional max query length for queries sent to Loki. Default is 721h which matches the default Loki value.
; loki_max_query_length = 360h

# For "loki" only.
# Maximum size in bytes for queries sent to Loki. This limit is applied to user provided filters as well as system defined ones, e.g. applied by access control.
# If filter exceeds the limit, API returns error with code "alerting.state-history.loki.requestTooLong".
# Default is 64kb
;loki_max_query_size = 65536

[unified_alerting.state_history.external_labels]
# Optional extra labels to attach to outbound state history records or log streams.
# Any number of label key-value-pairs can be provided.
; mylabelkey = mylabelvalue

[unified_alerting.state_history.annotations]
# This section controls retention of annotations automatically created while evaluating alert rules
# when alerting state history backend is configured to be annotations (a setting [unified_alerting.state_history].backend

# Configures for how long alert annotations are stored. Default is 0, which keeps them forever.
# This setting should be expressed as an duration. Ex 6h (hours), 10d (days), 2w (weeks), 1M (month).
max_age =

# Configures max number of alert annotations that Grafana stores. Default value is 0, which keeps all alert annotations.
max_annotations_to_keep =

#################################### Recording Rules #####################
[recording_rules]
# Enable recording rules. You must provide write credentials below.
enabled = false

# Target URL (including write path) for recording rules.
url =

# Optional username for basic authentication on recording rule write requests. Can be left blank to disable basic auth
basic_auth_username =

# Optional assword for basic authentication on recording rule write requests. Can be left blank.
basic_auth_password =

# Request timeout for recording rule writes.
timeout = 30s

# Optional custom headers to include in recording rule write requests.
[recording_rules.custom_headers]
# exampleHeader = exampleValue

#################################### Annotations #########################
[annotations]
# Configures the batch size for the annotation clean-up job. This setting is used for dashboard, API, and alert annotations.
;cleanupjob_batchsize = 100

# Enforces the maximum allowed length of the tags for any newly introduced annotations. It can be between 500 and 4096 inclusive (which is the respective's column length). Default value is 500.
# Setting it to a higher value would impact performance therefore is not recommended.
;tags_length = 500

[annotations.dashboard]
# Dashboard annotations means that annotations are associated with the dashboard they are created on.

# Configures how long dashboard annotations are stored. Default is 0, which keeps them forever.
# This setting should be expressed as a duration. Examples: 6h (hours), 10d (days), 2w (weeks), 1M (month).
;max_age =

# Configures max number of dashboard annotations that Grafana stores. Default value is 0, which keeps all dashboard annotations.
;max_annotations_to_keep =

[annotations.api]
# API annotations means that the annotations have been created using the API without any
# association with a dashboard.

# Configures how long Grafana stores API annotations. Default is 0, which keeps them forever.
# This setting should be expressed as a duration. Examples: 6h (hours), 10d (days), 2w (weeks), 1M (month).
;max_age =

# Configures max number of API annotations that Grafana keeps. Default value is 0, which keeps all API annotations.
;max_annotations_to_keep =

#################################### Explore #############################
[explore]
# Enable the Explore section
;enabled = true

#################################### Help #############################
[help]
# Enable the Help section
;enabled = true

#################################### Profile #############################
[profile]
# Enable the Profile section
;enabled = true

#################################### News #############################
[news]
# Enable the news feed section
; news_feed_enabled = true

#################################### Query #############################
[query]
# Set the number of data source queries that can be executed concurrently in mixed queries. Default is the number of CPUs.
;concurrent_query_limit =

#################################### Query History #############################
[query_history]
# Enable the Query history
;enabled = true

#################################### Short Links #############################
[short_links]
# Short links which are never accessed will be deleted as cleanup. Time is in days. Default is 7 days. Max is 365. 0 means they will be deleted approximately every 10 minutes.
;expire_time = 7

#################################### Internal Grafana Metrics ##########################
# Metrics available at HTTP URL /metrics and /metrics/plugins/:pluginId
[metrics]
# Disable / Enable internal metrics
;enabled           = true
# Graphite Publish interval
;interval_seconds  = 10
# Disable total stats (stat_totals_*) metrics to be generated
;disable_total_stats = false
# The interval at which the total stats collector will update the stats. Default is 1800 seconds.
;total_stats_collector_interval_seconds = 1800

#If both are set, basic auth will be required for the metrics endpoints.
; basic_auth_username =
; basic_auth_password =

# Metrics environment info adds dimensions to the `grafana_environment_info` metric, which
# can expose more information about the Grafana instance.
[metrics.environment_info]
#exampleLabel1 = exampleValue1
#exampleLabel2 = exampleValue2

# Send internal metrics to Graphite
[metrics.graphite]
# Enable by setting the address setting (ex localhost:2003)
;address =
;prefix = prod.grafana.%(instance_name)s.

#################################### Grafana.com integration  ##########################
# Url used to import dashboards directly from Grafana.com
[grafana_com]
;url = https://grafana.com
;api_url = https://grafana.com/api
# Grafana instance - Grafana.com integration SSO API token
;sso_api_token = ""

#################################### Distributed tracing ############
# Opentracing is deprecated use opentelemetry instead
[tracing.jaeger]
# Enable by setting the address sending traces to jaeger (ex localhost:6831)
;address = localhost:6831
# Tag that will always be included in when creating new spans. ex (tag1:value1,tag2:value2)
;always_included_tag = tag1:value1
# Type specifies the type of the sampler: const, probabilistic, rateLimiting, or remote
;sampler_type = const
# jaeger samplerconfig param
# for "const" sampler, 0 or 1 for always false/true respectively
# for "probabilistic" sampler, a probability between 0 and 1
# for "rateLimiting" sampler, the number of spans per second
# for "remote" sampler, param is the same as for "probabilistic"
# and indicates the initial sampling rate before the actual one
# is received from the mothership
;sampler_param = 1
# sampling_server_url is the URL of a sampling manager providing a sampling strategy.
;sampling_server_url =
# Whether or not to use Zipkin propagation (x-b3- HTTP headers).
;zipkin_propagation = false
# Setting this to true disables shared RPC spans.
# Not disabling is the most common setting when using Zipkin elsewhere in your infrastructure.
;disable_shared_zipkin_spans = false

[tracing.opentelemetry]
# attributes that will always be included in when creating new spans. ex (key1:value1,key2:value2)
;custom_attributes = key1:value1,key2:value2
# Type specifies the type of the sampler: const, probabilistic, rateLimiting, or remote
; sampler_type = remote
# Sampler configuration parameter
# for "const" sampler, 0 or 1 for always false/true respectively
# for "probabilistic" sampler, a probability between 0.0 and 1.0
# for "rateLimiting" sampler, the number of spans per second
# for "remote" sampler, param is the same as for "probabilistic"
#   and indicates the initial sampling rate before the actual one
#   is received from the sampling server (set at sampling_server_url)
; sampler_param = 0.5
# specifies the URL of the sampling server when sampler_type is remote
; sampling_server_url = http://localhost:5778/sampling

[tracing.opentelemetry.jaeger]
# jaeger destination (ex http://localhost:14268/api/traces)
; address = http://localhost:14268/api/traces
# Propagation specifies the text map propagation format: w3c, jaeger
; propagation = jaeger

# This is a configuration for OTLP exporter with GRPC protocol
[tracing.opentelemetry.otlp]
# otlp destination (ex localhost:4317)
; address = localhost:4317
# Propagation specifies the text map propagation format: w3c, jaeger
; propagation = w3c

#################################### External image storage ##########################
[external_image_storage]
# Used for uploading images to public servers so they can be included in slack/email messages.
# you can choose between (s3, webdav, gcs, azure_blob, local)
;provider =

[external_image_storage.s3]
;endpoint =
;path_style_access =
;bucket =
;region =
;path =
;access_key =
;secret_key =

[external_image_storage.webdav]
;url =
;username =
;password =
;public_url =

[external_image_storage.gcs]
;key_file =
;bucket =
;path =
;enable_signed_urls = false
;signed_url_expiration =

[external_image_storage.azure_blob]
;account_name =
;account_key =
;container_name =
;sas_token_expiration_days =

[external_image_storage.local]
# does not require any configuration

[rendering]
# Options to configure a remote HTTP image rendering service, e.g. using https://github.com/grafana/grafana-image-renderer.
# URL to a remote HTTP image renderer service, e.g. http://localhost:8081/render, will enable Grafana to render panels and dashboards to PNG-images using HTTP requests to an external service.
;server_url =
# If the remote HTTP image renderer service runs on a different server than the Grafana server you may have to configure this to a URL where Grafana is reachable, e.g. http://grafana.domain/.
;callback_url =
# An auth token that will be sent to and verified by the renderer. The renderer will deny any request without an auth token matching the one configured on the renderer side.
;renderer_token = -
# Concurrent render request limit affects when the /render HTTP endpoint is used. Rendering many images at the same time can overload the server,
# which this setting can help protect against by only allowing a certain amount of concurrent requests.
;concurrent_render_request_limit = 30
# Determines the lifetime of the render key used by the image renderer to access and render Grafana.
# This setting should be expressed as a duration. Examples: 10s (seconds), 5m (minutes), 2h (hours).
# Default is 5m. This should be more than enough for most deployments.
# Change the value only if image rendering is failing and you see `Failed to get the render key from cache` in Grafana logs.
;render_key_lifetime = 5m
# Default width for panel screenshot
;default_image_width = 1000
# Default height for panel screenshot
;default_image_height = 500
# Default scale for panel screenshot
;default_image_scale = 1

[panels]
# If set to true Grafana will allow script tags in text panels. Not recommended as it enable XSS vulnerabilities.
;disable_sanitize_html = false

[plugins]
;enable_alpha = false
;app_tls_skip_verify_insecure = false
# Enter a comma-separated list of plugin identifiers to identify plugins to load even if they are unsigned. Plugins with modified signatures are never loaded.
;allow_loading_unsigned_plugins =
# Enable or disable installing / uninstalling / updating plugins directly from within Grafana.
;plugin_admin_enabled = false
;plugin_admin_external_manage_enabled = false
;plugin_catalog_url = https://grafana.com/grafana/plugins/
# Enter a comma-separated list of plugin identifiers to hide in the plugin catalog.
;plugin_catalog_hidden_plugins =
# Log all backend requests for core and external plugins.
;log_backend_requests = false
# Disable download of the public key for verifying plugin signature.
; public_key_retrieval_disabled = false
# Force download of the public key for verifying plugin signature on startup. If disabled, the public key will be retrieved every 10 days.
# Requires public_key_retrieval_disabled to be false to have any effect.
; public_key_retrieval_on_startup = false
# Enter a comma-separated list of plugin identifiers to avoid loading (including core plugins). These plugins will be hidden in the catalog.
; disable_plugins =

#################################### Grafana Live ##########################################
[live]
# max_connections to Grafana Live WebSocket endpoint per Grafana server instance. See Grafana Live docs
# if you are planning to make it higher than default 100 since this can require some OS and infrastructure
# tuning. 0 disables Live, -1 means unlimited connections.
;max_connections = 100

# allowed_origins is a comma-separated list of origins that can establish connection with Grafana Live.
# If not set then origin will be matched over root_url. Supports wildcard symbol "*".
;allowed_origins =

# engine defines an HA (high availability) engine to use for Grafana Live. By default no engine used - in
# this case Live features work only on a single Grafana server. Available options: "redis".
# Setting ha_engine is an EXPERIMENTAL feature.
;ha_engine =

# ha_engine_address sets a connection address for Live HA engine. Depending on engine type address format can differ.
# For now we only support Redis connection address in "host:port" format.
# This option is EXPERIMENTAL.
;ha_engine_address = "127.0.0.1:6379"

# ha_engine_password allows setting an optional password to authenticate with the engine
;ha_engine_password = ""

# ha_prefix is a prefix for keys in the HA engine. It's used to separate keys for different Grafana instances.
;ha_prefix =

#################################### Grafana Image Renderer Plugin ##########################
[plugin.grafana-image-renderer]
# Instruct headless browser instance to use a default timezone when not provided by Grafana, e.g. when rendering panel image of alert.
# See ICU’s metaZones.txt (https://cs.chromium.org/chromium/src/third_party/icu/source/data/misc/metaZones.txt) for a list of supported
# timezone IDs. Fallbacks to TZ environment variable if not set.
;rendering_timezone =

# Instruct headless browser instance to use a default language when not provided by Grafana, e.g. when rendering panel image of alert.
# Please refer to the HTTP header Accept-Language to understand how to format this value, e.g. 'fr-CH, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5'.
;rendering_language =

# Instruct headless browser instance to use a default device scale factor when not provided by Grafana, e.g. when rendering panel image of alert.
# Default is 1. Using a higher value will produce more detailed images (higher DPI), but will require more disk space to store an image.
;rendering_viewport_device_scale_factor =

# Instruct headless browser instance whether to ignore HTTPS errors during navigation. Per default HTTPS errors are not ignored. Due to
# the security risk it's not recommended to ignore HTTPS errors.
;rendering_ignore_https_errors =

# Instruct headless browser instance whether to capture and log verbose information when rendering an image. Default is false and will
# only capture and log error messages. When enabled, debug messages are captured and logged as well.
# For the verbose information to be included in the Grafana server log you have to adjust the rendering log level to debug, configure
# [log].filter = rendering:debug.
;rendering_verbose_logging =

# Instruct headless browser instance whether to output its debug and error messages into running process of remote rendering service.
# Default is false. This can be useful to enable (true) when troubleshooting.
;rendering_dumpio =

# Instruct headless browser instance whether to register metrics for the duration of every rendering step. Default is false.
# This can be useful to enable (true) when optimizing the rendering mode settings to improve the plugin performance or when troubleshooting.
;rendering_timing_metrics =

# Additional arguments to pass to the headless browser instance. Default is --no-sandbox. The list of Chromium flags can be found
# here (https://peter.sh/experiments/chromium-command-line-switches/). Multiple arguments is separated with comma-character.
;rendering_args =

# You can configure the plugin to use a different browser binary instead of the pre-packaged version of Chromium.
# Please note that this is not recommended, since you may encounter problems if the installed version of Chrome/Chromium is not
# compatible with the plugin.
;rendering_chrome_bin =

# Instruct how headless browser instances are created. Default is 'default' and will create a new browser instance on each request.
# Mode 'clustered' will make sure that only a maximum of browsers/incognito pages can execute concurrently.
# Mode 'reusable' will have one browser instance and will create a new incognito page on each request.
;rendering_mode =

# When rendering_mode = clustered, you can instruct how many browsers or incognito pages can execute concurrently. Default is 'browser'
# and will cluster using browser instances.
# Mode 'context' will cluster using incognito pages.
;rendering_clustering_mode =
# When rendering_mode = clustered, you can define the maximum number of browser instances/incognito pages that can execute concurrently. Default is '5'.
;rendering_clustering_max_concurrency =
# When rendering_mode = clustered, you can specify the duration a rendering request can take before it will time out. Default is `30` seconds.
;rendering_clustering_timeout =

# Limit the maximum viewport width, height and device scale factor that can be requested.
;rendering_viewport_max_width =
;rendering_viewport_max_height =
;rendering_viewport_max_device_scale_factor =

# Change the listening host and port of the gRPC server. Default host is 127.0.0.1 and default port is 0 and will automatically assign
# a port not in use.
;grpc_host =
;grpc_port =

[enterprise]
# Path to a valid Grafana Enterprise license.jwt file
;license_path =

[feature_toggles]
# there are currently two ways to enable feature toggles in the `grafana.ini`.
# you can either pass an array of feature you want to enable to the `enable` field or
# configure each toggle by setting the name of the toggle to true/false. Toggles set to true/false
# will take presidence over toggles in the `enable` list.

;enable = feature1,feature2

;feature1 = true
;feature2 = false

[date_formats]
# For information on what formatting patterns that are supported https://momentjs.com/docs/#/displaying/

# Default system date format used in time range picker and other places where full time is displayed
;full_date = YYYY-MM-DD HH:mm:ss

# Used by graph and other places where we only show small intervals
;interval_second = HH:mm:ss
;interval_minute = HH:mm
;interval_hour = MM/DD HH:mm
;interval_day = MM/DD
;interval_month = YYYY-MM
;interval_year = YYYY

# Experimental feature
;use_browser_locale = false

# Default timezone for user preferences. Options are 'browser' for the browser local timezone or a timezone name from IANA Time Zone database, e.g. 'UTC' or 'Europe/Amsterdam' etc.
;default_timezone = browser

[expressions]
# Enable or disable the expressions functionality.
;enabled = true

[geomap]
# Set the JSON configuration for the default basemap
;default_baselayer_config = `{
;  "type": "xyz",
;  "config": {
;    "attribution": "Open street map",
;    "url": "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
;  }
;}`

# Enable or disable loading other base map layers
;enable_custom_baselayers = true

#################################### Support Bundles #####################################
[support_bundles]
# Enable support bundle creation (default: true)
#enabled = true
# Only server admins can generate and view support bundles (default: true)
#server_admin_only = true
# If set, bundles will be encrypted with the provided public keys separated by whitespace
#public_keys = ""

# Move an app plugin referenced by its id (including all its pages) to a specific navigation section
[navigation.app_sections]
# The following will move an app plugin with the id of `my-app-id` under the `cfg` section
# my-app-id = cfg

# Move a specific app plugin page (referenced by its `path` field) to a specific navigation section
[navigation.app_standalone_pages]
# The following will move the page with the path "/a/my-app-id/my-page" from `my-app-id` to the `cfg` section
# /a/my-app-id/my-page = cfg

#################################### Secure Socks5 Datasource Proxy #####################################
[secure_socks_datasource_proxy]
; enabled = false
; root_ca_cert =
; client_key =
; client_cert =
; server_name =
# The address of the socks5 proxy datasources should connect to
; proxy_address =
; show_ui = true
; allow_insecure = false

################################## Feature Management ##############################################
[feature_management]
# Options to configure the experimental Feature Toggle Admin Page feature, which is behind the `featureToggleAdminPage` feature toggle. Use at your own risk.
# Allow editing of feature toggles in the feature management page
;allow_editing = false
# Allow customization of URL for the controller that manages feature toggles
;update_webhook =
# Allow configuring an auth token for feature management update requests
;update_webhook_token =
# Hide specific feature toggles from the feature management page
;hidden_toggles =
# Disable updating specific feature toggles in the feature management page
;read_only_toggles =

#################################### Public Dashboards #####################################
[public_dashboards]
# Set to false to disable public dashboards
;enabled = true

###################################### Cloud Migration ######################################
[cloud_migration]
# Set to true to enable target-side migration UI
;is_target = false
# Token used to send requests to grafana com
;gcom_api_token = ""
# How long to wait for a request sent to gms to start a snapshot to complete
;start_snapshot_timeout = 5s
# How long to wait for a request sent to gms to validate a key to complete
;validate_key_timeout = 5s
# How long to wait for a request sent to gms to get a snapshot status to complete
;get_snapshot_status_timeout = 5s
# How long to wait for a request sent to gms to create a presigned upload url
;create_upload_url_timeout = 5s
# How long to wait for a request sent to gms to report an event
;report_event_timeout = 5s
# How long to wait for a request to fetch an instance to complete
;fetch_instance_timeout = 5s
# How long to wait for a request to create an access policy to complete
;create_access_policy_timeout = 5s
# How long to wait for a request to create to fetch an access policy to complete
;fetch_access_policy_timeout = 5s
# How long to wait for a request to create to delete an access policy to complete
;delete_access_policy_timeout = 5s
# The domain name used to access cms
;domain = grafana-dev.net
# Folder used to store snapshot files. Defaults to the home dir
;snapshot_folder = ""
# Link to form to give feedback on the feature
;feedback_url = ""
# How frequently should the frontend UI poll for changes while resources are migrating
;frontend_poll_interval = 2s

################################## Frontend development configuration ###################################
# Warning! Any settings placed in this section will be available on `process.env.frontend_dev_{foo}` within frontend code
# Any values placed here may be accessible to the UI. Do not place sensitive information here.
[frontend_dev]
# Should UI tests fail when console log/warn/erroring?
# Does not affect the result when running on CI - only for allowing devs to choose this behaviour locally
; fail_tests_on_console = true
~~~
