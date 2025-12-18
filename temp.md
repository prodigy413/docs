```
__init__.py


import logging

# Configure logging
# Log format example: 2025/12/18 13:10:20 - [INFO] - Task started...

logging.basicConfig(
    format="%(asctime)s - [%(levelname)s] - %(message)s",
    datefmt="%Y/%m/%d %H:%M:%S",
    level=logging.INFO,
)

info = logging.info
error = logging.error





import subprocess
import json
import sys
import common.custom_logging as mylog


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
            if not result.stdout.strip():
                return []
            return json.loads(result.stdout)
        else:
            mylog.error(result.stderr)
            sys.exit(1)
    except FileNotFoundError:
        mylog.error('Command ibmcloud is not found.')
        sys.exit(1)
    except json.JSONDecodeError:
        mylog.error("Failed to parse JSON output.")
        sys.exit(1)


def check_login() -> None:
    """Check if the user is logged in."""

    data = run_cmd(["target"])
    rg = data.get("resource_group")
    if not isinstance(rg, dict) or not rg:
        mylog.error("Not logged in. Use 'ibmcloud login' to log in.")
        sys.exit(1)





from datetime import datetime
from openpyxl.styles import Alignment, Font, Border, Side

# Get current date and time
now = datetime.now()
date_for_filename = now.strftime("%Y%m%d_%H%M%S")
date_created = f"作成日時：{now.strftime("%Y/%m/%d %H:%M:%S")}"

# Names for get_user_access_group.py
sheetname_ag = "アクセスグループ一覧"
filename_ag = f"【IBM Cloud】{sheetname_ag}_{date_for_filename}.xlsx"

# Names for get_user_access_policy.py
sheetname_ap = "アクセスポリシー権限一覧"
filename_ap = f"【IBM Cloud】{sheetname_ap}_{date_for_filename}.xlsx"

# Names for get_user_permission_classic.py
sheetname_pc = "クラシックインフラストラクチャー権限一覧"
filename_pc = f"【IBM Cloud】{sheetname_pc}_{date_for_filename}.xlsx"

# Font style
default_font = Font(name="MS PGothic", size=11)

# Border style
thin_side = Side(style="thin")
thin_border = Border(left=thin_side, right=thin_side, top=thin_side, bottom=thin_side)

# Alignment styles
center_center = Alignment(horizontal="center", vertical="center")
right_center = Alignment(horizontal="right", vertical="center")
left_center = Alignment(horizontal="left", vertical="center")
center_bottom = Alignment(horizontal="center", vertical="bottom")





from collections import defaultdict
from openpyxl import Workbook
from openpyxl.styles import Alignment, PatternFill
from openpyxl.utils import get_column_letter

import common.custom_logging as mylog
from common.functions import run_cmd, check_login
import common.variables as vars


def get_account_users() -> list:
    """Get user emails."""

    data = run_cmd(["account", "users"])
    emails = [u.get("email") for u in data if u.get("email")]
    return sorted(emails, key=str.lower)


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

    mylog.info(f"Processing members for {len(groups)} groups...")
    for i, g in enumerate(groups, 1):
        mylog.info(f"[{i}/{len(groups)}] Processing: {g}")
        members = get_group_members(g)
        for email in members:
            membership[email].add(g)
    return users, groups, membership


def create_excel(users, groups, membership):
    """Create Excel file."""

    wb = Workbook()
    ws = wb.active
    ws.title = vars.sheetname_ag

    HEADER_ROW = 3
    FIRST_USER_ROW = 4
    FIRST_GROUP_COL = 3

    # column widths
    ws.column_dimensions["A"].width = 5   # No.
    ws.column_dimensions["B"].width = 30  # User
    for col_idx in range(FIRST_GROUP_COL, FIRST_GROUP_COL + len(groups)):  # access group
        col_letter = get_column_letter(col_idx)
        ws.column_dimensions[col_letter].width = 10

    # access group row height
    ws.row_dimensions[HEADER_ROW].height = 100

    # header color
    header_fill = PatternFill(start_color="FFDCE6F1", end_color="FFDCE6F1", fill_type="solid")

    # Date created
    created_label = ws.cell(row=2, column=1, value=vars.date_created)
    created_label.font = vars.default_font

    # No. header
    no_header = ws.cell(row=HEADER_ROW, column=1, value="No.")
    no_header.alignment = vars.center_center
    no_header.fill = header_fill

    # User header
    user_header = ws.cell(row=HEADER_ROW, column=2, value="User")
    user_header.alignment = vars.center_center
    user_header.fill = header_fill

    # Access group header
    for offset, group_name in enumerate(groups):
        col = FIRST_GROUP_COL + offset
        cell = ws.cell(row=HEADER_ROW, column=col, value=group_name)
        cell.alignment = Alignment(horizontal="center", textRotation=255)
        cell.font = vars.default_font
        cell.fill = header_fill

    # data section
    checked = "■"
    unchecked = "□"

    for idx, user in enumerate(users, start=1):
        row = FIRST_USER_ROW + idx - 1

        # No. cell
        no_cell = ws.cell(row=row, column=1, value=idx)
        no_cell.alignment = vars.right_center

        # User cell
        user_cell = ws.cell(row=row, column=2, value=user)
        user_cell.number_format = "@"

        # ■ / □ for each access group
        user_groups = membership.get(user, set())
        for offset, group_name in enumerate(groups):
            col = FIRST_GROUP_COL + offset
            cell = ws.cell(row=row, column=col)

            # In the "Public Access" group, mark all users as checked.
            if group_name == "Public Access":
                cell.value = checked
            else:
                cell.value = checked if group_name in user_groups else unchecked
            cell.alignment = vars.center_center

    # Add border lines
    max_row = ws.max_row
    max_col = ws.max_column
    for r in range(3, max_row + 1):
        for c in range(1, max_col + 1):
            cell = ws.cell(row=r, column=c)
            if cell.value is not None:
                cell.border = vars.thin_border
                cell.font = vars.default_font

    # Freeze Panes
    ws.freeze_panes = ws.cell(row=FIRST_USER_ROW, column=FIRST_GROUP_COL)

    try:
        wb.save(vars.filename_ag)
        mylog.info(f"Saved: {vars.filename_ag}")
    except Exception as e:
        mylog.error(f"Failed to save Excel file: {e}")


def main():
    check_login()
    mylog.info("Task started...")
    users, groups, membership = map_user_group()
    create_excel(users, groups, membership)
    mylog.info("Task completed.")


if __name__ == "__main__":
    main()





from openpyxl import Workbook
from openpyxl.styles import Alignment
from openpyxl.utils import get_column_letter

import common.custom_logging as mylog
from common.functions import run_cmd, check_login
import common.variables as vars


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

    return sorted(valid_users, key=str.lower)


def get_user_policies(user_id: str) -> list:
    """Get access policies for a specific user."""

    return run_cmd(["iam", "user-policies", user_id])


def get_resource_group_map() -> dict:
    """Get map of resource group ID to Name."""

    try:
        data = run_cmd(["resource", "groups"])
        return {g["id"]: g["name"] for g in data if "id" in g and "name" in g}
    except Exception as e:
        mylog.error(f"Warning: Failed to fetch resource groups: {e}")
        return {}


def process_policy_data(users, rg_map):
    """Fetch and structure data for Excel."""

    processed_data = []
    max_policy_count = 0

    for i, user in enumerate(users, 1):
        mylog.info(f"[{i}/{len(users)}] Processing: {user}")
        policies = get_user_policies(user)

        if not policies:
            continue

        user_entry = {
            "user": user,
            "policies": []
        }

        for policy in policies:
            # Roles
            role_names = [r.get("display_name", "Unknown") for r in policy.get("roles", [])]
            roles_str = ", ".join(role_names)

            # Resources
            resource_attrs = []
            attributes = policy.get("resources", [])

            for res in attributes:
                attrs_list = res.get("attributes", [])

                # Resource group
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

                    if is_rg_type and name == "resource" and value in rg_map:
                        value = rg_map[value]

                    resource_attrs.append(f"{name}: {value}")

            res_str = "\n".join(resource_attrs)
            if not res_str:
                res_str = "(Account Level)"

            user_entry["policies"].append({
                "roles": roles_str,
                "resources": res_str
            })

        if len(user_entry["policies"]) > max_policy_count:
            max_policy_count = len(user_entry["policies"])

        processed_data.append(user_entry)

    return processed_data, max_policy_count


def create_excel(data, max_policy_count):
    """Create Excel file matching the image format."""

    wb = Workbook()
    ws = wb.active
    ws.title = vars.sheetname_ap

    policy_align = Alignment(vertical="top", wrap_text=True)

    # Date created
    created_label = ws.cell(row=2, column=2, value=vars.date_created)
    created_label.font = vars.default_font

    # Header
    HEADER_ROW = 3

    # No., User, Category, Policy header
    headers = ["No.", "User", "Category"]

    for i in range(max_policy_count):
        headers.append(f"Policy {i + 1}")

    for col_idx, text in enumerate(headers, 2):
        cell = ws.cell(row=HEADER_ROW, column=col_idx, value=text)
        cell.font = vars.default_font
        cell.border = vars.thin_border
        cell.alignment = vars.center_center

    # Processing data
    current_row = HEADER_ROW + 1

    for idx, entry in enumerate(data, 1):
        row_roles = current_row
        row_resources = current_row + 1

        # No. column
        cell_no = ws.cell(row=row_roles, column=2, value=idx)
        cell_no.font = vars.default_font
        cell_no.alignment = vars.center_center
        cell_no.border = vars.thin_border

        ws.merge_cells(start_row=row_roles, start_column=2, end_row=row_resources, end_column=2)
        ws.cell(row=row_resources, column=2).border = vars.thin_border

        # User column
        cell_user = ws.cell(row=row_roles, column=3, value=entry["user"])
        cell_user.font = vars.default_font
        cell_user.alignment = vars.left_center
        cell_user.border = vars.thin_border

        ws.merge_cells(start_row=row_roles, start_column=3, end_row=row_resources, end_column=3)
        ws.cell(row=row_resources, column=3).border = vars.thin_border

        # Category column
        cell_cat_roles = ws.cell(row=row_roles, column=4, value="Roles")
        cell_cat_roles.font = vars.default_font
        cell_cat_roles.border = vars.thin_border
        cell_cat_roles.alignment = vars.left_center

        cell_cat_res = ws.cell(row=row_resources, column=4, value="Resources")
        cell_cat_res.font = vars.default_font
        cell_cat_res.border = vars.thin_border
        cell_cat_res.alignment = vars.left_center

        # Policy column
        for i, policy in enumerate(entry["policies"]):
            col_idx = 5 + i

            cell_r = ws.cell(row=row_roles, column=col_idx, value=policy["roles"])
            cell_r.font = vars.default_font
            cell_r.border = vars.thin_border
            cell_r.alignment = policy_align

            cell_res = ws.cell(row=row_resources, column=col_idx, value=policy["resources"])
            cell_res.font = vars.default_font
            cell_res.border = vars.thin_border
            cell_res.alignment = policy_align

        for i in range(len(entry["policies"]), max_policy_count):
            col_idx = 5 + i
            ws.cell(row=row_roles, column=col_idx).border = vars.thin_border
            ws.cell(row=row_resources, column=col_idx).border = vars.thin_border

        current_row += 2

    ws.column_dimensions["A"].width = 2   # Empty column
    ws.column_dimensions["B"].width = 5   # No. column
    ws.column_dimensions["C"].width = 25  # User column
    ws.column_dimensions["D"].width = 15  # Category column

    # Policy column
    for i in range(max_policy_count):
        col_letter = get_column_letter(5 + i)
        ws.column_dimensions[col_letter].width = 70

    # Freeze Panes
    ws.freeze_panes = ws.cell(row=HEADER_ROW + 1, column=5)

    try:
        wb.save(vars.filename_ap)
        mylog.info(f"Saved: {vars.filename_ap}")
    except Exception as e:
        mylog.error(f"Failed to save Excel file: {e}")


def main():
    if __name__ == "__main__":
        check_login()
        mylog.info("Task started...")

        rg_map = get_resource_group_map()
        users = get_account_users()
        mylog.info(f"Processing Users (Active): {len(users)}")

        processed_data, max_policies = process_policy_data(users, rg_map)

        if processed_data:
            create_excel(processed_data, max_policies)
        else:
            mylog.info("No policy data found.")

        mylog.info("Task completed.")


if __name__ == "__main__":
    main()





from collections import defaultdict
from openpyxl import Workbook
from openpyxl.styles import Alignment, PatternFill
from openpyxl.utils import get_column_letter

import common.custom_logging as mylog
from common.functions import run_cmd, check_login
import common.variables as vars


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
    return sorted(users, key=lambda x: x["username"].lower())


def map_user_perm():
    """Map users to permissions."""
    users = get_classic_users()

    # All permissions
    master_perm = set()
    # Map user and permission
    user_perm_map = defaultdict(set)
    # Permission description
    perm_desc = {}

    mylog.info(f"Processing permissions for {len(users)} users...")

    for i, user in enumerate(users, 1):
        mylog.info(f"[{i}/{len(users)}] Processing: {user['username']}")

        perm_data = run_cmd(["sl", "user", "permissions", str(user["id"])])

        # JSON: [ {"Department": "...", "Permissions": [ {"KeyName": "...", "Assigned": "true/false"}, ... ]}, ... ]
        for dept in perm_data:
            perms = dept.get("Permissions", [])
            for p in perms:
                key_name = p.get("KeyName")
                assigned = str(p.get("Assigned", "")).lower()  # "true" or "false"
                desc = p.get("Description") or p.get("description")

                if key_name:
                    master_perm.add(key_name)
                    if desc:
                        perm_desc.setdefault(key_name, desc)
                    if assigned == "true":
                        user_perm_map[user["username"]].add(key_name)

    sorted_perm = sorted(list(master_perm))
    return users, sorted_perm, user_perm_map, perm_desc


def create_excel(users, permissions, user_perm_map, perm_desc):
    """Create Excel file."""

    wb = Workbook()
    ws = wb.active
    ws.title = vars.sheetname_pc

    # Date created
    created_label = ws.cell(row=2, column=2, value=vars.date_created)
    created_label.font = vars.default_font

    USER_ROW = 3
    EMAIL_ROW = 4
    STATUS_ROW = 5
    PERM_ROW = 6
    NO_COL = 2
    PERM_COL = 3
    USER_COL = 4

    align_center_bottom = Alignment(horizontal="center", vertical="bottom")
    header_fill = PatternFill(start_color="F4B084", end_color="F4B084", fill_type="solid")

    # Header

    # No.
    ws.merge_cells(start_row=USER_ROW, start_column=NO_COL, end_row=STATUS_ROW, end_column=NO_COL)
    no_cell = ws.cell(row=USER_ROW, column=NO_COL, value="No.")
    no_cell.alignment = align_center_bottom

    # C column label
    ws.cell(row=USER_ROW, column=PERM_COL, value="username").fill = header_fill
    ws.cell(row=EMAIL_ROW, column=PERM_COL, value="email").fill = header_fill
    ws.cell(row=STATUS_ROW, column=PERM_COL, value="status").fill = header_fill

    # User column
    for idx, user in enumerate(users):
        col = USER_COL + idx
        # username
        user_cell = ws.cell(row=USER_ROW, column=col, value=user["username"])
        user_cell.alignment = vars.left_center

        # Email
        email_cell = ws.cell(row=EMAIL_ROW, column=col, value=user["email"])
        email_cell.alignment = vars.left_center
        # Status
        status_cell = ws.cell(row=STATUS_ROW, column=col, value=user["status"])
        status_cell.alignment = vars.left_center

    # Permission Row
    current_row = PERM_ROW

    for idx, perm_name in enumerate(permissions, start=1):
        # No.
        ws.cell(row=current_row, column=NO_COL, value=idx).alignment = vars.right_center

        # Permission Name
        perm_cell = ws.cell(row=current_row, column=PERM_COL, value=perm_name)
        perm_cell.fill = header_fill
        perm_cell.alignment = vars.left_center

        # Checkboxes (■ / □)
        for u_idx, user in enumerate(users):
            col = USER_COL + u_idx
            user_perms = user_perm_map.get(user["username"], set())

            val = "■" if perm_name in user_perms else "□"
            check_cell = ws.cell(row=current_row, column=col, value=val)
            check_cell.alignment = vars.center_center

        current_row += 1

    # Footer

    # ユーザーIDの業務上必要性
    nec_row = current_row
    ws.merge_cells(start_row=nec_row, start_column=NO_COL, end_row=nec_row, end_column=PERM_COL)
    ws.cell(row=nec_row, column=NO_COL, value="ユーザーIDの業務上必要性").fill = header_fill
    current_row += 1

    # 特権
    priv_row = current_row
    ws.merge_cells(start_row=priv_row, start_column=NO_COL, end_row=priv_row + 1, end_column=NO_COL)
    priv_cell = ws.cell(row=priv_row, column=NO_COL, value="特権")
    priv_cell.fill = header_fill
    priv_cell.alignment = vars.center_center

    # 有 / 無
    ws.cell(row=priv_row, column=PERM_COL, value="有").fill = header_fill
    ws.cell(row=priv_row, column=PERM_COL).alignment = vars.center_center
    ws.cell(row=priv_row + 1, column=PERM_COL, value="無").fill = header_fill
    ws.cell(row=priv_row + 1, column=PERM_COL).alignment = vars.center_center
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

    # Styling & Dimensions
    max_row = current_row
    max_col = USER_COL + len(users) - 1

    # Border line and font
    for r in range(USER_ROW, max_row + 1):
        for c in range(NO_COL, max_col + 1):
            cell = ws.cell(row=r, column=c)
            cell.border = vars.thin_border
            cell.font = vars.default_font

    # column widths
    ws.column_dimensions['A'].width = 2
    ws.column_dimensions['B'].width = 6
    ws.column_dimensions['C'].width = 35
    for idx in range(len(users)):
        ws.column_dimensions[get_column_letter(USER_COL + idx)].width = 10

    # Freeze Panes
    ws.freeze_panes = ws.cell(row=PERM_ROW, column=USER_COL)

    # Permission List Sheet
    perm_ws = wb.create_sheet(title="パーミッションリスト")

    # Header style
    perm_header_fill = PatternFill(start_color="FFFF00", end_color="FFFF00", fill_type="solid")

    header_row = 2
    header_col = 2

    # Header
    perm_ws.cell(row=header_row, column=header_col, value="No.").fill = perm_header_fill
    perm_ws.cell(row=header_row, column=header_col + 1, value="Permission").fill = perm_header_fill
    perm_ws.cell(row=header_row, column=header_col + 2, value="Description").fill = perm_header_fill

    for col in range(header_col, header_col + 3):
        perm_ws.cell(row=header_row, column=col).alignment = vars.center_center
        perm_ws.cell(row=header_row, column=col).border = vars.thin_border
        perm_ws.cell(row=header_row, column=col).font = vars.default_font

    # Permission and description
    for idx, perm_name in enumerate(permissions, start=1):
        row = header_row + idx
        perm_ws.cell(row=row, column=header_col, value=idx).alignment = vars.right_center
        perm_ws.cell(row=row, column=header_col + 1, value=perm_name).alignment = vars.left_center
        perm_ws.cell(row=row, column=header_col + 2, value=perm_desc.get(perm_name, "")).alignment = vars.left_center

        for col in range(header_col, header_col + 3):
            cell = perm_ws.cell(row=row, column=col)
            cell.border = vars.thin_border
            cell.font = vars.default_font

    # column widths
    perm_ws.column_dimensions['A'].width = 2
    perm_ws.column_dimensions['B'].width = 6
    perm_ws.column_dimensions['C'].width = 40
    perm_ws.column_dimensions['D'].width = 80

    try:
        wb.save(vars.filename_pc)
        mylog.info(f"Saved: {vars.filename_pc}")
    except Exception as e:
        mylog.error(f"Failed to save Excel file: {e}")


def main():
    if __name__ == "__main__":
        check_login()
        mylog.info("Task started...")
        users, permissions, user_perm_map, perm_desc = map_user_perm()
        create_excel(users, permissions, user_perm_map, perm_desc)
        mylog.info("Task completed.")


if __name__ == "__main__":
    main()

```
