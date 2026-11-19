```
mkdir aspnet-test && cd aspnet-test


FROM mcr.microsoft.com/dotnet/sdk:11.0 AS build
WORKDIR /src
RUN dotnet new web -n TestApp -f net11.0
RUN dotnet publish TestApp/TestApp.csproj -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:11.0
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "TestApp.dll"]


docker build -t aspnet-test .


docker run -d --name aspnet-test -p 8080:8080 aspnet-test


curl http://localhost:8080/
```


# ASP.NET Core 11 Dockerfile 解説

## Dockerfile

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:11.0 AS build
WORKDIR /src
RUN dotnet new web -n TestApp -f net11.0
RUN dotnet publish TestApp/TestApp.csproj -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:11.0
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "TestApp.dll"]
```

## 各行の説明

### 第1ステージ：ビルド

| 設定 | 説明 |
|---|---|
| `FROM .../sdk:11.0 AS build` | .NET 11 SDK イメージを使用。ステージ名を `build` に設定 |
| `WORKDIR /src` | 作業ディレクトリを `/src` に設定 |
| `RUN dotnet new web -n TestApp -f net11.0` | ASP.NET Core 11 のサンプル Web アプリを作成 |
| `RUN dotnet publish ... -c Release -o /app` | Release モードでビルドし、実行用ファイルを `/app` に出力 |

### 第2ステージ：実行

| 設定 | 説明 |
|---|---|
| `FROM .../aspnet:11.0` | ASP.NET Core 11 Runtime イメージを使用 |
| `WORKDIR /app` | 作業ディレクトリを `/app` に設定 |
| `COPY --from=build /app .` | 第1ステージのビルド成果物をコピー |
| `ENTRYPOINT ["dotnet", "TestApp.dll"]` | コンテナ起動時にアプリを実行。Kestrel が起動する |

## Docker コマンド

```bash
# イメージ作成
docker build -t aspnet-test .

# コンテナ起動
docker run -d --name aspnet-test -p 8080:8080 aspnet-test

# HTTPアクセス
curl http://localhost:8080/

# コンテナ削除
docker rm -f aspnet-test
```

## ポイント

- **マルチステージビルド**：ビルド環境と実行環境を分離する方式
- **SDK イメージ**：アプリの作成・ビルドに使用
- **Runtime イメージ**：ビルド済みアプリの実行に使用
- **Kestrel**：ASP.NET Core 標準の Web サーバー
- **8080**：コンテナ内のデフォルト HTTP ポート
- **メリット**：最終イメージに SDK を含めず、イメージサイズを削減できる
