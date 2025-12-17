```
import subprocess
import json
from collections import defaultdict
from datetime import datetime, timedelta
from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill, Border, Side
from openpyxl.utils import get_column_letter
import sys
from time import time


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
    """Get user emails."""

    data = run_cmd(["account", "users"])
    emails = [u.get("email") for u in data if u.get("email")]

    return sorted(emails)


def get_access_groups() -> list:
    """Get access group names."""

    data = run_cmd(["iam", "access-groups"])
    names = [g.get("name") for g in data if g.get("name")]
    return sorted(names)


def get_group_members(group_name: str) -> list:
    """Get user emails belonging to the specified access group."""

    data = run_cmd(["iam", "access-group-users", group_name])
    emails = [m.get("email") for m in data if m.get("email")]
    return emails


def map_user_group():
    """Map users to access groups."""

    users = get_account_users()
    groups = get_access_groups()

    membership = defaultdict(set)

    print(f"Processing members for {len(groups)} groups...")

    for i, g in enumerate(groups, 1):
        print(f"[{i}/{len(groups)}] Processing: {g}")
        members = get_group_members(g)
        for email in members:
            membership[email].add(g)

    return users, groups, membership


def create_excel(users, groups, membership):
    """Create Excel file."""

    today = datetime.now().strftime('%Y%m%d')
    sheetname = f"ibmcloud_access_groups_{today}"
    filename = f"{sheetname}.xlsx"

    wb = Workbook()
    ws = wb.active
    ws.title = sheetname

    HEADER_ROW = 1
    FIRST_USER_ROW = 2
    FIRST_GROUP_COL = 3

    # column widths
    ws.column_dimensions["A"].width = 5   # No.
    ws.column_dimensions["B"].width = 30  # User
    for col_idx in range(FIRST_GROUP_COL, FIRST_GROUP_COL + len(groups)):  # access group
        col_letter = get_column_letter(col_idx)
        ws.column_dimensions[col_letter].width = 5

    # access group ヘッダ行の高さ（縦書き見やすく）
    ws.row_dimensions[HEADER_ROW].height = 80

    # Common styles
    center = Alignment(horizontal="center", vertical="center")
    vertical_text = Alignment(
        horizontal="center",
        # vertical="center",
        textRotation=255,
        wrap_text=True,
    )

    # Border (thin) style
    thin_side = Side(style="thin")
    thin_border = Border(
        left=thin_side,
        right=thin_side,
        top=thin_side,
        bottom=thin_side
    )

    # header color
    header_fill = PatternFill(
        start_color="FFDCE6F1",
        end_color="FFDCE6F1",
        fill_type="solid",
    )

    # header
    no_header = ws.cell(row=HEADER_ROW, column=1, value="No.")
    no_header.alignment = center
    no_header.fill = header_fill

    user_header = ws.cell(row=HEADER_ROW, column=2, value="User")
    user_header.alignment = center
    user_header.fill = header_fill

    for offset, group_name in enumerate(groups):
        col = FIRST_GROUP_COL + offset
        cell = ws.cell(row=HEADER_ROW, column=col, value=group_name)
        cell.alignment = vertical_text
        cell.font = Font(bold=True)
        cell.fill = header_fill

    # data section
    checked = "■"
    unchecked = "□"

    for idx, user in enumerate(users, start=1):
        row = FIRST_USER_ROW + idx - 1

        # No.
        no_cell = ws.cell(row=row, column=1, value=idx)
        no_cell.alignment = Alignment(horizontal="right", vertical="center")

        # User ID (email address)
        user_cell = ws.cell(row=row, column=2, value=user)
        user_cell.number_format = "@"
        # ■ / □ for each access group
        user_groups = membership.get(user, set())
        for offset, group_name in enumerate(groups):
            col = FIRST_GROUP_COL + offset
            cell = ws.cell(row=row, column=col)
            cell.value = checked if group_name in user_groups else unchecked
            cell.alignment = center

    # Add border lines
    max_row = ws.max_row
    max_col = ws.max_column
    for r in range(1, max_row + 1):
        for c in range(1, max_col + 1):
            cell = ws.cell(row=r, column=c)
            if cell.value is not None:
                cell.border = thin_border
                cell.font = Font(name="MS PGothic", size=11)

    # Freeze Panes
    ws.freeze_panes = ws.cell(row=FIRST_USER_ROW, column=FIRST_GROUP_COL)

    try:
        wb.save(filename)
        print(f"Saved: {filename}")
    except Exception as e:
        print(f"Failed to save Excel file: {e}")


def main():
    if __name__ == "__main__":
        start_time = time()
        print("Task started...")

        users, groups, membership = map_user_group()
        create_excel(users, groups, membership)

        end_time = time()
        elapsed_time = timedelta(seconds=int(end_time - start_time))
        print(f"Task completed.\nElapsed time: {elapsed_time}.")


if __name__ == "__main__":
    main()





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





import subprocess
import json
from collections import defaultdict
from datetime import datetime, timedelta
from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill, Border, Side
from openpyxl.utils import get_column_letter
import sys
from time import time


def run_cmd(cmd_args: list) -> list:
    """Run command and return parsed JSON output."""
    try:
        cmd = ["ibmcloud"] + cmd_args + ["--output", "json"]
        result = subprocess.run(
            cmd,
            text=True,
            capture_output=True,
        )
        if result.returncode == 0:
            if not result.stdout.strip():
                return []
            return json.loads(result.stdout)
        else:
            print(f"Warning: Command failed: {' '.join(cmd)}")
            print(result.stderr)
            sys.exit(1)
    except FileNotFoundError:
        print('Command ibmcloud is not found.')
        sys.exit(1)
    except json.JSONDecodeError:
        print("Failed to parse JSON output.")
        sys.exit(1)


def get_classic_users() -> list:
    """Get Classic user details (ID, Username, Email, Status)."""

    data = run_cmd(["sl", "user", "list", "--column", "id,username,email,status"])
    users = []
    for u in data:
        user_info = {
            "id": u.get("id"),
            "username": u.get("username"),
            "email": u.get("email"),
            "status": u.get("userStatus").get("name")
        }
        if user_info["email"]:
            users.append(user_info)

    return sorted(users, key=lambda x: x["username"])


def map_user_permissions():
    """Map users to permissions based on the JSON structure provided."""
    users = get_classic_users()

    # 全てのPermissionを格納するセット（これがC列になります）
    master_permissions = set()
    # ユーザーごとの所持Permissionマップ
    user_permission_map = defaultdict(set)

    print(f"Processing permissions for {len(users)} users...")

    for i, user in enumerate(users, 1):
        print(f"[{i}/{len(users)}] Processing: {user['username']}")

        # 指定されたコマンドを実行: ibmcloud sl user permissions <ID>
        perm_data = run_cmd(["sl", "user", "permissions", str(user["id"])])

        # JSON構造: [ {"Department": "...", "Permissions": [ {"KeyName": "...", "Assigned": "true/false"}, ... ]}, ... ]
        for dept in perm_data:
            perms = dept.get("Permissions", [])
            for p in perms:
                key_name = p.get("KeyName")
                assigned = str(p.get("Assigned", "")).lower() # "true" or "false"

                if key_name:
                    # 1. マスターリストには無条件で追加（C列用）
                    master_permissions.add(key_name)

                    # 2. Assignedがtrueならユーザーの持ち物として追加（■用）
                    if assigned == "true":
                        user_permission_map[user["username"]].add(key_name)

    # Permission名をアルファベット順にソート
    sorted_permissions = sorted(list(master_permissions))

    return users, sorted_permissions, user_permission_map


def create_excel(users, permissions, user_permission_map):
    """Create Excel file based on the provided logic and layout."""

    today = datetime.now().strftime('%Y%m%d')
    sheetname = f"ibmcloud_classic_perms_{today}"
    filename = f"{sheetname}.xlsx"

    wb = Workbook()
    ws = wb.active
    ws.title = "Permissions"

    # --- Layout Constants ---
    # ヘッダー行の定義
    USER_ROW = 2   # username
    EMAIL_ROW = 3  # Email
    STATUS_ROW = 4  # Status
    PERM_ROW = 5    # Permission開始行

    NO_COL = 2      # B列
    PERM_COL = 3    # C列
    USER_COL = 4  # D列

    # Styles
    thin_side = Side(style="thin")
    thin_border = Border(left=thin_side, right=thin_side, top=thin_side, bottom=thin_side)

    align_center = Alignment(horizontal="center", vertical="center")
    align_left = Alignment(horizontal="left", vertical="center")
    align_bottom_center = Alignment(horizontal="center", vertical="bottom")

    # オレンジ色の塗りつぶし
    header_fill = PatternFill(start_color="F4B084", end_color="F4B084", fill_type="solid")

    # --- 1. Header Section ---

    # No. (B列: 行2-4結合)
    ws.merge_cells(start_row=USER_ROW, start_column=NO_COL, end_row=STATUS_ROW, end_column=NO_COL)
    no_cell = ws.cell(row=USER_ROW, column=NO_COL, value="No.")
    no_cell.alignment = align_bottom_center

    # C列ラベル
    ws.cell(row=USER_ROW, column=PERM_COL, value="username").fill = header_fill
    ws.cell(row=EMAIL_ROW, column=PERM_COL, value="Email").fill = header_fill
    ws.cell(row=STATUS_ROW, column=PERM_COL, value="Status").fill = header_fill

    # ユーザー列 (D列以降)
    for idx, user in enumerate(users):
        col = USER_COL + idx
        # username
        user_cell = ws.cell(row=USER_ROW, column=col, value=user["username"])
        user_cell.alignment = align_left

        # Email
        email_cell = ws.cell(row=EMAIL_ROW, column=col, value=user["email"])
        email_cell.alignment = align_left
        # Status
        status_cell = ws.cell(row=STATUS_ROW, column=col, value=user["status"])
        status_cell.alignment = align_left

    # --- 2. Permission Rows ---
    current_row = PERM_ROW

    for idx, perm_name in enumerate(permissions, start=1):
        # No.
        ws.cell(row=current_row, column=NO_COL, value=idx).alignment = Alignment(horizontal="right", vertical="center")

        # Permission Name
        perm_cell = ws.cell(row=current_row, column=PERM_COL, value=perm_name)
        perm_cell.fill = header_fill
        perm_cell.alignment = align_left

        # Checkboxes (■ / □)
        for u_idx, user in enumerate(users):
            col = USER_COL + u_idx
            user_perms = user_permission_map.get(user["username"], set())

            val = "■" if perm_name in user_perms else "□"
            check_cell = ws.cell(row=current_row, column=col, value=val)
            check_cell.alignment = align_center

        current_row += 1

    # --- 3. Footer Section (Fixed Rows) ---

    # ユーザーIDの業務上必要性
    nec_row = current_row
    ws.merge_cells(start_row=nec_row, start_column=NO_COL, end_row=nec_row, end_column=PERM_COL)
    ws.cell(row=nec_row, column=NO_COL, value="ユーザーIDの業務上必要性").fill = header_fill
    current_row += 1

    # 特権 (結合)
    priv_row = current_row
    ws.merge_cells(start_row=priv_row, start_column=NO_COL, end_row=priv_row+1, end_column=NO_COL)
    priv_cell = ws.cell(row=priv_row, column=NO_COL, value="特権")
    priv_cell.fill = header_fill
    priv_cell.alignment = align_center

    # 有 / 無
    ws.cell(row=priv_row, column=PERM_COL, value="有").fill = header_fill
    ws.cell(row=priv_row, column=PERM_COL).alignment = align_center
    ws.cell(row=priv_row+1, column=PERM_COL, value="無").fill = header_fill
    ws.cell(row=priv_row+1, column=PERM_COL).alignment = align_center
    current_row += 2

    # 特権の業務上必要性
    pnec_row = current_row
    ws.merge_cells(start_row=pnec_row, start_column=NO_COL, end_row=pnec_row, end_column=PERM_COL)
    ws.cell(row=pnec_row, column=NO_COL, value="特権の業務上必要性").fill = header_fill
    current_row += 1

    # 退職者検証
    ret_row = current_row
    ws.merge_cells(start_row=ret_row, start_column=NO_COL, end_row=ret_row, end_column=PERM_COL)
    ws.cell(row=ret_row, column=NO_COL, value="退職者検証").fill = header_fill
    current_row += 1

    # 削除・変更理由
    del_row = current_row
    ws.merge_cells(start_row=del_row, start_column=NO_COL, end_row=del_row, end_column=PERM_COL)
    ws.cell(row=del_row, column=NO_COL, value="削除・変更理由").fill = header_fill

    # --- 4. Styling & Dimensions ---
    max_row = current_row
    max_col = USER_COL + len(users) - 1

    # 全体に罫線とフォント適用
    for r in range(USER_ROW, max_row + 1):
        for c in range(NO_COL, max_col + 1):
            cell = ws.cell(row=r, column=c)
            cell.border = thin_border
            cell.font = Font(name="MS PGothic", size=11)

    # 列幅調整
    ws.column_dimensions['A'].width = 2
    ws.column_dimensions['B'].width = 6
    ws.column_dimensions['C'].width = 35
    for idx in range(len(users)):
        ws.column_dimensions[get_column_letter(USER_COL + idx)].width = 10

    # 枠固定
    ws.freeze_panes = ws.cell(row=PERM_ROW, column=USER_COL)
    try:
        wb.save(filename)
        print(f"Saved: {filename}")
    except Exception as e:
        print(f"Failed to save Excel file: {e}")


def main():
    if __name__ == "__main__":
        start_time = time()
        print("Task started...")

        users, permissions, user_permission_map = map_user_permissions()
        create_excel(users, permissions, user_permission_map)

        end_time = time()
        elapsed_time = timedelta(seconds=int(end_time - start_time))
        print(f"Task completed.\nElapsed time: {elapsed_time}.")


if __name__ == "__main__":
    main()

```
