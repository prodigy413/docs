```
import csv
import json
import subprocess
import sys
import yaml


def run_cmd(cmd: list[str]) -> str:
    r = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    r.check_returncode()
    return r.stdout.strip()


def main() -> None:
    csv_file = 'pw_list.csv'
    targets = []

    # 1. CSVファイルの読み込み
    try:
        with open(csv_file, mode='r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                targets.append(row)
    except FileNotFoundError:
        print(f"Error: {csv_file} が見つかりません。")
        sys.exit(1)

    # 2. 既存DBの確認
    print("Checking existing Redis instances...")
    try:
        check_cmd = ["ibmcloud", "resource", "service-instances", "--service-name", "databases-for-redis", "--output", "json"]
        ls_out = run_cmd(check_cmd)
        existing_instances = json.loads(ls_out)
        existing_names = [inst['name'] for inst in existing_instances]
    except subprocess.CalledProcessError:
        print("Error: インスタンス一覧の取得に失敗しました。")
        sys.exit(1)
    except (json.JSONDecodeError, KeyError):
        print("Error: JSONの解析に失敗しました。")
        sys.exit(1)

    # CSV記載のDBが存在するか一括チェック
    missing_dbs = [t['db'] for t in targets if t['db'] not in existing_names]
    if missing_dbs:
        print(f"Error: インスタンスが見つかりません: {', '.join(missing_dbs)}")
        print("スクリプトを中止します。")
        sys.exit(1)

    print("OK: すべての対象DBの存在を確認しました。")

    # 3. 各DBの接続情報を取得してYAMLを作成
    docs = []
    for target in targets:
        name = target['db']
        pw = target['pw']

        print(f'{name}: processing...')

        cmd = ["ibmcloud", "cdb", "cxn", name, "-a", "-u", "admin", "-p", pw, "-e", "private", "-j"]

        try:
            cxn_out = run_cmd(cmd)
            cxn = json.loads(cxn_out)

            # 各値をコマンド結果のJSONから取得
            host = cxn["connection"]["rediss"]["hosts"][0]["hostname"]
            port = cxn["connection"]["rediss"]["hosts"][0]["port"]
            password = cxn["connection"]["rediss"]["authentication"]["password"]

            if "batch" in name:
                docs.append({
                    name: {
                        "SECURE_LOG_REDIS_HOST": host,
                        "SECURE_LOG_REDIS_PASSWORD": password,
                        "SECURE_LOG_REDIS_PORT": port
                    }
                })
            else:
                docs.append({
                    name: {
                        "SPRING_REDIS_HOST": host,
                        "SPRING_REDIS_PASSWORD": password,
                        "SPRING_REDIS_PORT": port
                    }
                })

            # safe_dump から safe_dump_all に変更することで、「---」区切りのマルチドキュメント形式にします
            with open("base.yaml", "w", encoding="utf-8") as f:
                yaml.safe_dump_all(docs, f, sort_keys=False, allow_unicode=True)

        except subprocess.CalledProcessError:
            print(f"Error: {name} の接続情報取得に失敗しました。")
            sys.exit(1)
        except (json.JSONDecodeError, KeyError):
            print(f"Error: {name} の接続情報JSONの解析に失敗しました。")
            sys.exit(1)

    print("Done: base.yaml が作成されました。")


if __name__ == "__main__":
    main()

```
