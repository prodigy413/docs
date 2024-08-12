~~~
apache.yaml



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
  name: conf-01
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
  name: conf-02
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpd-01
  labels:
    app: httpd-01
spec:
  selector:
    matchLabels:
      app: httpd-01
  replicas: 1
  template:
    metadata:
      labels:
        app: httpd-01
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
          name: conf-01
          items:
          - key: httpd.conf
            path: httpd.conf
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpd-02
  labels:
    app: httpd-02
spec:
  selector:
    matchLabels:
      app: httpd-02
  replicas: 1
  template:
    metadata:
      labels:
        app: httpd-02
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
          name: conf-02
          items:
          - key: httpd.conf
            path: httpd.conf
---
apiVersion: v1
kind: Service
metadata:
  name: httpd-01
spec:
  selector:
    app: httpd-01
  clusterIP: 10.106.69.120
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: httpd-02
spec:
  selector:
    app: httpd-02
  clusterIP: 10.106.69.121
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80









proxy.yaml

kind: Namespace
apiVersion: v1
metadata:
  name: istio-test
  labels:
    name: istio-test
    istio-injection: enabled
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
            set $backend_server 10.106.69.120;
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
  namespace: istio-test
---
apiVersion: v1
data:
  nginx.conf: |2

    worker_processes  auto;

    error_log  /var/log/nginx/error.log notice;
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

        include       /etc/nginx/mime.types;
        default_type  application/octet-stream;

        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

        access_log  /var/log/nginx/access.log  main;

        sendfile        on;

        keepalive_timeout  65;

        include /etc/nginx/conf.d/*.conf;
    }
kind: ConfigMap
metadata:
  name: nginx-conf
  namespace: istio-test
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
apiVersion: apps/v1
kind: Deployment
metadata:
  name: proxy-01
  labels:
    app: proxy-01
  namespace: istio-test
spec:
  selector:
    matchLabels:
      app: proxy-01
  replicas: 1
  template:
    metadata:
      labels:
        app: proxy-01
#      annotations:
#        proxy.istio.io/config: |
#          proxyHeaders:
#            server:
#              disabled: true
#              value: "test-server"
    spec:
      containers:
      - name: proxy
        image: nginxinc/nginx-unprivileged:1.25.5
        volumeMounts:
        - name: nginx-conf
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
        - name: proxy-conf
          mountPath: /etc/nginx/conf.d
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
  name: proxy-01
  namespace: istio-test
spec:
  selector:
    app: proxy-01
  ports:
  - name: proxy
    protocol: TCP
    port: 8080
    targetPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: proxy-01
  namespace: istio-test
spec:
  ingressClassName: nginx
  rules:
  - host: proxy-01-ingress.test.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: proxy-01
            port:
              number: 8080
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: proxy-01
  namespace: istio-test
spec:
  gateways:
  - istio-system/test-gw
  hosts:
  - "proxy-01-istio.test.local"
  http:
  - route:
    - destination:
        host: proxy-01
        port:
          number: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: proxy-02
  labels:
    app: proxy-02
  namespace: istio-test
spec:
  selector:
    matchLabels:
      app: proxy-02
  replicas: 1
  template:
    metadata:
      labels:
        app: proxy-02
        sidecar.istio.io/inject: "false"
#      annotations:
#        proxy.istio.io/config: |
#          proxyHeaders:
#            server:
#              disabled: true
#              value: "test-server"
    spec:
      containers:
      - name: proxy
        image: nginxinc/nginx-unprivileged:1.25.5
        volumeMounts:
        - name: nginx-conf
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
        - name: proxy-conf
          mountPath: /etc/nginx/conf.d
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
  name: proxy-02
  namespace: istio-test
spec:
  selector:
    app: proxy-02
  ports:
  - name: proxy
    protocol: TCP
    port: 8080
    targetPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: proxy-02
  namespace: istio-test
spec:
  ingressClassName: nginx
  rules:
  - host: proxy-02-ingress.test.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: proxy-02
            port:
              number: 8080
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: proxy-02
  namespace: istio-test
spec:
  gateways:
  - istio-system/test-gw
  hosts:
  - "proxy-02-istio.test.local"
  http:
  - route:
    - destination:
        host: proxy-02
        port:
          number: 8080
      headers:
        response: 
          remove:
          - server
---
apiVersion: v1
kind: Pod
metadata:
  name: network-client
#  namespace: istio-test
spec:
  containers:
  - name: network-client
    image: prodigy413/network-client:1.0









apiVersion: v1
items:
- apiVersion: v1
  data:
    ca.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJjVENDQVJhZ0F3SUJBZ0lRYU5jcnp3c3dTTWF0djM0WTlvQXdsekFLQmdncWhrak9QUVFEQWpBWU1SWXcKRkFZRFZRUURFdzF6Wld4bWMybG5ibVZrTFdOaE1CNFhEVEkwTURneE1ERXpORFV6TWxvWERUSTBNVEV3T0RFegpORFV6TWxvd0dERVdNQlFHQTFVRUF4TU5jMlZzWm5OcFoyNWxaQzFqWVRCWk1CTUdCeXFHU000OUFnRUdDQ3FHClNNNDlBd0VIQTBJQUJDT1pKY29abUpXZStZSk81SVU5NlFxdEhwdERYYmhRRjg1VkR3WFBiTGpGQmJhYzZKWUcKakVyZ1FpREEyWkkxQjJXd3RyZ0FiMWhZUHZGSzZENVl2V3VqUWpCQU1BNEdBMVVkRHdFQi93UUVBd0lDcERBUApCZ05WSFJNQkFmOEVCVEFEQVFIL01CMEdBMVVkRGdRV0JCU1RNZU5lVFVhSUZxMm5vQ0lyRFRBRXlCUEphekFLCkJnZ3Foa2pPUFFRREFnTkpBREJHQWlFQTA5c0U4WS9jcHp1bFpBVEpyUXhxdXNWd3pGVFRLejNmNlJPNkp6RnAKaUtrQ0lRRHI1UFc5cXgrQ1M3M0FtcnRrb1dvdmZqajB1WHA3NHhtYUR6cVdFWmVCNkE9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUIxRENDQVhxZ0F3SUJBZ0lRVnZXbUtyOERBWURkVDVtQ3piMlNzakFLQmdncWhrak9QUVFEQWpBWU1SWXcKRkFZRFZRUURFdzF6Wld4bWMybG5ibVZrTFdOaE1CNFhEVEkwTURneE1qRTFORGt3TUZvWERUSTBNRGd4TXpFMQpORGt3TUZvd1ZURU9NQXdHQTFVRUJoTUZTbUZ3WVc0eERqQU1CZ05WQkFnVEJWUnZhM2x2TVE4d0RRWURWUVFICkV3WkJaR0ZqYUdreEZUQVRCZ05WQkFvVERFcGxaR2tnUVdOaFpHVnRlVEVMTUFrR0ExVUVDeE1DU1ZRd1dUQVQKQmdjcWhrak9QUUlCQmdncWhrak9QUU1CQndOQ0FBUzRtcEJMcGJQUFg4SnIwZFo3ZGtiWnBEZ20zUFdjeFM0OQpseHo4RWlyT2g3dThMUnJlS2RoWFo2dVA2Q0VsU0NFZGVlUDhpMzJ1R3F2b2x1UDZZeFVWbzJrd1p6QU9CZ05WCkhROEJBZjhFQkFNQ0JhQXdEQVlEVlIwVEFRSC9CQUl3QURBZkJnTlZIU01FR0RBV2dCU1RNZU5lVFVhSUZxMm4Kb0NJckRUQUV5QlBKYXpBbUJnTlZIUkVFSHpBZGdodHdjbTk0ZVMwd01TMXBibWR5WlhOekxuUmxjM1F1Ykc5agpZV3d3Q2dZSUtvWkl6ajBFQXdJRFNBQXdSUUlnUnZoWnUvUXZLaXRSLzFMZFhjMk1zTVRwdHhScGNFaCtLUTF6Cm1HLzV2TUlDSVFDRWFOWUR2VWNIVUxWR1JGbXMvbjluUTU5djFIWTJFKzc4ZFkvUXJIWHNvZz09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    tls.key: LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0tCk1IY0NBUUVFSU1LVlM0UVFWV2VIWnlOWWptUC83OVJOczAxdFBYRTdHMU5Md1dDelZZa2xvQW9HQ0NxR1NNNDkKQXdFSG9VUURRZ0FFdUpxUVM2V3p6MS9DYTlIV2UzWkcyYVE0SnR6MW5NVXVQWmNjL0JJcXpvZTd2QzBhM2luWQpWMmVyaitnaEpVZ2hIWG5qL0l0OXJocXI2SmJqK21NVkZRPT0KLS0tLS1FTkQgRUMgUFJJVkFURSBLRVktLS0tLQo=
  kind: Secret
  metadata:
    annotations:
      cert-manager.io/alt-names: proxy-01-ingress.test.local
      cert-manager.io/certificate-name: proxy-01-ingress
      cert-manager.io/common-name: ""
      cert-manager.io/ip-sans: ""
      cert-manager.io/issuer-group: cert-manager.io
      cert-manager.io/issuer-kind: ClusterIssuer
      cert-manager.io/issuer-name: ca-issuer
      cert-manager.io/subject-countries: Japan
      cert-manager.io/subject-localities: Adachi
      cert-manager.io/subject-organizationalunits: IT
      cert-manager.io/subject-organizations: Jedi Academy
      cert-manager.io/subject-provinces: Tokyo
      cert-manager.io/uri-sans: ""
    creationTimestamp: "2024-08-12T15:49:00Z"
    labels:
      controller.cert-manager.io/fao: "true"
    name: proxy-01-ingress-crt
    namespace: istio-test
    resourceVersion: "5616476"
    uid: 56b90166-002d-424e-8570-d33d99c90bae
  type: kubernetes.io/tls
- apiVersion: v1
  data:
    ca.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJjVENDQVJhZ0F3SUJBZ0lRYU5jcnp3c3dTTWF0djM0WTlvQXdsekFLQmdncWhrak9QUVFEQWpBWU1SWXcKRkFZRFZRUURFdzF6Wld4bWMybG5ibVZrTFdOaE1CNFhEVEkwTURneE1ERXpORFV6TWxvWERUSTBNVEV3T0RFegpORFV6TWxvd0dERVdNQlFHQTFVRUF4TU5jMlZzWm5OcFoyNWxaQzFqWVRCWk1CTUdCeXFHU000OUFnRUdDQ3FHClNNNDlBd0VIQTBJQUJDT1pKY29abUpXZStZSk81SVU5NlFxdEhwdERYYmhRRjg1VkR3WFBiTGpGQmJhYzZKWUcKakVyZ1FpREEyWkkxQjJXd3RyZ0FiMWhZUHZGSzZENVl2V3VqUWpCQU1BNEdBMVVkRHdFQi93UUVBd0lDcERBUApCZ05WSFJNQkFmOEVCVEFEQVFIL01CMEdBMVVkRGdRV0JCU1RNZU5lVFVhSUZxMm5vQ0lyRFRBRXlCUEphekFLCkJnZ3Foa2pPUFFRREFnTkpBREJHQWlFQTA5c0U4WS9jcHp1bFpBVEpyUXhxdXNWd3pGVFRLejNmNlJPNkp6RnAKaUtrQ0lRRHI1UFc5cXgrQ1M3M0FtcnRrb1dvdmZqajB1WHA3NHhtYUR6cVdFWmVCNkE9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUIwekNDQVhxZ0F3SUJBZ0lRYThJaHNwOWp5bjBvYlFpbjMwTnpKekFLQmdncWhrak9QUVFEQWpBWU1SWXcKRkFZRFZRUURFdzF6Wld4bWMybG5ibVZrTFdOaE1CNFhEVEkwTURneE1qRTFORGt3TUZvWERUSTBNRGd4TXpFMQpORGt3TUZvd1ZURU9NQXdHQTFVRUJoTUZTbUZ3WVc0eERqQU1CZ05WQkFnVEJWUnZhM2x2TVE4d0RRWURWUVFICkV3WkJaR0ZqYUdreEZUQVRCZ05WQkFvVERFcGxaR2tnUVdOaFpHVnRlVEVMTUFrR0ExVUVDeE1DU1ZRd1dUQVQKQmdjcWhrak9QUUlCQmdncWhrak9QUU1CQndOQ0FBUkwzbW10MkwyVWR0U1BvenNBOVRRYWVhV1EvS2lseTQwQwpXUVVyWGxyZVpiYnVUS1JzeDhIVHVoOWxPd2hWNFJyZXRhdThldUJKUEo4S2I5MHFXeVhFbzJrd1p6QU9CZ05WCkhROEJBZjhFQkFNQ0JhQXdEQVlEVlIwVEFRSC9CQUl3QURBZkJnTlZIU01FR0RBV2dCU1RNZU5lVFVhSUZxMm4Kb0NJckRUQUV5QlBKYXpBbUJnTlZIUkVFSHpBZGdodHdjbTk0ZVMwd01pMXBibWR5WlhOekxuUmxjM1F1Ykc5agpZV3d3Q2dZSUtvWkl6ajBFQXdJRFJ3QXdSQUlnYkJOTkFXMVROcUlnRW9KQkhpbStNK1IzSmVYaFpzWDJwM1c1CkorLytMNVVDSUNBbS96ODQyRjV4bzhnelcxUm02VkM1QkhnUDJSWjFQU2dPZFlMOEc3N1MKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    tls.key: LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0tCk1IY0NBUUVFSUxCMHRlbzVpdFBzRzczcjFGWjVCUXFoNUVXN2g3aVR3WWp4L1pMUklSN3BvQW9HQ0NxR1NNNDkKQXdFSG9VUURRZ0FFUzk1cHJkaTlsSGJVajZNN0FQVTBHbm1sa1B5b3BjdU5BbGtGSzE1YTNtVzI3a3lrYk1mQgowN29mWlRzSVZlRWEzcldydkhyZ1NUeWZDbS9kS2xzbHhBPT0KLS0tLS1FTkQgRUMgUFJJVkFURSBLRVktLS0tLQo=
  kind: Secret
  metadata:
    annotations:
      cert-manager.io/alt-names: proxy-02-ingress.test.local
      cert-manager.io/certificate-name: proxy-02-ingress
      cert-manager.io/common-name: ""
      cert-manager.io/ip-sans: ""
      cert-manager.io/issuer-group: cert-manager.io
      cert-manager.io/issuer-kind: ClusterIssuer
      cert-manager.io/issuer-name: ca-issuer
      cert-manager.io/subject-countries: Japan
      cert-manager.io/subject-localities: Adachi
      cert-manager.io/subject-organizationalunits: IT
      cert-manager.io/subject-organizations: Jedi Academy
      cert-manager.io/subject-provinces: Tokyo
      cert-manager.io/uri-sans: ""
    creationTimestamp: "2024-08-12T15:49:00Z"
    labels:
      controller.cert-manager.io/fao: "true"
    name: proxy-02-ingress-crt
    namespace: istio-test
    resourceVersion: "5616464"
    uid: 5d38a2c1-1ba8-421e-ba90-8447831fce8c
  type: kubernetes.io/tls
kind: List
metadata:
  resourceVersion: ""










- apiVersion: v1
  data:
    ca.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJjVENDQVJhZ0F3SUJBZ0lRYU5jcnp3c3dTTWF0djM0WTlvQXdsekFLQmdncWhrak9QUVFEQWpBWU1SWXcKRkFZRFZRUURFdzF6Wld4bWMybG5ibVZrTFdOaE1CNFhEVEkwTURneE1ERXpORFV6TWxvWERUSTBNVEV3T0RFegpORFV6TWxvd0dERVdNQlFHQTFVRUF4TU5jMlZzWm5OcFoyNWxaQzFqWVRCWk1CTUdCeXFHU000OUFnRUdDQ3FHClNNNDlBd0VIQTBJQUJDT1pKY29abUpXZStZSk81SVU5NlFxdEhwdERYYmhRRjg1VkR3WFBiTGpGQmJhYzZKWUcKakVyZ1FpREEyWkkxQjJXd3RyZ0FiMWhZUHZGSzZENVl2V3VqUWpCQU1BNEdBMVVkRHdFQi93UUVBd0lDcERBUApCZ05WSFJNQkFmOEVCVEFEQVFIL01CMEdBMVVkRGdRV0JCU1RNZU5lVFVhSUZxMm5vQ0lyRFRBRXlCUEphekFLCkJnZ3Foa2pPUFFRREFnTkpBREJHQWlFQTA5c0U4WS9jcHp1bFpBVEpyUXhxdXNWd3pGVFRLejNmNlJPNkp6RnAKaUtrQ0lRRHI1UFc5cXgrQ1M3M0FtcnRrb1dvdmZqajB1WHA3NHhtYUR6cVdFWmVCNkE9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUIwekNDQVhpZ0F3SUJBZ0lRT1dKR1Boa3NIV1Z0SVRldW9KcGwvakFLQmdncWhrak9QUVFEQWpBWU1SWXcKRkFZRFZRUURFdzF6Wld4bWMybG5ibVZrTFdOaE1CNFhEVEkwTURneE1qRTFORGt3TUZvWERUSTBNRGd4TXpFMQpORGt3TUZvd1ZURU9NQXdHQTFVRUJoTUZTbUZ3WVc0eERqQU1CZ05WQkFnVEJWUnZhM2x2TVE4d0RRWURWUVFICkV3WkJaR0ZqYUdreEZUQVRCZ05WQkFvVERFcGxaR2tnUVdOaFpHVnRlVEVMTUFrR0ExVUVDeE1DU1ZRd1dUQVQKQmdjcWhrak9QUUlCQmdncWhrak9QUU1CQndOQ0FBUUhuQU11WVBxYnc1M2p3NnJUaThMdVNqMmU3M2lBUm8vMQp4MEYrKzhPaDlENkpSM3U2cHhsclg4bTlWSTdhdFY4MkFUTVdibUxCNkZNcGxacGd0UFp4bzJjd1pUQU9CZ05WCkhROEJBZjhFQkFNQ0JhQXdEQVlEVlIwVEFRSC9CQUl3QURBZkJnTlZIU01FR0RBV2dCU1RNZU5lVFVhSUZxMm4Kb0NJckRUQUV5QlBKYXpBa0JnTlZIUkVFSFRBYmdobHdjbTk0ZVMwd01TMXBjM1JwYnk1MFpYTjBMbXh2WTJGcwpNQW9HQ0NxR1NNNDlCQU1DQTBrQU1FWUNJUUQyWjFMT3BPNHdNWmxoN1N4NmVuUXl3bUtwS3NHUytKVGE2b2RVCmtnY1grd0loQU1hVXhQUWhJeE5aTlJ5bjFZWkVyNnljRWxoSk1vRTlqU3diY09WRnNMb0MKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    tls.key: LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0tCk1IY0NBUUVFSU1XTVBTdnUzT2RiTW9zZFpjOEcvMVlVSHRkYTA2dktHakhXR1gySUYxNGdvQW9HQ0NxR1NNNDkKQXdFSG9VUURRZ0FFQjV3RExtRDZtOE9kNDhPcTA0dkM3a285bnU5NGdFYVA5Y2RCZnZ2RG9mUStpVWQ3dXFjWgphMS9KdlZTTzJyVmZOZ0V6Rm01aXdlaFRLWldhWUxUMmNRPT0KLS0tLS1FTkQgRUMgUFJJVkFURSBLRVktLS0tLQo=
  kind: Secret
  metadata:
    annotations:
      cert-manager.io/alt-names: proxy-01-istio.test.local
      cert-manager.io/certificate-name: proxy-01-istio.test
      cert-manager.io/common-name: ""
      cert-manager.io/ip-sans: ""
      cert-manager.io/issuer-group: cert-manager.io
      cert-manager.io/issuer-kind: ClusterIssuer
      cert-manager.io/issuer-name: ca-issuer
      cert-manager.io/subject-countries: Japan
      cert-manager.io/subject-localities: Adachi
      cert-manager.io/subject-organizationalunits: IT
      cert-manager.io/subject-organizations: Jedi Academy
      cert-manager.io/subject-provinces: Tokyo
      cert-manager.io/uri-sans: ""
    creationTimestamp: "2024-08-10T13:45:37Z"
    labels:
      controller.cert-manager.io/fao: "true"
    name: proxy-01-istio.test-crt
    namespace: istio-system
    resourceVersion: "5616501"
    uid: 3db1c825-3042-4f41-9b30-72bf630fb2dc
  type: kubernetes.io/tls
- apiVersion: v1
  data:
    ca.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJjVENDQVJhZ0F3SUJBZ0lRYU5jcnp3c3dTTWF0djM0WTlvQXdsekFLQmdncWhrak9QUVFEQWpBWU1SWXcKRkFZRFZRUURFdzF6Wld4bWMybG5ibVZrTFdOaE1CNFhEVEkwTURneE1ERXpORFV6TWxvWERUSTBNVEV3T0RFegpORFV6TWxvd0dERVdNQlFHQTFVRUF4TU5jMlZzWm5OcFoyNWxaQzFqWVRCWk1CTUdCeXFHU000OUFnRUdDQ3FHClNNNDlBd0VIQTBJQUJDT1pKY29abUpXZStZSk81SVU5NlFxdEhwdERYYmhRRjg1VkR3WFBiTGpGQmJhYzZKWUcKakVyZ1FpREEyWkkxQjJXd3RyZ0FiMWhZUHZGSzZENVl2V3VqUWpCQU1BNEdBMVVkRHdFQi93UUVBd0lDcERBUApCZ05WSFJNQkFmOEVCVEFEQVFIL01CMEdBMVVkRGdRV0JCU1RNZU5lVFVhSUZxMm5vQ0lyRFRBRXlCUEphekFLCkJnZ3Foa2pPUFFRREFnTkpBREJHQWlFQTA5c0U4WS9jcHp1bFpBVEpyUXhxdXNWd3pGVFRLejNmNlJPNkp6RnAKaUtrQ0lRRHI1UFc5cXgrQ1M3M0FtcnRrb1dvdmZqajB1WHA3NHhtYUR6cVdFWmVCNkE9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUIxRENDQVhtZ0F3SUJBZ0lSQUxiNlpkWCtVaUVLbUd2NVZiMUZZc1l3Q2dZSUtvWkl6ajBFQXdJd0dERVcKTUJRR0ExVUVBeE1OYzJWc1puTnBaMjVsWkMxallUQWVGdzB5TkRBNE1USXhOVFE1TURCYUZ3MHlOREE0TVRNeApOVFE1TURCYU1GVXhEakFNQmdOVkJBWVRCVXBoY0dGdU1RNHdEQVlEVlFRSUV3VlViMnQ1YnpFUE1BMEdBMVVFCkJ4TUdRV1JoWTJocE1SVXdFd1lEVlFRS0V3eEtaV1JwSUVGallXUmxiWGt4Q3pBSkJnTlZCQXNUQWtsVU1Ga3cKRXdZSEtvWkl6ajBDQVFZSUtvWkl6ajBEQVFjRFFnQUVjL0pIUDFudVhFY1o1SHhOL0Z5cXpiM1kzcW83cGU1YgpjZ1YvUXlqbi81UHZwUGxkMThhQXNnVmZUZE1GTUFCeXNQOTI1RkVtWklwcFYyYTljM0NCRUtObk1HVXdEZ1lEClZSMFBBUUgvQkFRREFnV2dNQXdHQTFVZEV3RUIvd1FDTUFBd0h3WURWUjBqQkJnd0ZvQVVrekhqWGsxR2lCYXQKcDZBaUt3MHdCTWdUeVdzd0pBWURWUjBSQkIwd0c0SVpjSEp2ZUhrdE1ESXRhWE4wYVc4dWRHVnpkQzVzYjJOaApiREFLQmdncWhrak9QUVFEQWdOSkFEQkdBaUVBbDZTREg5dkExTXB1KzJnQmdCYjdQbG1YZVU0WTg3L3RWdG8rClFoNFJlbW9DSVFEN3VSTkdZY2s4Uk8zU0czZ1lyc2taSXNrWFNZWEEyamtxMlZJa2thTm4vZz09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    tls.key: LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0tCk1IY0NBUUVFSURqNWZ1TnRNTzZjR0owUzd5SnYxRlQyUVlScWI2ZGRQRFB5K0gwbG82WWpvQW9HQ0NxR1NNNDkKQXdFSG9VUURRZ0FFYy9KSFAxbnVYRWNaNUh4Ti9GeXF6YjNZM3FvN3BlNWJjZ1YvUXlqbi81UHZwUGxkMThhQQpzZ1ZmVGRNRk1BQnlzUDkyNUZFbVpJcHBWMmE5YzNDQkVBPT0KLS0tLS1FTkQgRUMgUFJJVkFURSBLRVktLS0tLQo=
  kind: Secret
  metadata:
    annotations:
      cert-manager.io/alt-names: proxy-02-istio.test.local
      cert-manager.io/certificate-name: proxy-02-istio
      cert-manager.io/common-name: ""
      cert-manager.io/ip-sans: ""
      cert-manager.io/issuer-group: cert-manager.io
      cert-manager.io/issuer-kind: ClusterIssuer
      cert-manager.io/issuer-name: ca-issuer
      cert-manager.io/subject-countries: Japan
      cert-manager.io/subject-localities: Adachi
      cert-manager.io/subject-organizationalunits: IT
      cert-manager.io/subject-organizations: Jedi Academy
      cert-manager.io/subject-provinces: Tokyo
      cert-manager.io/uri-sans: ""
    creationTimestamp: "2024-08-10T13:45:37Z"
    labels:
      controller.cert-manager.io/fao: "true"
    name: proxy-02-istio-crt
    namespace: istio-system
    resourceVersion: "5616497"
    uid: 65a390ac-b3d0-40c5-a846-9e0e6f2e3ef5
  type: kubernetes.io/tls
kind: List
metadata:
  resourceVersion: ""
~~~

~~~
kubectl apply -f proxy.yaml
kubectl delete -f proxy.yaml
kubectl -n istio-test get pod
~~~

~~~
kubectl -n istio-test rollout restart deployment proxy
kubectl -n istio-test exec -it deployments/proxy -- cat /etc/nginx/nginx.conf
kubectl -n istio-test exec -it deployments/proxy -- cat /etc/nginx/conf.d/proxy.conf
~~~

~~~
kubectl exec -it network-client -- bash
curl -sI http://httpd-01
curl -sI http://httpd-02
~~~

~~~
curl http://192.168.245.112 -H 'host: proxy-01-ingress.test.local'
curl http://192.168.245.111 -H 'host: proxy-01-istio.test.local'

curl http://192.168.245.112 -H 'host: proxy-02-ingress.test.local'
curl http://192.168.245.111 -H 'host: proxy-02-istio.test.local'

curl -sI http://192.168.245.112 -H 'host: proxy-01-ingress.test.local'
curl -sI http://192.168.245.111 -H 'host: proxy-01-istio.test.local'

curl -sI http://192.168.245.112 -H 'host: proxy-02-ingress.test.local'
curl -sI http://192.168.245.111 -H 'host: proxy-02-istio.test.local'
~~~

~~~
kubectl -n istio-test logs deploy/proxy-01 --tail=10 --since=30m
kubectl -n istio-test logs deploy/proxy-02 --tail=10 --since=30m
~~~
