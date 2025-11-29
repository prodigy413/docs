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
    for col_idx in range(FIRST_GROUP_COL, FIRST_GROUP_COL + len(groups)): # access group
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
        bottom=thin_side,
    )

    # header color
    header_fill = PatternFill(
        start_color="FFB7DEE8",
        end_color="FFB7DEE8",
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
                cell.font = Font(name="MS PGothic")

    # Freeze top 1 row + left 2 columns (independent of row/column count)
    # ws.freeze_panes = ws.cell(row=FIRST_USER_ROW, column=FIRST_GROUP_COL)

    try:
        wb.save(filename)
        print(f"Saved: {filename}")
    except Exception as e:
        print(f"Failed to save Excel file: {e}")


if __name__ == "__main__":
    start_time = time()
    print("Task started...")

    users, groups, membership = map_user_group()
    create_excel(users, groups, membership)

    end_time = time()
    elapsed_time = timedelta(seconds=int(end_time - start_time))
    print(f"Task completed in {elapsed_time}.")
```
