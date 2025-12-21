```
# Set-ExecutionPolicy Bypass -Scope Process
# Get-ExecutionPolicy
# aws s3 sync s3://>bucket_name> C:\Users\obi\test\20251220_manual_download
# Get-Date ; aws s3 sync s3://>bucket_name> .\ | Tee-Object .\out.log ; Get-Date
# Get-Date ; aws s3 sync s3://>bucket_name> .\ | Tee-Object .\out.log ; Get-Date
# Start-Transcript ..\out.log ; Get-Date ; aws s3 sync s3://>bucket_name> .\ ; Get-Date ; Stop-Transcript
# =================================================================
# AWS S3 Download & Zip Compression Script
# =================================================================

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

# ディレクトリ作成
New-Item -ItemType Directory -Path $localDownloadPath -Force | Out-Null
New-Item -ItemType Directory -Path $zipDestinationPath -Force | Out-Null

try {
    # 1. AWS S3からダウンロード
    Write-Host "--- S3からダウンロードを開始します ---" -ForegroundColor Cyan
    # syncコマンドは差分転送や再試行に強いため採用
    aws s3 sync $s3Uri $localDownloadPath

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





{
    "Bucket": "xxxxx",
    "LocalPath": "C:/Users/obi/test"
}


```
