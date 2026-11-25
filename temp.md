# Windows環境でVS CodeとGitの改行コードをLFに統一する方法

## 1. VS Codeの設定

### VS Code全体の設定

`Ctrl + Shift + P` を押して、`Preferences: Open User Settings (JSON)` を開き、以下を追加する。

```json
{
    "files.eol": "\n"
}
```

新規作成するファイルの改行コードがLFになる。

ただし、既存のCRLFファイルは自動変換されない。
VS Codeの右下にある `CRLF` をクリックし、`LF` を選択して保存する必要がある。

### プロジェクト単位の設定

`.vscode/settings.json` に以下を設定する。

```json
{
    "files.eol": "\n"
}
```

対象プロジェクト内で設定を共有できる。

## 2. Gitの設定

### Git全体の設定

```bash
git config --global core.autocrlf input
```

### リポジトリ単位の設定

```bash
git config --local core.autocrlf input
```

### core.autocrlfの設定値の違い

| 設定値 | ステージング時 | Checkout時 |
|---|---|---|
| `true` | LFに変換 | CRLFに変換 |
| `input` | LFに変換 | 変換しない |
| `false` | 変換しない | 変換しない |

## 3. .gitattributesによるLFの強制（推奨）

リポジトリのルートに `.gitattributes` を作成する。

```gitattributes
* text=auto eol=lf
```

各開発者のGit設定に依存せず、テキストファイルの改行コードをLFに統一できる。

### 既存ファイルへの適用

```bash
git add .gitattributes
git add --renormalize .
git status
git commit -m "Normalize line endings to LF"
git push
```

厳密にはPush時ではなく、`git add` でステージングする時点でLFに変換される。

## 4. 各設定の役割

| 設定 | 役割 |
|---|---|
| VS Code User Settings | VS Code全体のデフォルト改行コード |
| VS Code Workspace Settings | プロジェクト単位のデフォルト改行コード |
| `core.autocrlf` | Gitによる改行コードの変換 |
| `.gitattributes` | リポジトリで管理するテキストファイルの改行コード統一 |

## 5. 推奨構成

| 対象 | 設定 |
|---|---|
| VS Code | `"files.eol": "\n"` |
| Git | `core.autocrlf input` |
| リポジトリ | `* text=auto eol=lf` |

TerraformやKubernetesなどのコードをGitで管理する場合は、VS Codeの設定と `.gitattributes` の併用を推奨する。

エディタ側とバージョン管理側の両方で制御することで、開発者のOSやエディタの違いによる改行コードの問題を防げる。

特にチーム開発では、個人のGit設定に依存しない `.gitattributes` が重要である。
