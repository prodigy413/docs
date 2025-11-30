```python
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
    """Get user details (ID, Email, Status)."""

    data = run_cmd(["account", "users"])
    users = []
    for u in data:
        user_info = {
            "id": u.get("userId", ""),
            "email": u.get("email", ""),
            "status": u.get("state", "")
        }
        if user_info["email"]:
            users.append(user_info)
    return sorted(users, key=lambda x: x["email"])


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
    for g in groups:
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

    # --- Layout Constants ---
    ID_ROW = 2
    EMAIL_ROW = 3
    STATUS_ROW = 4
    FIRST_GROUP_ROW = 5
    FIRST_USER_COL = 4

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
    #no_cell.fill = header_fill
    no_cell.alignment = align_bottom_center

    # C column Labels
    ws.cell(row=ID_ROW, column=3, value="ID").fill = header_fill
    ws.cell(row=EMAIL_ROW, column=3, value="Email").fill = header_fill
    ws.cell(row=STATUS_ROW, column=3, value="Status").fill = header_fill

    # --- 2. User Columns (Row 2-4, Col D~) ---
    for idx, user in enumerate(users):
        col = FIRST_USER_COL + idx

        # ID
        id_cell = ws.cell(row=ID_ROW, column=col, value=user["id"])
        #id_cell.fill = header_fill
        id_cell.alignment = align_left

        # Email
        email_cell = ws.cell(row=EMAIL_ROW, column=col, value=user["email"])
        #email_cell.fill = header_fill
        email_cell.alignment = align_left

        # Status
        status_cell = ws.cell(row=STATUS_ROW, column=col, value=user["status"])
        #status_cell.fill = header_fill
        status_cell.alignment = align_left

    # --- 3. Group Rows (Row 5~) ---
    current_row = FIRST_GROUP_ROW

    for idx, group_name in enumerate(groups, start=1):
        # No.
        ws.cell(row=current_row, column=2, value=idx).alignment = Alignment(
            horizontal="right",
            vertical="center"
        )

        # Group Name
        ws.cell(row=current_row, column=3, value=group_name).fill = header_fill

        # Checkboxes
        for u_idx, user in enumerate(users):
            col = FIRST_USER_COL + u_idx
            user_groups = membership.get(user["email"], set())

            val = "■" if group_name in user_groups else "□"
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

    # Freeze Panes
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

        users, groups, membership = map_user_group()
        create_excel(users, groups, membership)

        end_time = time()
        elapsed_time = timedelta(seconds=int(end_time - start_time))
        print(f"Task completed in {elapsed_time}.")


if __name__ == "__main__":
    main()
```

```python
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

    for g in groups:
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
        no_cell.alignment = center

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
        print(f"Task completed in {elapsed_time}.")


if __name__ == "__main__":
    main()
```
