```
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
```

```powershell
# Set-ExecutionPolicy Bypass -Scope Process
# Get-ExecutionPolicy
# aws s3 sync s3://>bucket_name> C:\Users\obi\test\20251220_manual_download
# Get-Date ; aws s3 sync s3://>bucket_name> .\ | Tee-Object .\out.log ; Get-Date
# Get-Date ; aws s3 sync s3://>bucket_name> .\ | Tee-Object .\out.log ; Get-Date
# Start-Transcript ..\out.log ; Get-Date ; aws s3 sync s3://>bucket_name> .\ ; Get-Date ; Stop-Transcript
# =================================================================
# AWS S3 Download & Zip Compression Script
# =================================================================

Start-Transcript .\out.log | Out-Null
# --- 1. 設定ファイルの読み込み ---
$configPath = Join-Path $PSScriptRoot "config.json"

if (!(Test-Path $configPath)) {
    Write-Error "設定ファイルが見つかりません: $configPath"
    return
}

# 今日の日付を取得
$dateStr = Get-Date -Format "yyyyMMdd"

# JSONを読み込んでオブジェクトに変換
$config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json

$s3Uri              = "s3://$($config.Bucket)"  # S3のパス（末尾に/を推奨）
$localDownloadPath  = Join-Path $config.LocalPath $dateStr       # ダウンロード先
$zipDestinationPath = Join-Path $config.LocalPath "zip"     # 作成するZipのパス
$zipFile = Join-Path $zipDestinationPath "$($config.Bucket).zip"

## --- 設定項目 ---
#$s3Uri = "s3://>bucket_name>/"  # S3のパス（末尾に/を推奨）
#$localDownloadPath = "C:\Users\obi\test\20251220"         # ダウンロード先
#$zipDestinationPath = "C:\Users\obi\test\Backup.zip"      # 作成するZipのパス

# --- 環境準備 ---
# 日本語文字化け対策
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# .NETの圧縮ライブラリをロード（PS5で大容量Zipを扱うために必要）
Add-Type -AssemblyName System.IO.Compression.FileSystem

# 各パスが既に存在するかチェック
$paths = @($zipFile, $localDownloadPath, $zipDestinationPath)

foreach ($p in $paths) {
    if (Test-Path $p) {
    Write-Error "エラー: [$p] が既に存在します。"
    return
    }
}

while ($true) {

    $answer = (Read-Host "対象バケット名で$($config.Bucket)で正しいですか？ (Y/N)")

    if ($answer -eq "y") {
        break
    }
    elseif ($answer -eq "n") {
        Write-Host "--- スクリプトを終了します ---" -ForegroundColor Red
        exit
    }
    else {
        Write-Host "無効な入力です。" -ForegroundColor Yellow
    }
}

# ディレクトリ作成
New-Item -ItemType Directory -Path $localDownloadPath -Force | Out-Null
New-Item -ItemType Directory -Path $zipDestinationPath -Force | Out-Null

try {
    # 1. AWS S3からダウンロード
    Write-Host "--- S3からダウンロードを開始します ---" -ForegroundColor Cyan

    Get-Date
    # syncコマンドは差分転送や再試行に強いため採用
    aws s3 sync $s3Uri $localDownloadPath --no-progress 2>&1
    Get-Date

    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLIでのダウンロードに失敗しました。"
    }

    # 2. Zip圧縮
    Write-Host "--- 圧縮を開始します ---" -ForegroundColor Cyan
    
    # [System.IO.Compression.ZipFile]::CreateFromDirectory(元フォルダ, 保存先, 圧縮レベル, ディレクトリ名を含むか, エンコーディング)
    $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
    $includeBaseDirectory = $false
    $encoding = [System.Text.Encoding]::GetEncoding("UTF-8")

    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $localDownloadPath, 
        $zipFile, 
        $compressionLevel, 
        $includeBaseDirectory, 
        $encoding
    )

    Write-Host "--- 完了しました ---" -ForegroundColor Green
    Write-Host "保存先: $zipFile"
    Write-Host "X:に圧縮ファイルを保管してください。"
    Write-Host "作業依頼者へ完了メールを送信してください。"    

    $mail = @"
XXX様

お世話になっております。XXです。

作業が完了しました。

以上、よろしくお願いいたします。
"@

Write-Host $mail
}
catch {
    Write-Error "エラーが発生しました: $_"
}

Stop-Transcript | Out-Null

```
