- proxy
~~~
apiVersion: v1
kind: Pod
metadata:
  name: proxy
  labels:
    name: proxy
spec:
  containers:
  - name: proxy
    #image: nginx:1.25.5
    image: nginxinc/nginx-unprivileged:1.25.5
    #image: registry.access.redhat.com/ubi9/nginx-122:1-59.1712857762
    imagePullPolicy: IfNotPresent
    #imagePullPolicy: Always
    #command: ["sh",  "-c", "sleep infinity"]
    volumeMounts:
    #- name: v1-volume
    #  mountPath: /usr/share/nginx/html
    - name: nginx-conf
      mountPath: /etc/nginx/nginx.conf
      subPath: nginx.conf
    - name: proxy-conf
      mountPath: /etc/nginx/conf.d
    #- name: proxy-conf
    #  mountPath: /etc/nginx/conf.d/proxy.conf
    #  subPath: proxy.conf
  volumes:
  - name: nginx-conf
    configMap:
      name: nginx-conf
  - name: proxy-conf
    configMap:
      name: proxy-conf
---
apiVersion: v1
kind: Service
metadata:
  name: proxy
spec:
  selector:
    name: proxy
  ports:
  - name: web
    protocol: TCP
    port: 80
    targetPort: 80
  - name: proxy
    protocol: TCP
    port: 8080
    targetPort: 8080
  - name: ssh
    protocol: TCP
    port: 8022
    targetPort: 8022
---
apiVersion: v1
kind: Pod
metadata:
  name: network
  labels:
    name: network
spec:
  containers:
  - name: network
    image: prodigy413/network-client:1.0
    imagePullPolicy: IfNotPresent
    #imagePullPolicy: Always
