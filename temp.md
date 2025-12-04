```
helm upgrade logs-agent oci://icr.io/ibm-observe/logs-agent-helm \
--version 1.6.3 --values logs-values.yaml -n ibm-observe

helm install logs-agent oci://icr.io/ibm-observe/logs-agent-helm \
--version 1.6.3 --values logs-values.yaml -n ibm-observe

helm rollback logs-agent -n ibm-observe
```

```yaml
on:
  push:
    branches:
    - super-linter
jobs:
  build:
    name: Lint
    runs-on: ubuntu-latest

    permissions:
      contents: read
      packages: read
      statuses: write
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v6
        with:
          fetch-depth: 0
          persist-credentials: false

      - name: Super-linter
        uses: super-linter/super-linter@v8.3.0
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          #VALIDATE_YAML: true
          VALIDATE_YAML_PRETTIER: true
          VALIDATE_ALL_CODEBASE: false
          #YAML_FILE_NAME: .yamllint.yml
          FILTER_REGEX_INCLUDE: "yaml/yaml02/.*"
```

https://prettier.io/docs/options

```python
import subprocess
import json
import sys
from time import time
from datetime import timedelta

def run_cmd(cmd_args: list) -> list:
    """Run command and return parsed JSON output."""
    try:
        # コマンド実行（変更なし）
        result = subprocess.run(
            ["ibmcloud"] + cmd_args + ["--output", "json"],
            text=True,
            capture_output=True,
            encoding='utf-8'
        )
        if result.returncode == 0:
            return json.loads(result.stdout)
        else:
            # エラー時は標準エラー出力を表示して終了
            print(result.stderr)
            sys.exit(1)
    except FileNotFoundError:
        print('Command ibmcloud is not found.')
        sys.exit(1)
    except json.JSONDecodeError:
        print("Failed to parse JSON output.")
        sys.exit(1)


def get_account_users() -> list:
    """Get user emails (Skip pending users)."""

    data = run_cmd(["account", "users"])
    valid_ids = []

    for u in data:
        # status (state) が PENDING の場合はスキップ
        state = u.get("state", "").upper()
        if state == "PENDING":
            continue

        user_id = u.get("userId")
        if user_id:
            valid_ids.append(user_id)

    return sorted(valid_ids)


def get_user_policies(user_id: str) -> list:
    """Get access policies for a specific user."""
    # ユーザー個別のポリシーを取得
    return run_cmd(["iam", "user-policies", user_id])


def get_resource_group_map() -> dict:
    """Get map of resource group ID to Name."""
    try:
        data = run_cmd(["resource", "groups"])
        # IDをキー、Nameを値にする辞書を作成
        return {g["id"]: g["name"] for g in data if "id" in g and "name" in g}
    except Exception as e:
        print(f"Warning: Failed to fetch resource groups: {e}")
        return {}


def main():
    if __name__ == "__main__":
        start_time = time()
        print("Task started...")

        # 0. リソースグループ情報の取得
        print("Fetching resource groups...")
        rg_map = get_resource_group_map()

        users = get_account_users()
        print(f"Target Users (Active): {len(users)}")

        all_policies = {}

        # 1. ポリシー取得
        for i, user in enumerate(users, 1):
            print(f"[{i}/{len(users)}] Getting policies for: {user}")
            policies = get_user_policies(user)
            all_policies[user] = policies

        # 2. 結果の整形・出力
        print("\n--- Access Policy Summary ---")

        for user, policies in all_policies.items():
            # ポリシーがないユーザーはスキップ
            if not policies:
                continue

            print(f"\nUser: {user}")

            for policy in policies:
                # Rolesのdisplay_nameを取得
                role_names = [r.get("display_name", "Unknown") for r in policy.get("roles", [])]
                roles_str = ", ".join(role_names)

                # Resourcesのattributesを処理
                resource_attrs = []
                attributes = policy.get("resources", [])

                # リソースリストが空でないか確認（通常はリストの中にオブジェクトが入っている）
                # 構造: "resources": [ { "attributes": [...] } ]
                for res in attributes:
                    attrs_list = res.get("attributes", [])

                    # このリソース定義が resource-group かどうか判定
                    is_rg_type = False
                    for attr in attrs_list:
                        if attr.get("name") == "resourceType" and attr.get("value") == "resource-group":
                            is_rg_type = True
                            break

                    # 属性の抽出と置換
                    for attr in attrs_list:
                        name = attr.get("name")
                        value = attr.get("value")

                        # accountIdは除外
                        if name == "accountId":
                            continue

                        # resourceTypeがresource-groupで、かつ属性名がresourceの場合、IDを名前に置換
                        if is_rg_type and name == "resource" and value in rg_map:
                            value = rg_map[value]  # ID -> Name 置換

                        resource_attrs.append(f"{name}={value}")

                res_str = ", ".join(resource_attrs)
                if not res_str:
                    res_str = "(Account Level)"

                print(f"  - Roles: [{roles_str}]")
                print(f"    Resources: {res_str}")

        end_time = time()
        elapsed_time = timedelta(seconds=int(end_time - start_time))
        print(f"\nTask completed.\nElapsed time: {elapsed_time}.")


if __name__ == "__main__":
    main()
```
