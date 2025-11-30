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
        cmd = ["ibmcloud"] + cmd_args + ["--output", "json"]
        result = subprocess.run(
            cmd,
            text=True,
            capture_output=True,
            encoding='utf-8'
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
```
