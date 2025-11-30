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
    """Get classic user details (ID, username, Email, Status)."""

    # Classic: ibmcloud sl user list
    data = run_cmd([
        "sl", "user", "list",
        "--column", "id",
        "--column", "username",
        "--column", "email",
        "--column", "status",
    ])

    users = []
    for u in data:
        # status はコマンドによって userStatus.name だったり status だったりするので両対応
        status_info = u.get("userStatus")
        if isinstance(status_info, dict):
            status = status_info.get("name")
        else:
            status = u.get("status")

        user_info = {
            "id": u.get("id"),
            "username": u.get("username"),
            "email": u.get("email"),
            "status": status,
        }
        if user_info["email"]:
            users.append(user_info)

    return sorted(users, key=lambda x: x["email"])


def get_user_permissions(user_id: int) -> dict:
    """
    Get classic permissions for a user.

    Returns:
        dict[str, bool]: { permission_keyName: enabled }
    """

    # Classic permission: ibmcloud sl user permissions USER_ID
    data = run_cmd(["sl", "user", "permissions", str(user_id)])

    perms = {}
    for p in data:
        # JSON のキー名は環境により多少違う可能性があるので、keyName を優先して拾う
        key_name = p.get("keyName") or p.get("name")
        if not key_name:
            continue

        val = p.get("value")
        if isinstance(val, str):
            enabled = val.lower() == "true"
        else:
            enabled = bool(val)

        perms[key_name] = enabled

    return perms


def map_user_permissions():
    """
    Map users to classic permissions.

    Returns:
        users: list[dict]     ... get_account_users() の結果
        permissions: list[str]... アカウント内で一度でも登場したすべての permission keyName
        membership: dict[str, set[str]]
            email -> { permission keyName, ... }  (有効な permission のみ)
    """

    users = get_account_users()
    membership = defaultdict(set)
    all_permissions = set()

    for u in users:
        perms = get_user_permissions(u["id"])
        for perm_name, enabled in perms.items():
            all_permissions.add(perm_name)
            if enabled:
                membership[u["email"]].add(perm_name)

    permissions = sorted(all_permissions)
    return users, permissions, membership


