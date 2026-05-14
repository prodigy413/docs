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

    # 1. CSVファイルの読み込み (サンプルコードを参照)
    try:
        with open(csv_file, mode='r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                targets.append(row)
    except FileNotFoundError:
        print(f"Error: {csv_file} が見つかりません。")
        sys.exit(1)

    # 2. 既存DBの確認 (サンプルコードのDBチェックを参照)
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

        # コマンド引数の変更 (指定の形に変更)
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

            # ベースコードの挙動に合わせてループ内で都度書き出し
            with open("base.yaml", "w", encoding="utf-8") as f:
                yaml.safe_dump(docs, f, sort_keys=False, allow_unicode=True)

        except subprocess.CalledProcessError:
            print(f"Error: {name} の接続情報取得に失敗しました。")
            sys.exit(1)
        except (json.JSONDecodeError, KeyError):
            print(f"Error: {name} の接続情報JSONの解析に失敗しました。")
            sys.exit(1)

    print("Done: base.yaml が作成されました。")


if __name__ == "__main__":
    main()










import csv
import json
import subprocess
import sys


def run_command(command, silent_stdout=False):
    print(f"\n------------------------------\n[Executing] {' '.join(command)}")
    result = subprocess.run(command, capture_output=True, text=True)

    # 標準出力の表示判定
    if not silent_stdout and result.stdout:
        print(f"[STDOUT]\n{result.stdout.strip()}")

    # 標準エラーは常に表示（エラー把握のため）
    if result.stderr:
        print(f"[STDERR]\n{result.stderr.strip()}")

    return result


def main():
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

    # 2. 既存DBの確認 (このステップのSTDOUTは表示しない)
    print("\n##############################")
    print("# 既存のRedisインスタンスを確認中 (JSON出力は省略)")
    print("##############################")
    check_cmd = ["ibmcloud", "resource", "service-instances", "--service-name", "databases-for-redis", "--output", "json"]
    # silent_stdout=True を指定して大きなJSONを表示させない
    res = run_command(check_cmd, silent_stdout=True)

    if res.returncode != 0:
        print("Error: インスタンス一覧の取得に失敗しました。")
        sys.exit(1)

    try:
        existing_instances = json.loads(res.stdout)
        existing_names = [inst['name'] for inst in existing_instances]
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

    # 3. パスワードの設定 (結果を出力する)
    print("\n##############################")
    print("# パスワード設定フェーズ")
    print("##############################")
    for target in targets:
        db = target['db']
        pw = target['pw']

        # defaultユーザー
        run_command(["ibmcloud", "cdb", "user-password", db, "default", pw])
        # adminユーザー
        run_command(["ibmcloud", "cdb", "user-password", db, "admin", pw])

    # 4. 設定確認 (結果を出力する)
    print("\n##############################")
    print("# 接続確認フェーズ")
    print("##############################")
    for target in targets:
        db = target['db']
        pw = target['pw']

        # defaultユーザーの接続確認
        run_command(["ibmcloud", "cdb", "cxn", db, "-a", "-u", "default", "-p", pw, "-e", "private"])
        # adminユーザーの接続確認
        run_command(["ibmcloud", "cdb", "cxn", db, "-a", "-u", "admin", "-p", pw, "-e", "private"])


if __name__ == "__main__":
    main()

```