---
apiVersion: v1
data:
  nginx.conf: |2

    worker_processes  auto;

    error_log  /var/log/nginx/error.log warn;
    pid        /tmp/nginx.pid;


    events {
        worker_connections  1024;
    }


    http {
        proxy_temp_path /tmp/proxy_temp;
        client_body_temp_path /tmp/client_temp;
        fastcgi_temp_path /tmp/fastcgi_temp;
        uwsgi_temp_path /tmp/uwsgi_temp;
        scgi_temp_path /tmp/scgi_temp;
        server_tokens off;

        include       /etc/nginx/mime.types;
        default_type  application/octet-stream;

        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for" $request_time';

        access_log  /var/log/nginx/access.log  main;

        sendfile        on;

        keepalive_timeout  65;

        include /etc/nginx/conf.d/*.conf;
    }
kind: ConfigMap
metadata:
  name: nginx-conf
---
apiVersion: v1
data:
  proxy.conf: |
    server {
        listen       8080;
        server_name  localhost;
        client_max_body_size 5M;

        location /nginx_status {
            stub_status on;
            access_log off;
            allow 127.0.0.1;
            deny all;
        }

        location / {
            set $backend_server 10.102.153.254;
            proxy_redirect                      off;
            proxy_set_header Host               $host;
            proxy_set_header X-Real-IP          $remote_addr;
            proxy_set_header X-Forwarded-For    $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto  $scheme;
            proxy_read_timeout                  1m;
            proxy_connect_timeout               1m;
            proxy_pass                          http://$backend_server;
        }
    }
kind: ConfigMap
metadata:
  name: proxy-conf
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: nginx.test.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-for-proxy-test
            port:
              number: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-for-proxy-test
spec:
  selector:
    app: nginx-for-proxy-test
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx-for-proxy-test
  labels:
    app: nginx-for-proxy-test
spec:
  containers:
  - name: nginx-for-proxy-test
    image: nginx:1.25.5
    imagePullPolicy: IfNotPresent
    #imagePullPolicy: Always
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: ssh
  labels:
    name: ssh
spec:
  containers:
  - name: ssh
    image: linuxserver/openssh-server:amd64-version-9.6_p1-r0
    imagePullPolicy: IfNotPresent
    ports:
    - name: http
      containerPort: 2222
    env:
    - name: USER_NAME
      value: "test"
    - name: USER_PASSWORD
      value: "password"
    - name: PASSWORD_ACCESS
      value: "true"
    - name: UPUID
      value: "1000"
    - name: PGID
      value: "1000"
    - name: TZ
      value: "Etc/UTC"
---
apiVersion: v1
kind: Service
metadata:
  name: ssh
spec:
  selector:
    name: ssh
  type: ClusterIP
  ports:
  - name: http
    protocol: TCP
    port: 2222
    targetPort: 2222
~~~

- apache.yaml

~~~
---
kind: Namespace
apiVersion: v1
metadata:
  name: istio-test
  labels:
    name: istio-test
    istio-injection: enabled
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: httpd-ingress
  annotations:
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header X-Forwarded-For "$http_x_forwarded_for";
spec:
  ingressClassName: nginx
  rules:
  - host: httpd.test.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: httpd
            port:
              number: 80
---
apiVersion: v1
kind: Service
metadata:
  name: httpd
spec:
  selector:
    app: httpd
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
---
apiVersion: v1
data:
  httpd.conf: "#\n# This is the main Apache HTTP server configuration file.  It contains
    the\n# configuration directives that give the server its instructions.\n# See
    <URL:http://httpd.apache.org/docs/2.4/> for detailed information.\n# In particular,
    see \n# <URL:http://httpd.apache.org/docs/2.4/mod/directives.html>\n# for a discussion
    of each configuration directive.\n#\n# Do NOT simply read the instructions in
    here without understanding\n# what they do.  They're here only as hints or reminders.
    \ If you are unsure\n# consult the online docs. You have been warned.  \n#\n#
    Configuration and logfile names: If the filenames you specify for many\n# of the
    server's control files begin with \"/\" (or \"drive:/\" for Win32), the\n# server
    will use that explicit path.  If the filenames do *not* begin\n# with \"/\", the
    value of ServerRoot is prepended -- so \"logs/access_log\"\n# with ServerRoot
    set to \"/usr/local/apache2\" will be interpreted by the\n# server as \"/usr/local/apache2/logs/access_log\",
    whereas \"/logs/access_log\" \n# will be interpreted as '/logs/access_log'.\n\n#\n#
    ServerRoot: The top of the directory tree under which the server's\n# configuration,
    error, and log files are kept.\n#\n# Do not add a slash at the end of the directory
    path.  If you point\n# ServerRoot at a non-local disk, be sure to specify a local
    disk on the\n# Mutex directive, if file-based mutexes are used.  If you wish to
    share the\n# same ServerRoot for multiple httpd daemons, you will need to change
    at\n# least PidFile.\n#\nServerRoot \"/usr/local/apache2\"\n\n#\n# Mutex: Allows
    you to set the mutex mechanism and mutex file directory\n# for individual mutexes,
    or change the global defaults\n#\n# Uncomment and change the directory if mutexes
    are file-based and the default\n# mutex file directory is not on a local disk
    or is not appropriate for some\n# other reason.\n#\n# Mutex default:logs\n\n#\n#
    Listen: Allows you to bind Apache to specific IP addresses and/or\n# ports, instead
    of the default. See also the <VirtualHost>\n# directive.\n#\n# Change this to
    Listen on specific IP addresses as shown below to \n# prevent Apache from glomming
    onto all bound IP addresses.\n#\n#Listen 12.34.56.78:80\nListen 80\n\n#\n# Dynamic
    Shared Object (DSO) Support\n#\n# To be able to use the functionality of a module
    which was built as a DSO you\n# have to place corresponding `LoadModule' lines
    at this location so the\n# directives contained in it are actually available _before_
    they are used.\n# Statically compiled modules (those listed by `httpd -l') do
    not need\n# to be loaded here.\n#\n# Example:\n# LoadModule foo_module modules/mod_foo.so\n#\nLoadModule
    mpm_event_module modules/mod_mpm_event.so\n#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so\n#LoadModule
    mpm_worker_module modules/mod_mpm_worker.so\nLoadModule authn_file_module modules/mod_authn_file.so\n#LoadModule
    authn_dbm_module modules/mod_authn_dbm.so\n#LoadModule authn_anon_module modules/mod_authn_anon.so\n#LoadModule
    authn_dbd_module modules/mod_authn_dbd.so\n#LoadModule authn_socache_module modules/mod_authn_socache.so\nLoadModule
    authn_core_module modules/mod_authn_core.so\nLoadModule authz_host_module modules/mod_authz_host.so\nLoadModule
    authz_groupfile_module modules/mod_authz_groupfile.so\nLoadModule authz_user_module
    modules/mod_authz_user.so\n#LoadModule authz_dbm_module modules/mod_authz_dbm.so\n#LoadModule
    authz_owner_module modules/mod_authz_owner.so\n#LoadModule authz_dbd_module modules/mod_authz_dbd.so\nLoadModule
    authz_core_module modules/mod_authz_core.so\n#LoadModule authnz_ldap_module modules/mod_authnz_ldap.so\n#LoadModule
    authnz_fcgi_module modules/mod_authnz_fcgi.so\nLoadModule access_compat_module
    modules/mod_access_compat.so\nLoadModule auth_basic_module modules/mod_auth_basic.so\n#LoadModule
    auth_form_module modules/mod_auth_form.so\n#LoadModule auth_digest_module modules/mod_auth_digest.so\n#LoadModule
    allowmethods_module modules/mod_allowmethods.so\n#LoadModule isapi_module modules/mod_isapi.so\n#LoadModule
    file_cache_module modules/mod_file_cache.so\n#LoadModule cache_module modules/mod_cache.so\n#LoadModule
    cache_disk_module modules/mod_cache_disk.so\n#LoadModule cache_socache_module
    modules/mod_cache_socache.so\n#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so\n#LoadModule
    socache_dbm_module modules/mod_socache_dbm.so\n#LoadModule socache_memcache_module
    modules/mod_socache_memcache.so\n#LoadModule socache_redis_module modules/mod_socache_redis.so\n#LoadModule
    watchdog_module modules/mod_watchdog.so\n#LoadModule macro_module modules/mod_macro.so\n#LoadModule
    dbd_module modules/mod_dbd.so\n#LoadModule bucketeer_module modules/mod_bucketeer.so\n#LoadModule
    dumpio_module modules/mod_dumpio.so\n#LoadModule echo_module modules/mod_echo.so\n#LoadModule
    example_hooks_module modules/mod_example_hooks.so\n#LoadModule case_filter_module
    modules/mod_case_filter.so\n#LoadModule case_filter_in_module modules/mod_case_filter_in.so\n#LoadModule
    example_ipc_module modules/mod_example_ipc.so\n#LoadModule buffer_module modules/mod_buffer.so\n#LoadModule
    data_module modules/mod_data.so\n#LoadModule ratelimit_module modules/mod_ratelimit.so\nLoadModule
    reqtimeout_module modules/mod_reqtimeout.so\n#LoadModule ext_filter_module modules/mod_ext_filter.so\n#LoadModule
    request_module modules/mod_request.so\n#LoadModule include_module modules/mod_include.so\nLoadModule
    filter_module modules/mod_filter.so\n#LoadModule reflector_module modules/mod_reflector.so\n#LoadModule
    substitute_module modules/mod_substitute.so\n#LoadModule sed_module modules/mod_sed.so\n#LoadModule
    charset_lite_module modules/mod_charset_lite.so\n#LoadModule deflate_module modules/mod_deflate.so\n#LoadModule
    xml2enc_module modules/mod_xml2enc.so\n#LoadModule proxy_html_module modules/mod_proxy_html.so\n#LoadModule
    brotli_module modules/mod_brotli.so\nLoadModule mime_module modules/mod_mime.so\n#LoadModule
    ldap_module modules/mod_ldap.so\nLoadModule log_config_module modules/mod_log_config.so\n#LoadModule
    log_debug_module modules/mod_log_debug.so\n#LoadModule log_forensic_module modules/mod_log_forensic.so\n#LoadModule
    logio_module modules/mod_logio.so\n#LoadModule lua_module modules/mod_lua.so\nLoadModule
    env_module modules/mod_env.so\n#LoadModule mime_magic_module modules/mod_mime_magic.so\n#LoadModule
    cern_meta_module modules/mod_cern_meta.so\n#LoadModule expires_module modules/mod_expires.so\nLoadModule
    headers_module modules/mod_headers.so\n#LoadModule ident_module modules/mod_ident.so\n#LoadModule
    usertrack_module modules/mod_usertrack.so\n#LoadModule unique_id_module modules/mod_unique_id.so\nLoadModule
    setenvif_module modules/mod_setenvif.so\nLoadModule version_module modules/mod_version.so\n#LoadModule
    remoteip_module modules/mod_remoteip.so\n#LoadModule proxy_module modules/mod_proxy.so\n#LoadModule
    proxy_connect_module modules/mod_proxy_connect.so\n#LoadModule proxy_ftp_module
    modules/mod_proxy_ftp.so\n#LoadModule proxy_http_module modules/mod_proxy_http.so\n#LoadModule
    proxy_fcgi_module modules/mod_proxy_fcgi.so\n#LoadModule proxy_scgi_module modules/mod_proxy_scgi.so\n#LoadModule
    proxy_uwsgi_module modules/mod_proxy_uwsgi.so\n#LoadModule proxy_fdpass_module
    modules/mod_proxy_fdpass.so\n#LoadModule proxy_wstunnel_module modules/mod_proxy_wstunnel.so\n#LoadModule
    proxy_ajp_module modules/mod_proxy_ajp.so\n#LoadModule proxy_balancer_module modules/mod_proxy_balancer.so\n#LoadModule
    proxy_express_module modules/mod_proxy_express.so\n#LoadModule proxy_hcheck_module
    modules/mod_proxy_hcheck.so\n#LoadModule session_module modules/mod_session.so\n#LoadModule
    session_cookie_module modules/mod_session_cookie.so\n#LoadModule session_crypto_module
    modules/mod_session_crypto.so\n#LoadModule session_dbd_module modules/mod_session_dbd.so\n#LoadModule
    slotmem_shm_module modules/mod_slotmem_shm.so\n#LoadModule slotmem_plain_module
    modules/mod_slotmem_plain.so\n#LoadModule ssl_module modules/mod_ssl.so\n#LoadModule
    optional_hook_export_module modules/mod_optional_hook_export.so\n#LoadModule optional_hook_import_module
    modules/mod_optional_hook_import.so\n#LoadModule optional_fn_import_module modules/mod_optional_fn_import.so\n#LoadModule
    optional_fn_export_module modules/mod_optional_fn_export.so\n#LoadModule dialup_module
    modules/mod_dialup.so\n#LoadModule http2_module modules/mod_http2.so\n#LoadModule
    proxy_http2_module modules/mod_proxy_http2.so\n#LoadModule md_module modules/mod_md.so\n#LoadModule
    lbmethod_byrequests_module modules/mod_lbmethod_byrequests.so\n#LoadModule lbmethod_bytraffic_module
    modules/mod_lbmethod_bytraffic.so\n#LoadModule lbmethod_bybusyness_module modules/mod_lbmethod_bybusyness.so\n#LoadModule
    lbmethod_heartbeat_module modules/mod_lbmethod_heartbeat.so\nLoadModule unixd_module
    modules/mod_unixd.so\n#LoadModule heartbeat_module modules/mod_heartbeat.so\n#LoadModule
    heartmonitor_module modules/mod_heartmonitor.so\n#LoadModule dav_module modules/mod_dav.so\nLoadModule
    status_module modules/mod_status.so\nLoadModule autoindex_module modules/mod_autoindex.so\n#LoadModule
    asis_module modules/mod_asis.so\n#LoadModule info_module modules/mod_info.so\n#LoadModule
    suexec_module modules/mod_suexec.so\n<IfModule !mpm_prefork_module>\n\t#LoadModule
    cgid_module modules/mod_cgid.so\n</IfModule>\n<IfModule mpm_prefork_module>\n\t#LoadModule
    cgi_module modules/mod_cgi.so\n</IfModule>\n#LoadModule dav_fs_module modules/mod_dav_fs.so\n#LoadModule
    dav_lock_module modules/mod_dav_lock.so\n#LoadModule vhost_alias_module modules/mod_vhost_alias.so\n#LoadModule
    negotiation_module modules/mod_negotiation.so\nLoadModule dir_module modules/mod_dir.so\n#LoadModule
    imagemap_module modules/mod_imagemap.so\n#LoadModule actions_module modules/mod_actions.so\n#LoadModule
    speling_module modules/mod_speling.so\n#LoadModule userdir_module modules/mod_userdir.so\nLoadModule
    alias_module modules/mod_alias.so\n#LoadModule rewrite_module modules/mod_rewrite.so\n\n<IfModule
    unixd_module>\n#\n# If you wish httpd to run as a different user or group, you
    must run\n# httpd as root initially and it will switch.  \n#\n# User/Group: The
    name (or #number) of the user/group to run httpd as.\n# It is usually good practice
    to create a dedicated user and group for\n# running httpd, as with most system
    services.\n#\nUser www-data\nGroup www-data\n\n</IfModule>\n\n# 'Main' server
    configuration\n#\n# The directives in this section set up the values used by the
    'main'\n# server, which responds to any requests that aren't handled by a\n# <VirtualHost>
    definition.  These values also provide defaults for\n# any <VirtualHost> containers
    you may define later in the file.\n#\n# All of these directives may appear inside
    <VirtualHost> containers,\n# in which case these default settings will be overridden
    for the\n# virtual host being defined.\n#\n\n#\n# ServerAdmin: Your address, where
    problems with the server should be\n# e-mailed.  This address appears on some
    server-generated pages, such\n# as error documents.  e.g. admin@your-domain.com\n#\nServerAdmin
    you@example.com\n\n#\n# ServerName gives the name and port that the server uses
    to identify itself.\n# This can often be determined automatically, but we recommend
    you specify\n# it explicitly to prevent problems during startup.\n#\n# If your
    host doesn't have a registered DNS name, enter its IP address here.\n#\n#ServerName
    www.example.com:80\n\n#\n# Deny access to the entirety of your server's filesystem.
    You must\n# explicitly permit access to web content directories in other \n# <Directory>
    blocks below.\n#\n<Directory />\n    AllowOverride none\n    Require all denied\n</Directory>\n\n#\n#
    Note that from this point forward you must specifically allow\n# particular features
    to be enabled - so if something's not working as\n# you might expect, make sure
    that you have specifically enabled it\n# below.\n#\n\n#\n# DocumentRoot: The directory
    out of which you will serve your\n# documents. By default, all requests are taken
    from this directory, but\n# symbolic links and aliases may be used to point to
    other locations.\n#\nDocumentRoot \"/usr/local/apache2/htdocs\"\n<Directory \"/usr/local/apache2/htdocs\">\n
    \   #\n    # Possible values for the Options directive are \"None\", \"All\",\n
    \   # or any combination of:\n    #   Indexes Includes FollowSymLinks SymLinksifOwnerMatch
    ExecCGI MultiViews\n    #\n    # Note that \"MultiViews\" must be named *explicitly*
    --- \"Options All\"\n    # doesn't give it to you.\n    #\n    # The Options directive
    is both complicated and important.  Please see\n    # http://httpd.apache.org/docs/2.4/mod/core.html#options\n
    \   # for more information.\n    #\n    Options Indexes FollowSymLinks\n\n    #\n
    \   # AllowOverride controls what directives may be placed in .htaccess files.\n
    \   # It can be \"All\", \"None\", or any combination of the keywords:\n    #
    \  AllowOverride FileInfo AuthConfig Limit\n    #\n    AllowOverride None\n\n
    \   #\n    # Controls who can get stuff from this server.\n    #\n    Require
    all granted\n</Directory>\n\n#\n# DirectoryIndex: sets the file that Apache will
    serve if a directory\n# is requested.\n#\n<IfModule dir_module>\n    DirectoryIndex
    index.html\n</IfModule>\n\n#\n# The following lines prevent .htaccess and .htpasswd
    files from being \n# viewed by Web clients. \n#\n<Files \".ht*\">\n    Require
    all denied\n</Files>\n\n#\n# ErrorLog: The location of the error log file.\n#
    If you do not specify an ErrorLog directive within a <VirtualHost>\n# container,
    error messages relating to that virtual host will be\n# logged here.  If you *do*
    define an error logfile for a <VirtualHost>\n# container, that host's errors will
    be logged there and not here.\n#\nErrorLog /proc/self/fd/2\n\n#\n# LogLevel: Control
    the number of messages logged to the error_log.\n# Possible values include: debug,
    info, notice, warn, error, crit,\n# alert, emerg.\n#\nLogLevel warn\n\n<IfModule
    log_config_module>\n    #\n    # The following directives define some format nicknames
    for use with\n    # a CustomLog directive (see below).\n    #\n    LogFormat \"%h
    %l %u %t \\\"%r\\\" %>s %b \\\"%{Referer}i\\\" \\\"%{User-Agent}i\\\" %{X-Forwarded-For}i\"
    combined\n    LogFormat \"%h %l %u %t \\\"%r\\\" %>s %b %{X-Forwarded-For}i\" common\n\n    <IfModule
    logio_module>\n      # You need to enable mod_logio.c to use %I and %O\n      LogFormat
    \"%h %l %u %t \\\"%r\\\" %>s %b \\\"%{Referer}i\\\" \\\"%{User-Agent}i\\\" %I
    %O %{X-Forwarded-For}i\" combinedio\n    </IfModule>\n\n    #\n    # The location
    and format of the access logfile (Common Logfile Format).\n    # If you do not
    define any access logfiles within a <VirtualHost>\n    # container, they will
    be logged here.  Contrariwise, if you *do*\n    # define per-<VirtualHost> access
    logfiles, transactions will be\n    # logged therein and *not* in this file.\n
    \   #\n    CustomLog /proc/self/fd/1 common\n\n    #\n    # If you prefer a logfile
    with access, agent, and referer information\n    # (Combined Logfile Format) you
    can use the following directive.\n    #\n    #CustomLog \"logs/access_log\" combined\n</IfModule>\n\n<IfModule
    alias_module>\n    #\n    # Redirect: Allows you to tell clients about documents
    that used to \n    # exist in your server's namespace, but do not anymore. The
    client \n    # will make a new request for the document at its new location.\n
    \   # Example:\n    # Redirect permanent /foo http://www.example.com/bar\n\n    #\n
    \   # Alias: Maps web paths into filesystem paths and is used to\n    # access
    content that does not live under the DocumentRoot.\n    # Example:\n    # Alias
    /webpath /full/filesystem/path\n    #\n    # If you include a trailing / on /webpath
    then the server will\n    # require it to be present in the URL.  You will also
    likely\n    # need to provide a <Directory> section to allow access to\n    #
    the filesystem path.\n\n    #\n    # ScriptAlias: This controls which directories
    contain server scripts. \n    # ScriptAliases are essentially the same as Aliases,
    except that\n    # documents in the target directory are treated as applications
    and\n    # run by the server when requested rather than as documents sent to the\n
    \   # client.  The same rules about trailing \"/\" apply to ScriptAlias\n    #
    directives as to Alias.\n    #\n    ScriptAlias /cgi-bin/ \"/usr/local/apache2/cgi-bin/\"\n\n</IfModule>\n\n<IfModule
    cgid_module>\n    #\n    # ScriptSock: On threaded servers, designate the path
    to the UNIX\n    # socket used to communicate with the CGI daemon of mod_cgid.\n
    \   #\n    #Scriptsock cgisock\n</IfModule>\n\n#\n# \"/usr/local/apache2/cgi-bin\"
    should be changed to whatever your ScriptAliased\n# CGI directory exists, if you
    have that configured.\n#\n<Directory \"/usr/local/apache2/cgi-bin\">\n    AllowOverride
    None\n    Options None\n    Require all granted\n</Directory>\n\n<IfModule headers_module>\n
    \   #\n    # Avoid passing HTTP_PROXY environment to CGI's on this or any proxied\n
    \   # backend servers which have lingering \"httpoxy\" defects.\n    # 'Proxy'
    request header is undefined by the IETF, not listed by IANA\n    #\n    RequestHeader
    unset Proxy early\n</IfModule>\n\n<IfModule mime_module>\n    #\n    # TypesConfig
    points to the file containing the list of mappings from\n    # filename extension
    to MIME-type.\n    #\n    TypesConfig conf/mime.types\n\n    #\n    # AddType
    allows you to add to or override the MIME configuration\n    # file specified
    in TypesConfig for specific file types.\n    #\n    #AddType application/x-gzip
    .tgz\n    #\n    # AddEncoding allows you to have certain browsers uncompress\n
    \   # information on the fly. Note: Not all browsers support this.\n    #\n    #AddEncoding
    x-compress .Z\n    #AddEncoding x-gzip .gz .tgz\n    #\n    # If the AddEncoding
    directives above are commented-out, then you\n    # probably should define those
    extensions to indicate media types:\n    #\n    AddType application/x-compress
    .Z\n    AddType application/x-gzip .gz .tgz\n\n    #\n    # AddHandler allows
    you to map certain file extensions to \"handlers\":\n    # actions unrelated to
    filetype. These can be either built into the server\n    # or added with the Action
    directive (see below)\n    #\n    # To use CGI scripts outside of ScriptAliased
    directories:\n    # (You will also need to add \"ExecCGI\" to the \"Options\"
    directive.)\n    #\n    #AddHandler cgi-script .cgi\n\n    # For type maps (negotiated
    resources):\n    #AddHandler type-map var\n\n    #\n    # Filters allow you to
    process content before it is sent to the client.\n    #\n    # To parse .shtml
    files for server-side includes (SSI):\n    # (You will also need to add \"Includes\"
    to the \"Options\" directive.)\n    #\n    #AddType text/html .shtml\n    #AddOutputFilter
    INCLUDES .shtml\n</IfModule>\n\n#\n# The mod_mime_magic module allows the server
    to use various hints from the\n# contents of the file itself to determine its
    type.  The MIMEMagicFile\n# directive tells the module where the hint definitions
    are located.\n#\n#MIMEMagicFile conf/magic\n\n#\n# Customizable error responses
    come in three flavors:\n# 1) plain text 2) local redirects 3) external redirects\n#\n#
    Some examples:\n#ErrorDocument 500 \"The server made a boo boo.\"\n#ErrorDocument
    404 /missing.html\n#ErrorDocument 404 \"/cgi-bin/missing_handler.pl\"\n#ErrorDocument
    402 http://www.example.com/subscription_info.html\n#\n\n#\n# MaxRanges: Maximum
    number of Ranges in a request before\n# returning the entire resource, or one
    of the special\n# values 'default', 'none' or 'unlimited'.\n# Default setting
    is to accept 200 Ranges.\n#MaxRanges unlimited\n\n#\n# EnableMMAP and EnableSendfile:
    On systems that support it, \n# memory-mapping or the sendfile syscall may be
    used to deliver\n# files.  This usually improves server performance, but must\n#
    be turned off when serving from networked-mounted \n# filesystems or if support
    for these functions is otherwise\n# broken on your system.\n# Defaults: EnableMMAP
    On, EnableSendfile Off\n#\n#EnableMMAP off\n#EnableSendfile on\n\n# Supplemental
    configuration\n#\n# The configuration files in the conf/extra/ directory can be
    \n# included to add extra features or to modify the default configuration of \n#
    the server, or you may simply copy their contents here and change as \n# necessary.\n\n#
    Server-pool management (MPM specific)\n#Include conf/extra/httpd-mpm.conf\n\n#
    Multi-language error messages\n#Include conf/extra/httpd-multilang-errordoc.conf\n\n#
    Fancy directory listings\n#Include conf/extra/httpd-autoindex.conf\n\n# Language
    settings\n#Include conf/extra/httpd-languages.conf\n\n# User home directories\n#Include
    conf/extra/httpd-userdir.conf\n\n# Real-time info on requests and configuration\n#Include
    conf/extra/httpd-info.conf\n\n# Virtual hosts\n#Include conf/extra/httpd-vhosts.conf\n\n#
    Local access to the Apache HTTP Server Manual\n#Include conf/extra/httpd-manual.conf\n\n#
    Distributed authoring and versioning (WebDAV)\n#Include conf/extra/httpd-dav.conf\n\n#
    Various default settings\n#Include conf/extra/httpd-default.conf\n\n# Configure
    mod_proxy_html to understand HTML4/XHTML1\n<IfModule proxy_html_module>\nInclude
    conf/extra/proxy-html.conf\n</IfModule>\n\n# Secure (SSL/TLS) connections\n#Include
    conf/extra/httpd-ssl.conf\n#\n# Note: The following must must be present to support\n#
    \      starting without SSL on platforms with no /dev/random equivalent\n#       but
    a statically compiled-in mod_ssl.\n#\n<IfModule ssl_module>\nSSLRandomSeed startup
    builtin\nSSLRandomSeed connect builtin\n</IfModule>\n\n"
kind: ConfigMap
metadata:
  name: conf
---
apiVersion: v1
data:
  httpd.conf: "#\n# This is the main Apache HTTP server configuration file.  It contains
    the\n# configuration directives that give the server its instructions.\n# See
    <URL:http://httpd.apache.org/docs/2.4/> for detailed information.\n# In particular,
    see \n# <URL:http://httpd.apache.org/docs/2.4/mod/directives.html>\n# for a discussion
    of each configuration directive.\n#\n# Do NOT simply read the instructions in
    here without understanding\n# what they do.  They're here only as hints or reminders.
    \ If you are unsure\n# consult the online docs. You have been warned.  \n#\n#
    Configuration and logfile names: If the filenames you specify for many\n# of the
    server's control files begin with \"/\" (or \"drive:/\" for Win32), the\n# server
    will use that explicit path.  If the filenames do *not* begin\n# with \"/\", the
    value of ServerRoot is prepended -- so \"logs/access_log\"\n# with ServerRoot
    set to \"/usr/local/apache2\" will be interpreted by the\n# server as \"/usr/local/apache2/logs/access_log\",
    whereas \"/logs/access_log\" \n# will be interpreted as '/logs/access_log'.\n\n#\n#
    ServerRoot: The top of the directory tree under which the server's\n# configuration,
    error, and log files are kept.\n#\n# Do not add a slash at the end of the directory
    path.  If you point\n# ServerRoot at a non-local disk, be sure to specify a local
    disk on the\n# Mutex directive, if file-based mutexes are used.  If you wish to
    share the\n# same ServerRoot for multiple httpd daemons, you will need to change
    at\n# least PidFile.\n#\nServerRoot \"/usr/local/apache2\"\n\n#\n# Mutex: Allows
    you to set the mutex mechanism and mutex file directory\n# for individual mutexes,
    or change the global defaults\n#\n# Uncomment and change the directory if mutexes
    are file-based and the default\n# mutex file directory is not on a local disk
    or is not appropriate for some\n# other reason.\n#\n# Mutex default:logs\n\n#\n#
    Listen: Allows you to bind Apache to specific IP addresses and/or\n# ports, instead
    of the default. See also the <VirtualHost>\n# directive.\n#\n# Change this to
    Listen on specific IP addresses as shown below to \n# prevent Apache from glomming
    onto all bound IP addresses.\n#\n#Listen 12.34.56.78:80\nListen 80\n\n#\n# Dynamic
    Shared Object (DSO) Support\n#\n# To be able to use the functionality of a module
    which was built as a DSO you\n# have to place corresponding `LoadModule' lines
    at this location so the\n# directives contained in it are actually available _before_
    they are used.\n# Statically compiled modules (those listed by `httpd -l') do
    not need\n# to be loaded here.\n#\n# Example:\n# LoadModule foo_module modules/mod_foo.so\n#\nLoadModule
    mpm_event_module modules/mod_mpm_event.so\n#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so\n#LoadModule
    mpm_worker_module modules/mod_mpm_worker.so\nLoadModule authn_file_module modules/mod_authn_file.so\n#LoadModule
    authn_dbm_module modules/mod_authn_dbm.so\n#LoadModule authn_anon_module modules/mod_authn_anon.so\n#LoadModule
    authn_dbd_module modules/mod_authn_dbd.so\n#LoadModule authn_socache_module modules/mod_authn_socache.so\nLoadModule
    authn_core_module modules/mod_authn_core.so\nLoadModule authz_host_module modules/mod_authz_host.so\nLoadModule
    authz_groupfile_module modules/mod_authz_groupfile.so\nLoadModule authz_user_module
    modules/mod_authz_user.so\n#LoadModule authz_dbm_module modules/mod_authz_dbm.so\n#LoadModule
    authz_owner_module modules/mod_authz_owner.so\n#LoadModule authz_dbd_module modules/mod_authz_dbd.so\nLoadModule
    authz_core_module modules/mod_authz_core.so\n#LoadModule authnz_ldap_module modules/mod_authnz_ldap.so\n#LoadModule
    authnz_fcgi_module modules/mod_authnz_fcgi.so\nLoadModule access_compat_module
    modules/mod_access_compat.so\nLoadModule auth_basic_module modules/mod_auth_basic.so\n#LoadModule
    auth_form_module modules/mod_auth_form.so\n#LoadModule auth_digest_module modules/mod_auth_digest.so\n#LoadModule
    allowmethods_module modules/mod_allowmethods.so\n#LoadModule isapi_module modules/mod_isapi.so\n#LoadModule
    file_cache_module modules/mod_file_cache.so\n#LoadModule cache_module modules/mod_cache.so\n#LoadModule
    cache_disk_module modules/mod_cache_disk.so\n#LoadModule cache_socache_module
    modules/mod_cache_socache.so\n#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so\n#LoadModule
    socache_dbm_module modules/mod_socache_dbm.so\n#LoadModule socache_memcache_module
    modules/mod_socache_memcache.so\n#LoadModule socache_redis_module modules/mod_socache_redis.so\n#LoadModule
    watchdog_module modules/mod_watchdog.so\n#LoadModule macro_module modules/mod_macro.so\n#LoadModule
    dbd_module modules/mod_dbd.so\n#LoadModule bucketeer_module modules/mod_bucketeer.so\n#LoadModule
    dumpio_module modules/mod_dumpio.so\n#LoadModule echo_module modules/mod_echo.so\n#LoadModule
    example_hooks_module modules/mod_example_hooks.so\n#LoadModule case_filter_module
    modules/mod_case_filter.so\n#LoadModule case_filter_in_module modules/mod_case_filter_in.so\n#LoadModule
    example_ipc_module modules/mod_example_ipc.so\n#LoadModule buffer_module modules/mod_buffer.so\n#LoadModule
    data_module modules/mod_data.so\n#LoadModule ratelimit_module modules/mod_ratelimit.so\nLoadModule
    reqtimeout_module modules/mod_reqtimeout.so\n#LoadModule ext_filter_module modules/mod_ext_filter.so\n#LoadModule
    request_module modules/mod_request.so\n#LoadModule include_module modules/mod_include.so\nLoadModule
    filter_module modules/mod_filter.so\n#LoadModule reflector_module modules/mod_reflector.so\n#LoadModule
    substitute_module modules/mod_substitute.so\n#LoadModule sed_module modules/mod_sed.so\n#LoadModule
    charset_lite_module modules/mod_charset_lite.so\n#LoadModule deflate_module modules/mod_deflate.so\n#LoadModule
    xml2enc_module modules/mod_xml2enc.so\n#LoadModule proxy_html_module modules/mod_proxy_html.so\n#LoadModule
    brotli_module modules/mod_brotli.so\nLoadModule mime_module modules/mod_mime.so\n#LoadModule
    ldap_module modules/mod_ldap.so\nLoadModule log_config_module modules/mod_log_config.so\n#LoadModule
    log_debug_module modules/mod_log_debug.so\n#LoadModule log_forensic_module modules/mod_log_forensic.so\n#LoadModule
    logio_module modules/mod_logio.so\n#LoadModule lua_module modules/mod_lua.so\nLoadModule
    env_module modules/mod_env.so\n#LoadModule mime_magic_module modules/mod_mime_magic.so\n#LoadModule
    cern_meta_module modules/mod_cern_meta.so\n#LoadModule expires_module modules/mod_expires.so\nLoadModule
    headers_module modules/mod_headers.so\n#LoadModule ident_module modules/mod_ident.so\n#LoadModule
    usertrack_module modules/mod_usertrack.so\n#LoadModule unique_id_module modules/mod_unique_id.so\nLoadModule
    setenvif_module modules/mod_setenvif.so\nLoadModule version_module modules/mod_version.so\n#LoadModule
    remoteip_module modules/mod_remoteip.so\n#LoadModule proxy_module modules/mod_proxy.so\n#LoadModule
    proxy_connect_module modules/mod_proxy_connect.so\n#LoadModule proxy_ftp_module
    modules/mod_proxy_ftp.so\n#LoadModule proxy_http_module modules/mod_proxy_http.so\n#LoadModule
    proxy_fcgi_module modules/mod_proxy_fcgi.so\n#LoadModule proxy_scgi_module modules/mod_proxy_scgi.so\n#LoadModule
    proxy_uwsgi_module modules/mod_proxy_uwsgi.so\n#LoadModule proxy_fdpass_module
    modules/mod_proxy_fdpass.so\n#LoadModule proxy_wstunnel_module modules/mod_proxy_wstunnel.so\n#LoadModule
    proxy_ajp_module modules/mod_proxy_ajp.so\n#LoadModule proxy_balancer_module modules/mod_proxy_balancer.so\n#LoadModule
    proxy_express_module modules/mod_proxy_express.so\n#LoadModule proxy_hcheck_module
    modules/mod_proxy_hcheck.so\n#LoadModule session_module modules/mod_session.so\n#LoadModule
    session_cookie_module modules/mod_session_cookie.so\n#LoadModule session_crypto_module
    modules/mod_session_crypto.so\n#LoadModule session_dbd_module modules/mod_session_dbd.so\n#LoadModule
    slotmem_shm_module modules/mod_slotmem_shm.so\n#LoadModule slotmem_plain_module
    modules/mod_slotmem_plain.so\n#LoadModule ssl_module modules/mod_ssl.so\n#LoadModule
    optional_hook_export_module modules/mod_optional_hook_export.so\n#LoadModule optional_hook_import_module
    modules/mod_optional_hook_import.so\n#LoadModule optional_fn_import_module modules/mod_optional_fn_import.so\n#LoadModule
    optional_fn_export_module modules/mod_optional_fn_export.so\n#LoadModule dialup_module
    modules/mod_dialup.so\n#LoadModule http2_module modules/mod_http2.so\n#LoadModule
    proxy_http2_module modules/mod_proxy_http2.so\n#LoadModule md_module modules/mod_md.so\n#LoadModule
    lbmethod_byrequests_module modules/mod_lbmethod_byrequests.so\n#LoadModule lbmethod_bytraffic_module
    modules/mod_lbmethod_bytraffic.so\n#LoadModule lbmethod_bybusyness_module modules/mod_lbmethod_bybusyness.so\n#LoadModule
    lbmethod_heartbeat_module modules/mod_lbmethod_heartbeat.so\nLoadModule unixd_module
    modules/mod_unixd.so\n#LoadModule heartbeat_module modules/mod_heartbeat.so\n#LoadModule
    heartmonitor_module modules/mod_heartmonitor.so\n#LoadModule dav_module modules/mod_dav.so\nLoadModule
    status_module modules/mod_status.so\nLoadModule autoindex_module modules/mod_autoindex.so\n#LoadModule
    asis_module modules/mod_asis.so\n#LoadModule info_module modules/mod_info.so\n#LoadModule
    suexec_module modules/mod_suexec.so\n<IfModule !mpm_prefork_module>\n\t#LoadModule
    cgid_module modules/mod_cgid.so\n</IfModule>\n<IfModule mpm_prefork_module>\n\t#LoadModule
    cgi_module modules/mod_cgi.so\n</IfModule>\n#LoadModule dav_fs_module modules/mod_dav_fs.so\n#LoadModule
    dav_lock_module modules/mod_dav_lock.so\n#LoadModule vhost_alias_module modules/mod_vhost_alias.so\n#LoadModule
    negotiation_module modules/mod_negotiation.so\nLoadModule dir_module modules/mod_dir.so\n#LoadModule
    imagemap_module modules/mod_imagemap.so\n#LoadModule actions_module modules/mod_actions.so\n#LoadModule
    speling_module modules/mod_speling.so\n#LoadModule userdir_module modules/mod_userdir.so\nLoadModule
    alias_module modules/mod_alias.so\n#LoadModule rewrite_module modules/mod_rewrite.so\n\n<IfModule
    unixd_module>\n#\n# If you wish httpd to run as a different user or group, you
    must run\n# httpd as root initially and it will switch.  \n#\n# User/Group: The
    name (or #number) of the user/group to run httpd as.\n# It is usually good practice
    to create a dedicated user and group for\n# running httpd, as with most system
    services.\n#\nUser www-data\nGroup www-data\n\n</IfModule>\n\n# 'Main' server
    configuration\n#\n# The directives in this section set up the values used by the
    'main'\n# server, which responds to any requests that aren't handled by a\n# <VirtualHost>
    definition.  These values also provide defaults for\n# any <VirtualHost> containers
    you may define later in the file.\n#\n# All of these directives may appear inside
    <VirtualHost> containers,\n# in which case these default settings will be overridden
    for the\n# virtual host being defined.\n#\n\n#\n# ServerAdmin: Your address, where
    problems with the server should be\n# e-mailed.  This address appears on some
    server-generated pages, such\n# as error documents.  e.g. admin@your-domain.com\n#\nServerAdmin
    you@example.com\n\n#\n# ServerName gives the name and port that the server uses
    to identify itself.\n# This can often be determined automatically, but we recommend
    you specify\n# it explicitly to prevent problems during startup.\n#\n# If your
    host doesn't have a registered DNS name, enter its IP address here.\n#\n#ServerName
    www.example.com:80\n\n#\n# Deny access to the entirety of your server's filesystem.
    You must\n# explicitly permit access to web content directories in other \n# <Directory>
    blocks below.\n#\n<Directory />\n    AllowOverride none\n    Require all denied\n</Directory>\n\n#\n#
    Note that from this point forward you must specifically allow\n# particular features
    to be enabled - so if something's not working as\n# you might expect, make sure
    that you have specifically enabled it\n# below.\n#\n\n#\n# DocumentRoot: The directory
    out of which you will serve your\n# documents. By default, all requests are taken
    from this directory, but\n# symbolic links and aliases may be used to point to
    other locations.\n#\nDocumentRoot \"/usr/local/apache2/htdocs\"\n<Directory \"/usr/local/apache2/htdocs\">\n
    \   #\n    # Possible values for the Options directive are \"None\", \"All\",\n
    \   # or any combination of:\n    #   Indexes Includes FollowSymLinks SymLinksifOwnerMatch
    ExecCGI MultiViews\n    #\n    # Note that \"MultiViews\" must be named *explicitly*
    --- \"Options All\"\n    # doesn't give it to you.\n    #\n    # The Options directive
    is both complicated and important.  Please see\n    # http://httpd.apache.org/docs/2.4/mod/core.html#options\n
    \   # for more information.\n    #\n    Options Indexes FollowSymLinks\n\n    #\n
    \   # AllowOverride controls what directives may be placed in .htaccess files.\n
    \   # It can be \"All\", \"None\", or any combination of the keywords:\n    #
    \  AllowOverride FileInfo AuthConfig Limit\n    #\n    AllowOverride None\n\n
    \   #\n    # Controls who can get stuff from this server.\n    #\n    Require
    all granted\n</Directory>\n\n#\n# DirectoryIndex: sets the file that Apache will
    serve if a directory\n# is requested.\n#\n<IfModule dir_module>\n    DirectoryIndex
    index.html\n</IfModule>\n\n#\n# The following lines prevent .htaccess and .htpasswd
    files from being \n# viewed by Web clients. \n#\n<Files \".ht*\">\n    Require
    all denied\n</Files>\n\n#\n# ErrorLog: The location of the error log file.\n#
    If you do not specify an ErrorLog directive within a <VirtualHost>\n# container,
    error messages relating to that virtual host will be\n# logged here.  If you *do*
    define an error logfile for a <VirtualHost>\n# container, that host's errors will
    be logged there and not here.\n#\nErrorLog /proc/self/fd/2\n\n#\n# LogLevel: Control
    the number of messages logged to the error_log.\n# Possible values include: debug,
    info, notice, warn, error, crit,\n# alert, emerg.\n#\nLogLevel warn\n\n<IfModule
    log_config_module>\n    #\n    # The following directives define some format nicknames
    for use with\n    # a CustomLog directive (see below).\n    #\n    LogFormat \"%h
    %l %u %t \\\"%r\\\" %>s %b \\\"%{Referer}i\\\" \\\"%{User-Agent}i\\\" %{X-Forwarded-For}i\"
    combined\n    LogFormat \"%h %l %u %t \\\"%r\\\" %>s %b %{X-Forwarded-For}i\" common\n\n    <IfModule
    logio_module>\n      # You need to enable mod_logio.c to use %I and %O\n      LogFormat
    \"%h %l %u %t \\\"%r\\\" %>s %b \\\"%{Referer}i\\\" \\\"%{User-Agent}i\\\" %I
    %O %{X-Forwarded-For}i\" combinedio\n    </IfModule>\n\n    #\n    # The location
    and format of the access logfile (Common Logfile Format).\n    # If you do not
    define any access logfiles within a <VirtualHost>\n    # container, they will
    be logged here.  Contrariwise, if you *do*\n    # define per-<VirtualHost> access
    logfiles, transactions will be\n    # logged therein and *not* in this file.\n
    \   #\n    CustomLog /proc/self/fd/1 common\n\n    #\n    # If you prefer a logfile
    with access, agent, and referer information\n    # (Combined Logfile Format) you
    can use the following directive.\n    #\n    #CustomLog \"logs/access_log\" combined\n</IfModule>\n\n<IfModule
    alias_module>\n    #\n    # Redirect: Allows you to tell clients about documents
    that used to \n    # exist in your server's namespace, but do not anymore. The
    client \n    # will make a new request for the document at its new location.\n
    \   # Example:\n    # Redirect permanent /foo http://www.example.com/bar\n\n    #\n
    \   # Alias: Maps web paths into filesystem paths and is used to\n    # access
    content that does not live under the DocumentRoot.\n    # Example:\n    # Alias
    /webpath /full/filesystem/path\n    #\n    # If you include a trailing / on /webpath
    then the server will\n    # require it to be present in the URL.  You will also
    likely\n    # need to provide a <Directory> section to allow access to\n    #
    the filesystem path.\n\n    #\n    # ScriptAlias: This controls which directories
    contain server scripts. \n    # ScriptAliases are essentially the same as Aliases,
    except that\n    # documents in the target directory are treated as applications
    and\n    # run by the server when requested rather than as documents sent to the\n
    \   # client.  The same rules about trailing \"/\" apply to ScriptAlias\n    #
    directives as to Alias.\n    #\n    ScriptAlias /cgi-bin/ \"/usr/local/apache2/cgi-bin/\"\n\n</IfModule>\n\n<IfModule
    cgid_module>\n    #\n    # ScriptSock: On threaded servers, designate the path
    to the UNIX\n    # socket used to communicate with the CGI daemon of mod_cgid.\n
    \   #\n    #Scriptsock cgisock\n</IfModule>\n\n#\n# \"/usr/local/apache2/cgi-bin\"
    should be changed to whatever your ScriptAliased\n# CGI directory exists, if you
    have that configured.\n#\n<Directory \"/usr/local/apache2/cgi-bin\">\n    AllowOverride
    None\n    Options None\n    Require all granted\n</Directory>\n\n<IfModule headers_module>\n
    \   #\n    # Avoid passing HTTP_PROXY environment to CGI's on this or any proxied\n
    \   # backend servers which have lingering \"httpoxy\" defects.\n    # 'Proxy'
    request header is undefined by the IETF, not listed by IANA\n    #\n    RequestHeader
    unset Proxy early\n</IfModule>\n\n<IfModule mime_module>\n    #\n    # TypesConfig
    points to the file containing the list of mappings from\n    # filename extension
    to MIME-type.\n    #\n    TypesConfig conf/mime.types\n\n    #\n    # AddType
    allows you to add to or override the MIME configuration\n    # file specified
    in TypesConfig for specific file types.\n    #\n    #AddType application/x-gzip
    .tgz\n    #\n    # AddEncoding allows you to have certain browsers uncompress\n
    \   # information on the fly. Note: Not all browsers support this.\n    #\n    #AddEncoding
    x-compress .Z\n    #AddEncoding x-gzip .gz .tgz\n    #\n    # If the AddEncoding
    directives above are commented-out, then you\n    # probably should define those
    extensions to indicate media types:\n    #\n    AddType application/x-compress
    .Z\n    AddType application/x-gzip .gz .tgz\n\n    #\n    # AddHandler allows
    you to map certain file extensions to \"handlers\":\n    # actions unrelated to
    filetype. These can be either built into the server\n    # or added with the Action
    directive (see below)\n    #\n    # To use CGI scripts outside of ScriptAliased
    directories:\n    # (You will also need to add \"ExecCGI\" to the \"Options\"
    directive.)\n    #\n    #AddHandler cgi-script .cgi\n\n    # For type maps (negotiated
    resources):\n    #AddHandler type-map var\n\n    #\n    # Filters allow you to
    process content before it is sent to the client.\n    #\n    # To parse .shtml
    files for server-side includes (SSI):\n    # (You will also need to add \"Includes\"
    to the \"Options\" directive.)\n    #\n    #AddType text/html .shtml\n    #AddOutputFilter
    INCLUDES .shtml\n</IfModule>\n\n#\n# The mod_mime_magic module allows the server
    to use various hints from the\n# contents of the file itself to determine its
    type.  The MIMEMagicFile\n# directive tells the module where the hint definitions
    are located.\n#\n#MIMEMagicFile conf/magic\n\n#\n# Customizable error responses
    come in three flavors:\n# 1) plain text 2) local redirects 3) external redirects\n#\n#
    Some examples:\n#ErrorDocument 500 \"The server made a boo boo.\"\n#ErrorDocument
    404 /missing.html\n#ErrorDocument 404 \"/cgi-bin/missing_handler.pl\"\n#ErrorDocument
    402 http://www.example.com/subscription_info.html\n#\n\n#\n# MaxRanges: Maximum
    number of Ranges in a request before\n# returning the entire resource, or one
    of the special\n# values 'default', 'none' or 'unlimited'.\n# Default setting
    is to accept 200 Ranges.\n#MaxRanges unlimited\n\n#\n# EnableMMAP and EnableSendfile:
    On systems that support it, \n# memory-mapping or the sendfile syscall may be
    used to deliver\n# files.  This usually improves server performance, but must\n#
    be turned off when serving from networked-mounted \n# filesystems or if support
    for these functions is otherwise\n# broken on your system.\n# Defaults: EnableMMAP
    On, EnableSendfile Off\n#\n#EnableMMAP off\n#EnableSendfile on\n\n# Supplemental
    configuration\n#\n# The configuration files in the conf/extra/ directory can be
    \n# included to add extra features or to modify the default configuration of \n#
    the server, or you may simply copy their contents here and change as \n# necessary.\n\n#
    Server-pool management (MPM specific)\n#Include conf/extra/httpd-mpm.conf\n\n#
    Multi-language error messages\n#Include conf/extra/httpd-multilang-errordoc.conf\n\n#
    Fancy directory listings\n#Include conf/extra/httpd-autoindex.conf\n\n# Language
    settings\n#Include conf/extra/httpd-languages.conf\n\n# User home directories\n#Include
    conf/extra/httpd-userdir.conf\n\n# Real-time info on requests and configuration\n#Include
    conf/extra/httpd-info.conf\n\n# Virtual hosts\n#Include conf/extra/httpd-vhosts.conf\n\n#
    Local access to the Apache HTTP Server Manual\n#Include conf/extra/httpd-manual.conf\n\n#
    Distributed authoring and versioning (WebDAV)\n#Include conf/extra/httpd-dav.conf\n\n#
    Various default settings\n#Include conf/extra/httpd-default.conf\n\n# Configure
    mod_proxy_html to understand HTML4/XHTML1\n<IfModule proxy_html_module>\nInclude
    conf/extra/proxy-html.conf\n</IfModule>\n\n# Secure (SSL/TLS) connections\n#Include
    conf/extra/httpd-ssl.conf\n#\n# Note: The following must must be present to support\n#
    \      starting without SSL on platforms with no /dev/random equivalent\n#       but
    a statically compiled-in mod_ssl.\n#\n<IfModule ssl_module>\nSSLRandomSeed startup
    builtin\nSSLRandomSeed connect builtin\n</IfModule>\n\n"
kind: ConfigMap
metadata:
  name: conf
  namespace: istio-test
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpd
  labels:
    app: httpd
spec:
  selector:
    matchLabels:
      app: httpd
  replicas: 1
  template:
    metadata:
      labels:
        app: httpd
    spec:
      containers:
      - name: httpd
        image: httpd:2.4
        volumeMounts:
        - name: conf
          mountPath: /usr/local/apache2/conf/httpd.conf
          subPath: httpd.conf
      volumes:
      - name: conf
        configMap:
          name: conf
          items:
          - key: httpd.conf
            path: httpd.conf
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx-client
spec:
  containers:
  - name: nginx
    image: nginx:1.25.3
---
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: test-gw
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: test-vs
  namespace: istio-test
spec:
  gateways:
  - istio-system/test-gw
  hosts:
  - "httpd-istio.test.local"
  http:
  - route:
    - destination:
        host: httpd
        port:
          number: 80
---
apiVersion: v1
kind: Service
metadata:
  name: httpd
  namespace: istio-test
spec:
  selector:
    app: httpd
  ports:
  - name: http
    port: 80
    targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpd
  labels:
    app: httpd
  namespace: istio-test
spec:
  selector:
    matchLabels:
      app: httpd
  replicas: 1
  template:
    metadata:
      labels:
        app: httpd
    spec:
      containers:
      - name: httpd
        image: httpd:2.4
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - name: conf
          mountPath: /usr/local/apache2/conf/httpd.conf
          subPath: httpd.conf
      volumes:
      - name: conf
        configMap:
          name: conf
          items:
          - key: httpd.conf
            path: httpd.conf
~~~

- deploy.yaml
~~~
---
kind: Namespace
apiVersion: v1
metadata:
  name: istio-test
  labels:
    name: istio-test
    istio-injection: enabled
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  annotations:
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header X-Forwarded-For "$http_x_forwarded_for";
spec:
  ingressClassName: nginx
  rules:
  - host: nginx.test.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
---
apiVersion: v1
data:
  nginx.conf: |
    user  nginx;
    worker_processes  auto;

    error_log  /var/log/nginx/error.log notice;
    pid        /var/run/nginx.pid;


    events {
        worker_connections  1024;
    }


    http {
        include       /etc/nginx/mime.types;
        default_type  application/octet-stream;

        server_tokens on;

        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

        access_log  /var/log/nginx/access.log  main;

        sendfile        on;
        #tcp_nopush     on;

        keepalive_timeout  65;

        #gzip  on;

        include /etc/nginx/conf.d/*.conf;
    }
kind: ConfigMap
metadata:
  name: conf
---
apiVersion: v1
data:
  nginx.conf: |
    user  nginx;
    worker_processes  auto;

    error_log  /var/log/nginx/error.log notice;
    pid        /var/run/nginx.pid;


    events {
        worker_connections  1024;
    }


    http {
        include       /etc/nginx/mime.types;
        default_type  application/octet-stream;

        server_tokens on;

        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

        access_log  /var/log/nginx/access.log  main;

        sendfile        on;
        #tcp_nopush     on;

        keepalive_timeout  65;

        #gzip  on;

        include /etc/nginx/conf.d/*.conf;
    }
kind: ConfigMap
metadata:
  name: conf
  namespace: istio-test
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx01
        image: nginx:1.25.3
        volumeMounts:
        - name: conf
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
      volumes:
      - name: conf
        configMap:
          name: conf
          items:
          - key: nginx.conf
            path: nginx.conf
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx-client
spec:
  containers:
  - name: nginx
    image: nginx:1.25.3
---
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: test-gw
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: test-vs
  namespace: istio-test
spec:
  gateways:
  - istio-system/test-gw
  hosts:
  - "nginx-istio.test.local"
  http:
  - route:
    - destination:
        host: nginx
        port:
          number: 80
    retries:
      attempts: 2
      retryOn: "429"
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: test-vs-internal
  namespace: istio-test
spec:
  gateways:
  - istio-system/test-gw
  hosts:
  - "ngix.istio-test.svc.cluster.local"
  http:
  - route:
    - destination:
        host: nginx
        port:
          number: 80
    retries:
      attempts: 2
      retryOn: "429"
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: istio-test
spec:
  selector:
    app: nginx
  ports:
  - name: http
    port: 80
    targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
  namespace: istio-test
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - name: conf
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
      volumes:
      - name: conf
        configMap:
          name: conf
          items:
          - key: nginx.conf
            path: nginx.conf
~~~

- httpd.conf
~~~
#
# This is the main Apache HTTP server configuration file.  It contains the
# configuration directives that give the server its instructions.
# See <URL:http://httpd.apache.org/docs/2.4/> for detailed information.
# In particular, see 
# <URL:http://httpd.apache.org/docs/2.4/mod/directives.html>
# for a discussion of each configuration directive.
#
# Do NOT simply read the instructions in here without understanding
# what they do.  They're here only as hints or reminders.  If you are unsure
# consult the online docs. You have been warned.  
#
# Configuration and logfile names: If the filenames you specify for many
# of the server's control files begin with "/" (or "drive:/" for Win32), the
# server will use that explicit path.  If the filenames do *not* begin
# with "/", the value of ServerRoot is prepended -- so "logs/access_log"
# with ServerRoot set to "/usr/local/apache2" will be interpreted by the
# server as "/usr/local/apache2/logs/access_log", whereas "/logs/access_log" 
# will be interpreted as '/logs/access_log'.

#
# ServerRoot: The top of the directory tree under which the server's
# configuration, error, and log files are kept.
#
# Do not add a slash at the end of the directory path.  If you point
# ServerRoot at a non-local disk, be sure to specify a local disk on the
# Mutex directive, if file-based mutexes are used.  If you wish to share the
# same ServerRoot for multiple httpd daemons, you will need to change at
# least PidFile.
#
ServerRoot "/usr/local/apache2"

#
# Mutex: Allows you to set the mutex mechanism and mutex file directory
# for individual mutexes, or change the global defaults
#
# Uncomment and change the directory if mutexes are file-based and the default
# mutex file directory is not on a local disk or is not appropriate for some
# other reason.
#
# Mutex default:logs

#
# Listen: Allows you to bind Apache to specific IP addresses and/or
# ports, instead of the default. See also the <VirtualHost>
# directive.
#
# Change this to Listen on specific IP addresses as shown below to 
# prevent Apache from glomming onto all bound IP addresses.
#
#Listen 12.34.56.78:80
Listen 80

#
# Dynamic Shared Object (DSO) Support
#
# To be able to use the functionality of a module which was built as a DSO you
# have to place corresponding `LoadModule' lines at this location so the
# directives contained in it are actually available _before_ they are used.
# Statically compiled modules (those listed by `httpd -l') do not need
# to be loaded here.
#
# Example:
# LoadModule foo_module modules/mod_foo.so
#
LoadModule mpm_event_module modules/mod_mpm_event.so
#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so
#LoadModule mpm_worker_module modules/mod_mpm_worker.so
LoadModule authn_file_module modules/mod_authn_file.so
#LoadModule authn_dbm_module modules/mod_authn_dbm.so
#LoadModule authn_anon_module modules/mod_authn_anon.so
#LoadModule authn_dbd_module modules/mod_authn_dbd.so
#LoadModule authn_socache_module modules/mod_authn_socache.so
LoadModule authn_core_module modules/mod_authn_core.so
LoadModule authz_host_module modules/mod_authz_host.so
LoadModule authz_groupfile_module modules/mod_authz_groupfile.so
LoadModule authz_user_module modules/mod_authz_user.so
#LoadModule authz_dbm_module modules/mod_authz_dbm.so
#LoadModule authz_owner_module modules/mod_authz_owner.so
#LoadModule authz_dbd_module modules/mod_authz_dbd.so
LoadModule authz_core_module modules/mod_authz_core.so
#LoadModule authnz_ldap_module modules/mod_authnz_ldap.so
#LoadModule authnz_fcgi_module modules/mod_authnz_fcgi.so
LoadModule access_compat_module modules/mod_access_compat.so
LoadModule auth_basic_module modules/mod_auth_basic.so
#LoadModule auth_form_module modules/mod_auth_form.so
#LoadModule auth_digest_module modules/mod_auth_digest.so
#LoadModule allowmethods_module modules/mod_allowmethods.so
#LoadModule isapi_module modules/mod_isapi.so
#LoadModule file_cache_module modules/mod_file_cache.so
#LoadModule cache_module modules/mod_cache.so
#LoadModule cache_disk_module modules/mod_cache_disk.so
#LoadModule cache_socache_module modules/mod_cache_socache.so
#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so
#LoadModule socache_dbm_module modules/mod_socache_dbm.so
#LoadModule socache_memcache_module modules/mod_socache_memcache.so
#LoadModule socache_redis_module modules/mod_socache_redis.so
#LoadModule watchdog_module modules/mod_watchdog.so
#LoadModule macro_module modules/mod_macro.so
#LoadModule dbd_module modules/mod_dbd.so
#LoadModule bucketeer_module modules/mod_bucketeer.so
#LoadModule dumpio_module modules/mod_dumpio.so
#LoadModule echo_module modules/mod_echo.so
#LoadModule example_hooks_module modules/mod_example_hooks.so
#LoadModule case_filter_module modules/mod_case_filter.so
#LoadModule case_filter_in_module modules/mod_case_filter_in.so
#LoadModule example_ipc_module modules/mod_example_ipc.so
#LoadModule buffer_module modules/mod_buffer.so
#LoadModule data_module modules/mod_data.so
#LoadModule ratelimit_module modules/mod_ratelimit.so
LoadModule reqtimeout_module modules/mod_reqtimeout.so
#LoadModule ext_filter_module modules/mod_ext_filter.so
#LoadModule request_module modules/mod_request.so
#LoadModule include_module modules/mod_include.so
LoadModule filter_module modules/mod_filter.so
#LoadModule reflector_module modules/mod_reflector.so
#LoadModule substitute_module modules/mod_substitute.so
#LoadModule sed_module modules/mod_sed.so
#LoadModule charset_lite_module modules/mod_charset_lite.so
#LoadModule deflate_module modules/mod_deflate.so
#LoadModule xml2enc_module modules/mod_xml2enc.so
#LoadModule proxy_html_module modules/mod_proxy_html.so
#LoadModule brotli_module modules/mod_brotli.so
LoadModule mime_module modules/mod_mime.so
#LoadModule ldap_module modules/mod_ldap.so
LoadModule log_config_module modules/mod_log_config.so
#LoadModule log_debug_module modules/mod_log_debug.so
#LoadModule log_forensic_module modules/mod_log_forensic.so
#LoadModule logio_module modules/mod_logio.so
#LoadModule lua_module modules/mod_lua.so
LoadModule env_module modules/mod_env.so
#LoadModule mime_magic_module modules/mod_mime_magic.so
#LoadModule cern_meta_module modules/mod_cern_meta.so
#LoadModule expires_module modules/mod_expires.so
LoadModule headers_module modules/mod_headers.so
#LoadModule ident_module modules/mod_ident.so
#LoadModule usertrack_module modules/mod_usertrack.so
#LoadModule unique_id_module modules/mod_unique_id.so
LoadModule setenvif_module modules/mod_setenvif.so
LoadModule version_module modules/mod_version.so
#LoadModule remoteip_module modules/mod_remoteip.so
#LoadModule proxy_module modules/mod_proxy.so
#LoadModule proxy_connect_module modules/mod_proxy_connect.so
#LoadModule proxy_ftp_module modules/mod_proxy_ftp.so
#LoadModule proxy_http_module modules/mod_proxy_http.so
#LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so
#LoadModule proxy_scgi_module modules/mod_proxy_scgi.so
#LoadModule proxy_uwsgi_module modules/mod_proxy_uwsgi.so
#LoadModule proxy_fdpass_module modules/mod_proxy_fdpass.so
#LoadModule proxy_wstunnel_module modules/mod_proxy_wstunnel.so
#LoadModule proxy_ajp_module modules/mod_proxy_ajp.so
#LoadModule proxy_balancer_module modules/mod_proxy_balancer.so
#LoadModule proxy_express_module modules/mod_proxy_express.so
#LoadModule proxy_hcheck_module modules/mod_proxy_hcheck.so
#LoadModule session_module modules/mod_session.so
#LoadModule session_cookie_module modules/mod_session_cookie.so
#LoadModule session_crypto_module modules/mod_session_crypto.so
#LoadModule session_dbd_module modules/mod_session_dbd.so
#LoadModule slotmem_shm_module modules/mod_slotmem_shm.so
#LoadModule slotmem_plain_module modules/mod_slotmem_plain.so
#LoadModule ssl_module modules/mod_ssl.so
#LoadModule optional_hook_export_module modules/mod_optional_hook_export.so
#LoadModule optional_hook_import_module modules/mod_optional_hook_import.so
#LoadModule optional_fn_import_module modules/mod_optional_fn_import.so
#LoadModule optional_fn_export_module modules/mod_optional_fn_export.so
#LoadModule dialup_module modules/mod_dialup.so
#LoadModule http2_module modules/mod_http2.so
#LoadModule proxy_http2_module modules/mod_proxy_http2.so
#LoadModule md_module modules/mod_md.so
#LoadModule lbmethod_byrequests_module modules/mod_lbmethod_byrequests.so
#LoadModule lbmethod_bytraffic_module modules/mod_lbmethod_bytraffic.so
#LoadModule lbmethod_bybusyness_module modules/mod_lbmethod_bybusyness.so
#LoadModule lbmethod_heartbeat_module modules/mod_lbmethod_heartbeat.so
LoadModule unixd_module modules/mod_unixd.so
#LoadModule heartbeat_module modules/mod_heartbeat.so
#LoadModule heartmonitor_module modules/mod_heartmonitor.so
#LoadModule dav_module modules/mod_dav.so
LoadModule status_module modules/mod_status.so
LoadModule autoindex_module modules/mod_autoindex.so
#LoadModule asis_module modules/mod_asis.so
#LoadModule info_module modules/mod_info.so
#LoadModule suexec_module modules/mod_suexec.so
<IfModule !mpm_prefork_module>
	#LoadModule cgid_module modules/mod_cgid.so
</IfModule>
<IfModule mpm_prefork_module>
	#LoadModule cgi_module modules/mod_cgi.so
</IfModule>
#LoadModule dav_fs_module modules/mod_dav_fs.so
#LoadModule dav_lock_module modules/mod_dav_lock.so
#LoadModule vhost_alias_module modules/mod_vhost_alias.so
#LoadModule negotiation_module modules/mod_negotiation.so
LoadModule dir_module modules/mod_dir.so
#LoadModule imagemap_module modules/mod_imagemap.so
#LoadModule actions_module modules/mod_actions.so
#LoadModule speling_module modules/mod_speling.so
#LoadModule userdir_module modules/mod_userdir.so
LoadModule alias_module modules/mod_alias.so
#LoadModule rewrite_module modules/mod_rewrite.so

<IfModule unixd_module>
#
# If you wish httpd to run as a different user or group, you must run
# httpd as root initially and it will switch.  
#
# User/Group: The name (or #number) of the user/group to run httpd as.
# It is usually good practice to create a dedicated user and group for
# running httpd, as with most system services.
#
User www-data
Group www-data

</IfModule>

# 'Main' server configuration
#
# The directives in this section set up the values used by the 'main'
# server, which responds to any requests that aren't handled by a
# <VirtualHost> definition.  These values also provide defaults for
# any <VirtualHost> containers you may define later in the file.
#
# All of these directives may appear inside <VirtualHost> containers,
# in which case these default settings will be overridden for the
# virtual host being defined.
#

#
# ServerAdmin: Your address, where problems with the server should be
# e-mailed.  This address appears on some server-generated pages, such
# as error documents.  e.g. admin@your-domain.com
#
ServerAdmin you@example.com

#
# ServerName gives the name and port that the server uses to identify itself.
# This can often be determined automatically, but we recommend you specify
# it explicitly to prevent problems during startup.
#
# If your host doesn't have a registered DNS name, enter its IP address here.
#
#ServerName www.example.com:80

#
# Deny access to the entirety of your server's filesystem. You must
# explicitly permit access to web content directories in other 
# <Directory> blocks below.
#
<Directory />
    AllowOverride none
    Require all denied
</Directory>

#
# Note that from this point forward you must specifically allow
# particular features to be enabled - so if something's not working as
# you might expect, make sure that you have specifically enabled it
# below.
#

#
# DocumentRoot: The directory out of which you will serve your
# documents. By default, all requests are taken from this directory, but
# symbolic links and aliases may be used to point to other locations.
#
DocumentRoot "/usr/local/apache2/htdocs"
<Directory "/usr/local/apache2/htdocs">
    #
    # Possible values for the Options directive are "None", "All",
    # or any combination of:
    #   Indexes Includes FollowSymLinks SymLinksifOwnerMatch ExecCGI MultiViews
    #
    # Note that "MultiViews" must be named *explicitly* --- "Options All"
    # doesn't give it to you.
    #
    # The Options directive is both complicated and important.  Please see
    # http://httpd.apache.org/docs/2.4/mod/core.html#options
    # for more information.
    #
    Options Indexes FollowSymLinks

    #
    # AllowOverride controls what directives may be placed in .htaccess files.
    # It can be "All", "None", or any combination of the keywords:
    #   AllowOverride FileInfo AuthConfig Limit
    #
    AllowOverride None

    #
    # Controls who can get stuff from this server.
    #
    Require all granted
</Directory>

#
# DirectoryIndex: sets the file that Apache will serve if a directory
# is requested.
#
<IfModule dir_module>
    DirectoryIndex index.html
</IfModule>

#
# The following lines prevent .htaccess and .htpasswd files from being 
# viewed by Web clients. 
#
<Files ".ht*">
    Require all denied
</Files>

#
# ErrorLog: The location of the error log file.
# If you do not specify an ErrorLog directive within a <VirtualHost>
# container, error messages relating to that virtual host will be
# logged here.  If you *do* define an error logfile for a <VirtualHost>
# container, that host's errors will be logged there and not here.
#
ErrorLog /proc/self/fd/2

#
# LogLevel: Control the number of messages logged to the error_log.
# Possible values include: debug, info, notice, warn, error, crit,
# alert, emerg.
#
LogLevel warn

<IfModule log_config_module>
    #
    # The following directives define some format nicknames for use with
    # a CustomLog directive (see below).
    #
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %{X-Forwarded-For}i" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b %{X-Forwarded-For}i" common

    <IfModule logio_module>
      # You need to enable mod_logio.c to use %I and %O
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O %{X-Forwarded-For}i" combinedio
    </IfModule>

    #
    # The location and format of the access logfile (Common Logfile Format).
    # If you do not define any access logfiles within a <VirtualHost>
    # container, they will be logged here.  Contrariwise, if you *do*
    # define per-<VirtualHost> access logfiles, transactions will be
    # logged therein and *not* in this file.
    #
    CustomLog /proc/self/fd/1 common

    #
    # If you prefer a logfile with access, agent, and referer information
    # (Combined Logfile Format) you can use the following directive.
    #
    #CustomLog "logs/access_log" combined
</IfModule>

<IfModule alias_module>
    #
    # Redirect: Allows you to tell clients about documents that used to 
    # exist in your server's namespace, but do not anymore. The client 
    # will make a new request for the document at its new location.
    # Example:
    # Redirect permanent /foo http://www.example.com/bar

    #
    # Alias: Maps web paths into filesystem paths and is used to
    # access content that does not live under the DocumentRoot.
    # Example:
    # Alias /webpath /full/filesystem/path
    #
    # If you include a trailing / on /webpath then the server will
    # require it to be present in the URL.  You will also likely
    # need to provide a <Directory> section to allow access to
    # the filesystem path.

    #
    # ScriptAlias: This controls which directories contain server scripts. 
    # ScriptAliases are essentially the same as Aliases, except that
    # documents in the target directory are treated as applications and
    # run by the server when requested rather than as documents sent to the
    # client.  The same rules about trailing "/" apply to ScriptAlias
    # directives as to Alias.
    #
    ScriptAlias /cgi-bin/ "/usr/local/apache2/cgi-bin/"

</IfModule>

<IfModule cgid_module>
    #
    # ScriptSock: On threaded servers, designate the path to the UNIX
    # socket used to communicate with the CGI daemon of mod_cgid.
    #
    #Scriptsock cgisock
</IfModule>

#
# "/usr/local/apache2/cgi-bin" should be changed to whatever your ScriptAliased
# CGI directory exists, if you have that configured.
#
<Directory "/usr/local/apache2/cgi-bin">
    AllowOverride None
    Options None
    Require all granted
</Directory>

<IfModule headers_module>
    #
    # Avoid passing HTTP_PROXY environment to CGI's on this or any proxied
    # backend servers which have lingering "httpoxy" defects.
    # 'Proxy' request header is undefined by the IETF, not listed by IANA
    #
    RequestHeader unset Proxy early
</IfModule>

<IfModule mime_module>
    #
    # TypesConfig points to the file containing the list of mappings from
    # filename extension to MIME-type.
    #
    TypesConfig conf/mime.types

    #
    # AddType allows you to add to or override the MIME configuration
    # file specified in TypesConfig for specific file types.
    #
    #AddType application/x-gzip .tgz
    #
    # AddEncoding allows you to have certain browsers uncompress
    # information on the fly. Note: Not all browsers support this.
    #
    #AddEncoding x-compress .Z
    #AddEncoding x-gzip .gz .tgz
    #
    # If the AddEncoding directives above are commented-out, then you
    # probably should define those extensions to indicate media types:
    #
    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz

    #
    # AddHandler allows you to map certain file extensions to "handlers":
    # actions unrelated to filetype. These can be either built into the server
    # or added with the Action directive (see below)
    #
    # To use CGI scripts outside of ScriptAliased directories:
    # (You will also need to add "ExecCGI" to the "Options" directive.)
    #
    #AddHandler cgi-script .cgi

    # For type maps (negotiated resources):
    #AddHandler type-map var

    #
    # Filters allow you to process content before it is sent to the client.
    #
    # To parse .shtml files for server-side includes (SSI):
    # (You will also need to add "Includes" to the "Options" directive.)
    #
    #AddType text/html .shtml
    #AddOutputFilter INCLUDES .shtml
</IfModule>

#
# The mod_mime_magic module allows the server to use various hints from the
# contents of the file itself to determine its type.  The MIMEMagicFile
# directive tells the module where the hint definitions are located.
#
#MIMEMagicFile conf/magic

#
# Customizable error responses come in three flavors:
# 1) plain text 2) local redirects 3) external redirects
#
# Some examples:
#ErrorDocument 500 "The server made a boo boo."
#ErrorDocument 404 /missing.html
#ErrorDocument 404 "/cgi-bin/missing_handler.pl"
#ErrorDocument 402 http://www.example.com/subscription_info.html
#

#
# MaxRanges: Maximum number of Ranges in a request before
# returning the entire resource, or one of the special
# values 'default', 'none' or 'unlimited'.
# Default setting is to accept 200 Ranges.
#MaxRanges unlimited

#
# EnableMMAP and EnableSendfile: On systems that support it, 
# memory-mapping or the sendfile syscall may be used to deliver
# files.  This usually improves server performance, but must
# be turned off when serving from networked-mounted 
# filesystems or if support for these functions is otherwise
# broken on your system.
# Defaults: EnableMMAP On, EnableSendfile Off
#
#EnableMMAP off
#EnableSendfile on

# Supplemental configuration
#
# The configuration files in the conf/extra/ directory can be 
# included to add extra features or to modify the default configuration of 
# the server, or you may simply copy their contents here and change as 
# necessary.

# Server-pool management (MPM specific)
#Include conf/extra/httpd-mpm.conf

# Multi-language error messages
#Include conf/extra/httpd-multilang-errordoc.conf

# Fancy directory listings
#Include conf/extra/httpd-autoindex.conf

# Language settings
#Include conf/extra/httpd-languages.conf

# User home directories
#Include conf/extra/httpd-userdir.conf

# Real-time info on requests and configuration
#Include conf/extra/httpd-info.conf

# Virtual hosts
#Include conf/extra/httpd-vhosts.conf

# Local access to the Apache HTTP Server Manual
#Include conf/extra/httpd-manual.conf

# Distributed authoring and versioning (WebDAV)
#Include conf/extra/httpd-dav.conf

# Various default settings
#Include conf/extra/httpd-default.conf

# Configure mod_proxy_html to understand HTML4/XHTML1
<IfModule proxy_html_module>
Include conf/extra/proxy-html.conf
</IfModule>

# Secure (SSL/TLS) connections
#Include conf/extra/httpd-ssl.conf
#
# Note: The following must must be present to support
#       starting without SSL on platforms with no /dev/random equivalent
#       but a statically compiled-in mod_ssl.
#
<IfModule ssl_module>
SSLRandomSeed startup builtin
SSLRandomSeed connect builtin
</IfModule>

~~~

- nginx.conf
~~~
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    server_tokens on;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}
~~~

- readme.md
~~~
curl -sI http://192.168.245.112 -H 'host: nginx.test.local'

curl -sI http://192.168.245.111 -H 'host: nginx-istio.test.local'

while sleep 1 ; do echo -n "$(date '+%Y/%m/%d %H:%M:%S') " ; curl -sI http://192.168.245.112 -H 'host: nginx.test.local' | head -1 ; done

curl -H 'X-Forwarded-For: 192.168.245.101' -sI http://192.168.245.112 -H 'host: nginx.test.local'

curl -H 'X-Forwarded-For: 192.168.245.101' -sI http://192.168.245.111 -H 'host: nginx-istio.test.local'

curl -H 'X-Forwarded-For: 192.168.245.101' -sI http://192.168.245.112 -H 'host: httpd.test.local'

curl -H 'X-Forwarded-For: 192.168.245.101' -sI http://192.168.245.111 -H 'host: httpd-istio.test.local'

kubectl exec nginx-client -- curl -sI http://nginx
~~~