def create_excel(users, permissions, membership):
    """Create Excel file."""

    today = datetime.now().strftime('%Y%m%d')
    # シート名・ファイル名はそのまま利用（見た目のレイアウトには影響しない）
    sheetname = f"ibmcloud_access_groups_{today}"
    filename = f"{sheetname}.xlsx"

    wb = Workbook()
    ws = wb.active
    ws.title = sheetname

    # --- Layout Constants ---
    ID_ROW = 2
    EMAIL_ROW = 3
    STATUS_ROW = 4
    FIRST_GROUP_ROW = 5   # permission 一覧の先頭行
    FIRST_USER_COL = 4    # ユーザー列の開始列 (D 列)

    # Border
    thin_side = Side(style="thin")
    thin_border = Border(
        left=thin_side,
        right=thin_side,
        top=thin_side,
        bottom=thin_side
    )

    # Alignment
    align_center = Alignment(horizontal="center", vertical="center")
    align_left = Alignment(horizontal="left", vertical="center")
    align_bottom_center = Alignment(horizontal="center", vertical="bottom")

    # Header Fill Color
    header_fill = PatternFill(
        start_color="FFF8CBAD",
        end_color="FFF8CBAD",
        fill_type="solid"
    )

    # --- 1. Header Area ---

    # B2-B4 Merged: "No."
    no_cell = ws.cell(row=ID_ROW, column=2, value="No.")
    ws.merge_cells(start_row=ID_ROW, start_column=2, end_row=STATUS_ROW, end_column=2)
    no_cell.alignment = align_bottom_center

    # C column Labels
    ws.cell(row=ID_ROW, column=3, value="username").fill = header_fill
    ws.cell(row=EMAIL_ROW, column=3, value="Email").fill = header_fill
    ws.cell(row=STATUS_ROW, column=3, value="Status").fill = header_fill

    # --- 2. User Columns (Row 2-4, Col D~) ---
    for idx, user in enumerate(users):
        col = FIRST_USER_COL + idx

        # Username
        username_cell = ws.cell(row=ID_ROW, column=col, value=user["username"])
        username_cell.alignment = align_left

        # Email
        email_cell = ws.cell(row=EMAIL_ROW, column=col, value=user["email"])
        email_cell.alignment = align_left

        # Status
        status_cell = ws.cell(row=STATUS_ROW, column=col, value=user["status"])
        status_cell.alignment = align_left

    # --- 3. Permission Rows (Row 5~) ---
    current_row = FIRST_GROUP_ROW

    for idx, perm_name in enumerate(permissions, start=1):
        # No.
        ws.cell(row=current_row, column=2, value=idx).alignment = Alignment(
            horizontal="right",
            vertical="center"
        )

        # Permission Name (C 列)
        ws.cell(row=current_row, column=3, value=perm_name).fill = header_fill

        # Checkboxes for each user
        for u_idx, user in enumerate(users):
            col = FIRST_USER_COL + u_idx
            user_perms = membership.get(user["email"], set())

            val = "■" if perm_name in user_perms else "□"
            c_mark = ws.cell(row=current_row, column=col, value=val)
            c_mark.alignment = align_center

        current_row += 1

    # --- 4. Footer Fixed Rows ---

    # Necessity
    r_nec = current_row
    ws.cell(row=r_nec, column=2, value="ユーザーIDの業務上必要性").fill = header_fill
    ws.merge_cells(start_row=r_nec, start_column=2, end_row=r_nec, end_column=3)
    current_row += 1

    # Privilege (Merged)
    r_priv = current_row
    c_priv = ws.cell(row=r_priv, column=2, value="特権")
    c_priv.fill = header_fill
    c_priv.alignment = align_center
    ws.merge_cells(start_row=r_priv, start_column=2, end_row=r_priv+1, end_column=2)

    # Yes / No
    ws.cell(row=r_priv, column=3, value="有").fill = header_fill
    ws.cell(row=r_priv+1, column=3, value="無").fill = header_fill
    ws.cell(row=r_priv, column=3).alignment = align_center
    ws.cell(row=r_priv+1, column=3).alignment = align_center
    current_row += 2

    # Privilege Necessity
    r_pnec = current_row
    ws.cell(row=r_pnec, column=2, value="特権の業務上必要性").fill = header_fill
    ws.merge_cells(start_row=r_pnec, start_column=2, end_row=r_pnec, end_column=3)
    current_row += 1

    # Retirement Verification
    r_ret = current_row
    ws.cell(row=r_ret, column=2, value="退職者検証").fill = header_fill
    ws.merge_cells(start_row=r_ret, start_column=2, end_row=r_ret, end_column=3)
    current_row += 1

    # Reason for deletion/change
    r_reas = current_row
    ws.cell(row=r_reas, column=2, value="削除・変更理由").fill = header_fill
    ws.merge_cells(start_row=r_reas, start_column=2, end_row=r_reas, end_column=3)

    # --- 5. Global Styling (Font & Borders) ---
    max_row = current_row
    max_col = FIRST_USER_COL + len(users) - 1

    for r in range(2, max_row + 1):
        for c in range(2, max_col + 1):
            cell = ws.cell(row=r, column=c)
            cell.border = thin_border
            cell.font = Font(name="MS PGothic", size=11)

    # --- 6. Dimensions ---
    ws.column_dimensions['A'].width = 2
    ws.column_dimensions['B'].width = 8
    ws.column_dimensions['C'].width = 25
    for idx in range(len(users)):
        col_letter = get_column_letter(FIRST_USER_COL + idx)
        ws.column_dimensions[col_letter].width = 10

    # ヘッダー固定設定は元コードを維持
    ws.freeze_panes = ws.cell(row=FIRST_GROUP_ROW, column=FIRST_USER_COL)

    try:
        wb.save(filename)
        print(f"Saved: {filename}")
    except Exception as e:
        print(f"Failed to save Excel file: {e}")


def main():
    if __name__ == "__main__":
        start_time = time()
        print("Task started...")

        # Classic permission ベースのマッピングに変更
        users, permissions, membership = map_user_permissions()
        create_excel(users, permissions, membership)

        end_time = time()
        elapsed_time = timedelta(seconds=int(end_time - start_time))
        print(f"Task completed in {elapsed_time}.")


if __name__ == "__main__":
    main()

```
