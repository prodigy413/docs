| Version | Changes | Impact |
|--|--|--|
|1.29.5<br>2026/2/4|Security: an attacker might inject plain text data in the response from an SSL backend (CVE-2026-1642).|No|
|1.29.5<br>2026/2/4|Bugfix: use-after-free might occur after switching to the next gRPC or HTTP/2 backend.|No|
|1.29.5<br>2026/2/4|Bugfix: an invalid HTTP/2 request might be sent after switching to the next upstream.|No|
|1.29.5<br>2026/2/4|Bugfix: a response with multiple ranges might be larger than the source response.|No|
|1.29.5<br>2026/2/4|Bugfix: fixed setting HTTP_HOST when proxying to FastCGI, SCGI, and uwsgi backends.|No|
|1.29.5<br>2026/2/4|Bugfix: fixed warning when compiling with MSVC 2022 x86.|No|
|1.29.5<br>2026/2/4|Change: the logging level of the "ech_required" SSL error has been lowered from "crit" to "info".|No|

| Version | Changes | Impact |
|--|--|--|
|1.29.4<br>2025/12/09|Feature: the ngx_http_proxy_module supports HTTP/2.|No|
|1.29.4<br>2025/12/09|Feature: Encrypted ClientHello TLS extension support when using OpenSSL ECH feature branch; the "ssl_ech_file" directive.|No|
|1.29.4<br>2025/12/09|Change: validation of host and port in the request line, "Host" header field, and ":authority" pseudo-header field has been changed to follow RFC 3986.|No|
|1.29.4<br>2025/12/09|Change: now a single LF used as a line terminator in a chunked request or response body is considered an error.|No|
|1.29.4<br>2025/12/09|Bugfix: when using HTTP/3 with OpenSSL 3.5.1 or newer a segmentation fault might occur in a worker process; the bug had appeared in 1.29.1.|No|
|1.29.4<br>2025/12/09|Bugfix: a segmentation fault might occur in a worker process if the "try_files" directive and "proxy_pass" with a URI were used.|No|

| Version | Changes | Impact |
|--|--|--|
|1.29.3<br>2025/10/28|Feature: the "add_header_inherit" and "add_trailer_inherit" directives.|No|
|1.29.3<br>2025/10/28|Feature: the $request_port and $is_request_port variables.|No|
|1.29.3<br>2025/10/28|Feature: the $ssl_sigalg and $ssl_client_sigalg variables.|No|
|1.29.3<br>2025/10/28|Feature: the "volatile" parameter of the "geo" directive.|No|
|1.29.3<br>2025/10/28|Feature: now certificate compression is available with BoringSSL.|No|
|1.29.3<br>2025/10/28|Bugfix: now certificate compression is disabled with OCSP stapling.|No: bugfix|

| Version | Changes | Impact |
|--|--|--|
|1.29.2<br>2025/10/07|Feature: now nginx can be built with AWS-LC.|No|
|1.29.2<br>2025/10/07|Bugfix: now the "ssl_protocols" directive works in a virtual server different from the default server when using OpenSSL 1.1.1 or newer.|No: bugfix|
|1.29.2<br>2025/10/07|Bugfix: SSL handshake always failed when using TLSv1.3 with OpenSSL and client certificates and resuming a session with a different SNI value; the bug had appeared in 1.27.4.|No: bugfix|
|1.29.2<br>2025/10/07|Bugfix: the "ignoring stale global SSL error" alerts might appear in logs when using QUIC and the "ssl_reject_handshake" directive; the bug had appeared in 1.29.0.|No: bugfix|
|1.29.2<br>2025/10/07|Bugfix: in delta-seconds processing in the "Cache-Control" backend response header line.|No: bugfix|
|1.29.2<br>2025/10/07|Bugfix: an XCLIENT command didn't use the xtext encoding. Thanks to Igor Morgenstern of Aisle Research.|No: bugfix|
|1.29.2<br>2025/10/07|Bugfix: in SSL certificate caching during reconfiguration.|No: bugfix|

| Version | Changes | Impact |
|--|--|--|
|1.29.1<br>2025/08/13|Security: processing of a specially crafted login/password when using the "none" authentication method in the ngx_mail_smtp_module might cause worker process memory disclosure to the authentication server (CVE-2025-53859).||No: security patch
|1.29.1<br>2025/08/13|Change: now TLSv1.3 certificate compression is disabled by default.|No|
|1.29.1<br>2025/08/13|Feature: the "ssl_certificate_compression" directive.|No|
|1.29.1<br>2025/08/13|Feature: support for 0-RTT in QUIC when using OpenSSL 3.5.1 or newer.|No|
|1.29.1<br>2025/08/13|Bugfix: the 103 response might be buffered when using HTTP/2 and the "early_hints" directive.|No: bugfix|
|1.29.1<br>2025/08/13|Bugfix: in handling "Host" and ":authority" header lines with equal values when using HTTP/2; the bug had appeared in 1.17.9.|No: bugfix|
|1.29.1<br>2025/08/13|Bugfix: in handling "Host" header lines with a port when using HTTP/3.|No: bugfix|
|1.29.1<br>2025/08/13|Bugfix: nginx could not be built on NetBSD 10.0.|No: bugfix|
|1.29.1<br>2025/08/13|Bugfix: in the "none" parameter of the "smtp_auth" directive.|No: bugfix|

