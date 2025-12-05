```python
import subprocess
import json
import sys
from time import time
from datetime import datetime, timedelta
from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, Border, Side
from openpyxl.utils import get_column_letter


def run_cmd(cmd_args: list) -> list:
    """Run command and return parsed JSON output."""
    try:
        result = subprocess.run(
            ["ibmcloud"] + cmd_args + ["--output", "json"],
            text=True,
            capture_output=True,
            encoding='utf-8'
        )
        if result.returncode == 0:
            return json.loads(result.stdout)
        else:
            print(result.stderr)
            sys.exit(1)
    except FileNotFoundError:
        print('Command ibmcloud is not found.')
        sys.exit(1)
    except json.JSONDecodeError:
        print("Failed to parse JSON output.")
        sys.exit(1)


def get_account_users() -> list:
    """Get user userIds (Skip pending users)."""
    data = run_cmd(["account", "users"])
    valid_users = []

    for u in data:
        state = u.get("state", "").upper()
        if state == "PENDING":
            continue

        user_id = u.get("userId")
        if user_id:
            valid_users.append(user_id)

    return sorted(valid_users)


def get_user_policies(user_id: str) -> list:
    """Get access policies for a specific user."""
    return run_cmd(["iam", "user-policies", user_id])


def get_resource_group_map() -> dict:
    """Get map of resource group ID to Name."""
    try:
        data = run_cmd(["resource", "groups"])
        return {g["id"]: g["name"] for g in data if "id" in g and "name" in g}
    except Exception as e:
        print(f"Warning: Failed to fetch resource groups: {e}")
        return {}


def process_policy_data(users, rg_map):
    """Fetch and structure data for Excel."""
    processed_data = []
    max_policy_count = 0

    for i, user in enumerate(users, 1):
        print(f"[{i}/{len(users)}] Processing: {user}")
        policies = get_user_policies(user)

        if not policies:
            continue

        user_entry = {
            "user": user,
            "policies": []
        }

        for policy in policies:
            # 1. Roles
            role_names = [r.get("display_name", "Unknown") for r in policy.get("roles", [])]
            roles_str = ", ".join(role_names)

            # 2. Resources
            resource_attrs = []
            attributes = policy.get("resources", [])

            for res in attributes:
                attrs_list = res.get("attributes", [])

                # リソースグループ判定
                is_rg_type = False
                for attr in attrs_list:
                    if attr.get("name") == "resourceType" and attr.get("value") == "resource-group":
                        is_rg_type = True
                        break

                for attr in attrs_list:
                    name = attr.get("name")
                    value = attr.get("value")

                    if name == "accountId":
                        continue

                    # ID -> Name 置換
                    if is_rg_type and name == "resource" and value in rg_map:
                        value = rg_map[value]

                    # Excel内で見やすくするため "key: value" 形式にしてリスト化
                    resource_attrs.append(f"{name}: {value}")

            # 画像に合わせて改行区切りにする
            res_str = "\n".join(resource_attrs)
            if not res_str:
                res_str = "(Account Level)"

            user_entry["policies"].append({
                "roles": roles_str,
                "resources": res_str
            })

        # 最大ポリシー数を更新
        if len(user_entry["policies"]) > max_policy_count:
            max_policy_count = len(user_entry["policies"])

        processed_data.append(user_entry)

    return processed_data, max_policy_count


def create_excel(data, max_policy_count):
    """Create Excel file matching the image format."""

    today = datetime.now().strftime('%Y%m%d')
    sheetname = f"ibmcloud_user_policies_{today}"
    filename = f"{sheetname}.xlsx"

    wb = Workbook()
    ws = wb.active
    ws.title = sheetname

    # フォント設定 (MS PGothic, Boldなし)
    font_style = Font(name="Yu Gothic", size=11, bold=False)

    # 罫線設定
    thin_side = Side(style="thin")
    thin_border = Border(
        left=thin_side,
        right=thin_side,
        top=thin_side,
        bottom=thin_side
    )

    # 配置設定
    policy_align = Alignment(vertical="top", wrap_text=True)  # Resourcesは見やすく左寄せ・折り返し
    left_align = Alignment(horizontal="left", vertical="center")
    center_align = Alignment(horizontal="center", vertical="center")

    # --- ヘッダー作成 (Row 2) ---
    HEADER_ROW = 2

    # 固定ヘッダー
    headers = ["No.", "User", "Category"]
    # 動的ヘッダー (Policy 1, Policy 2...)
    for i in range(max_policy_count):
        headers.append(f"Policy {i+1}")

    for col_idx, text in enumerate(headers, 2):
        cell = ws.cell(row=HEADER_ROW, column=col_idx, value=text)
        cell.font = font_style
        cell.border = thin_border
        cell.alignment = center_align

# --- データ出力 ---
    current_row = 3

    # enumerateで連番(idx)を取得
    for idx, entry in enumerate(data, 1):
        row_roles = current_row
        row_resources = current_row + 1

        # 1. No.列 (B列: column=2)
        cell_no = ws.cell(row=row_roles, column=2, value=idx)
        cell_no.font = font_style
        cell_no.alignment = center_align
        cell_no.border = thin_border

        # No.列の結合
        ws.merge_cells(start_row=row_roles, start_column=2, end_row=row_resources, end_column=2)
        ws.cell(row=row_resources, column=2).border = thin_border

        # 2. User列 (C列: column=3)
        cell_user = ws.cell(row=row_roles, column=3, value=entry["user"])
        cell_user.font = font_style
        cell_user.alignment = left_align
        cell_user.border = thin_border

        # User列の結合
        ws.merge_cells(start_row=row_roles, start_column=3, end_row=row_resources, end_column=3)
        ws.cell(row=row_resources, column=3).border = thin_border

        # 3. Category列 (D列: column=4)
        cell_cat_roles = ws.cell(row=row_roles, column=4, value="Roles")
        cell_cat_roles.font = font_style
        cell_cat_roles.border = thin_border
        cell_cat_roles.alignment = left_align

        cell_cat_res = ws.cell(row=row_resources, column=4, value="Resources")
        cell_cat_res.font = font_style
        cell_cat_res.border = thin_border
        cell_cat_res.alignment = left_align

        # 4. Policy列 (E列以降: column=5 + i)
        for i, policy in enumerate(entry["policies"]):
            col_idx = 5 + i

            # Roles書き込み
            cell_r = ws.cell(row=row_roles, column=col_idx, value=policy["roles"])
            cell_r.font = font_style
            cell_r.border = thin_border
            cell_r.alignment = policy_align

            # Resources書き込み
            cell_res = ws.cell(row=row_resources, column=col_idx, value=policy["resources"])
            cell_res.font = font_style
            cell_res.border = thin_border
            cell_res.alignment = policy_align

        # 空白セルの罫線処理 (開始位置を5に変更)
        for i in range(len(entry["policies"]), max_policy_count):
            col_idx = 5 + i
            ws.cell(row=row_roles, column=col_idx).border = thin_border
            ws.cell(row=row_resources, column=col_idx).border = thin_border

        current_row += 2

# 列幅調整
    ws.column_dimensions["A"].width = 2   # A列: 空列(狭く)
    ws.column_dimensions["B"].width = 5   # B列: No.
    ws.column_dimensions["C"].width = 25  # C列: User
    ws.column_dimensions["D"].width = 15  # D列: Category

    # Policy列 (E列以降)
    for i in range(max_policy_count):
        col_letter = get_column_letter(5 + i)  # 5 = E列
        ws.column_dimensions[col_letter].width = 70

    # Freeze Panes
    ws.freeze_panes = ws.cell(row=HEADER_ROW+1, column=5)

    try:
        wb.save(filename)
        print(f"Saved: {filename}")
    except Exception as e:
        print(f"Failed to save Excel file: {e}")


def main():
    if __name__ == "__main__":
        start_time = time()
        print("Task started...")

        rg_map = get_resource_group_map()

        users = get_account_users()
        print(f"Processing Users (Active): {len(users)}")

        # データ取得・整形
        processed_data, max_policies = process_policy_data(users, rg_map)

        # Excel作成
        if processed_data:
            create_excel(processed_data, max_policies)
        else:
            print("No policy data found.")

        end_time = time()
        elapsed_time = timedelta(seconds=int(end_time - start_time))
        print(f"Task completed.\nElapsed time: {elapsed_time}.")


if __name__ == "__main__":
    main()

```