| Version | Changes | Impact |
|--|--|--|
|1.29.0<br>2025/06/24|Feature: support for response code 103 from proxy and gRPC backends; the "early_hints" directive.|No|
|1.29.0<br>2025/06/24|Feature: loading of secret keys from hardware tokens with OpenSSL provider.|No|
|1.29.0<br>2025/06/24|Feature: support for the "so_keepalive" parameter of the "listen" directive on macOS.|No|
|1.29.0<br>2025/06/24|Change: the logging level of SSL errors in a QUIC handshake has been changed from "error" to "crit" for critical errors, and to "info" for the rest; the logging level of unsupported QUIC transport parameters has been lowered from "info" to "debug".|No|
|1.29.0<br>2025/06/24|Change: the native nginx/Windows binary release is now built using Windows SDK 10.|No: No use Windows|
|1.29.0<br>2025/06/24|Bugfix: nginx could not be built by gcc 15 if ngx_http_v2_module or ngx_http_v3_module modules were used.|No: bugfix|
|1.29.0<br>2025/06/24|Bugfix: nginx might not be built by gcc 14 or newer with -O3 -flto optimization if ngx_http_v3_module was used.|No: bugfix|
|1.29.0<br>2025/06/24|Bugfixes and improvements in HTTP/3.|No: bugfix|

| Version | Changes | Impact |
|--|--|--|
|1.28.2<br>2026/2/4|Security: an attacker might inject plain text data in the response from an SSL backend (CVE-2026-1642).|No|
|1.28.2<br>2026/2/4|Bugfix: use-after-free might occur after switching to the next gRPC or HTTP/2 backend.|No|
|1.28.2<br>2026/2/4|Bugfix: fixed warning when compiling with MSVC 2022 x86.|No|

| Version | Changes | Impact |
|--|--|--|
|1.28.1<br>2025/12/23|Security: processing of a specially crafted login/password when using the "none" authentication method in the ngx_mail_smtp_module might cause worker process memory disclosure to the authentication server (CVE-2025-53859).|No|
|1.28.1<br>2025/12/23|Change: the native nginx/Windows binary release is now built usin Windows SDK 10.|No|
|1.28.1<br>2025/12/23|Bugfix: a segmentation fault might occur in a worker process if the "try_files" directive and "proxy_pass" with a URI were used.|No|
|1.28.1<br>2025/12/23|Bugfix: in handling "Host" and ":authority" header lines with equal values when using HTTP/2; the bug had appeared in 1.17.9.|No|
|1.28.1<br>2025/12/23|Bugfix: in handling "Host" header lines with a port when using HTTP/3.|No|
|1.28.1<br>2025/12/23|Bugfix: an XCLIENT command didn't use the xtext encoding.|No|
|1.28.1<br>2025/12/23|Bugfix: in SSL certificate caching during reconfiguration.|No|
|1.28.1<br>2025/12/23|Bugfix: in delta-seconds processing in the "Cache-Control" backend response header line.|No|
|1.28.1<br>2025/12/23|Bugfix: nginx could not be built on NetBSD 10.0.|No|
|1.28.1<br>2025/12/23|Bugfix: in HTTP/3.|No|

```terraform
# aws s3api get-bucket-acl --bucket obi-test-bucket-20260209 --query "Owner.ID" --output text
# aws s3api list-buckets --query "Owner.ID" --output text

resource "aws_s3_bucket_acl" "example" {
  acl    = null
  bucket = "bucket"
  region = "ap-northeast-1"
  access_control_policy {
    grant {
      permission = "FULL_CONTROL"
      grantee {
        email_address = null
        id            = "ididididididid"
        type          = "CanonicalUser"
        uri           = null
      }
    }
    owner {
      id = "ididididididid"
    }
  }
}

resource "aws_s3_bucket_request_payment_configuration" "example" {
  bucket = "bucket"
  payer  = "BucketOwner"
  region = "ap-northeast-1"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = "bucket"
  region = "ap-northeast-1"
  rule {
    blocked_encryption_types = []
    bucket_key_enabled       = true
    apply_server_side_encryption_by_default {
      kms_master_key_id = null
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = "bucket"
  ignore_public_acls      = true
  region                  = "ap-northeast-1"
  restrict_public_buckets = true
  skip_destroy            = null
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = "bucket"
  region = "ap-northeast-1"
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = "bucket"
  mfa    = null
  region = "ap-northeast-1"
  versioning_configuration {
    status = "Disabled"
  }
}

```
