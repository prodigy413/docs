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
    sheetname = f"アクセスグループ一覧_{today}"
    filename = f"【IBM Cloud】{sheetname}.xlsx"

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
        ws.column_dimensions[col_letter].width = 10

    # access group row height
    ws.row_dimensions[HEADER_ROW].height = 100

    # Common styles
    center = Alignment(horizontal="center", vertical="center")
    vertical_text = Alignment(
        horizontal="center",
        textRotation=255
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
            # In the "Public Access" group, mark all users as checked.
            if group_name == "Public Access":
                cell.value = checked
            else:
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
    start_time = time()
    print("Task started...")

    users, groups, membership = map_user_group()
    create_excel(users, groups, membership)

    end_time = time()
    elapsed_time = timedelta(seconds=int(end_time - start_time))
    print(f"Task completed.\nElapsed time: {elapsed_time}")


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

    today = datetime.now().strftime('%Y%m%d')
    sheetname = f"アクセスポリシー権限一覧_{today}"
    filename = f"【IBM Cloud】{sheetname}.xlsx"

    wb = Workbook()
    ws = wb.active
    ws.title = sheetname

    font_style = Font(name="Yu Gothic", size=11, bold=False)

    thin_side = Side(style="thin")
    thin_border = Border(
        left=thin_side,
        right=thin_side,
        top=thin_side,
        bottom=thin_side
    )

    policy_align = Alignment(vertical="top", wrap_text=True)
    left_align = Alignment(horizontal="left", vertical="center")
    center_align = Alignment(horizontal="center", vertical="center")

    # Header
    HEADER_ROW = 2

    headers = ["No.", "User", "Category"]

    for i in range(max_policy_count):
        headers.append(f"Policy {i+1}")

    for col_idx, text in enumerate(headers, 2):
        cell = ws.cell(row=HEADER_ROW, column=col_idx, value=text)
        cell.font = font_style
        cell.border = thin_border
        cell.alignment = center_align

    # Processing data
    current_row = 3

    for idx, entry in enumerate(data, 1):
        row_roles = current_row
        row_resources = current_row + 1

        # No. column
        cell_no = ws.cell(row=row_roles, column=2, value=idx)
        cell_no.font = font_style
        cell_no.alignment = center_align
        cell_no.border = thin_border

        ws.merge_cells(start_row=row_roles, start_column=2, end_row=row_resources, end_column=2)
        ws.cell(row=row_resources, column=2).border = thin_border

        # User column
        cell_user = ws.cell(row=row_roles, column=3, value=entry["user"])
        cell_user.font = font_style
        cell_user.alignment = left_align
        cell_user.border = thin_border

        ws.merge_cells(start_row=row_roles, start_column=3, end_row=row_resources, end_column=3)
        ws.cell(row=row_resources, column=3).border = thin_border

        # Category column
        cell_cat_roles = ws.cell(row=row_roles, column=4, value="Roles")
        cell_cat_roles.font = font_style
        cell_cat_roles.border = thin_border
        cell_cat_roles.alignment = left_align

        cell_cat_res = ws.cell(row=row_resources, column=4, value="Resources")
        cell_cat_res.font = font_style
        cell_cat_res.border = thin_border
        cell_cat_res.alignment = left_align

        # Policy column
        for i, policy in enumerate(entry["policies"]):
            col_idx = 5 + i

            cell_r = ws.cell(row=row_roles, column=col_idx, value=policy["roles"])
            cell_r.font = font_style
            cell_r.border = thin_border
            cell_r.alignment = policy_align

            cell_res = ws.cell(row=row_resources, column=col_idx, value=policy["resources"])
            cell_res.font = font_style
            cell_res.border = thin_border
            cell_res.alignment = policy_align

        for i in range(len(entry["policies"]), max_policy_count):
            col_idx = 5 + i
            ws.cell(row=row_roles, column=col_idx).border = thin_border
            ws.cell(row=row_resources, column=col_idx).border = thin_border

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

        processed_data, max_policies = process_policy_data(users, rg_map)

        if processed_data:
            create_excel(processed_data, max_policies)
        else:
            print("No policy data found.")

        end_time = time()
        elapsed_time = timedelta(seconds=int(end_time - start_time))
        print(f"Task completed.\nElapsed time: {elapsed_time}")


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
            if not result.stdout.strip():
                return []
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


def map_user_permissions():
    """Map users to permissions based on the JSON structure provided."""
    users = get_classic_users()

    # All permissions
    master_permissions = set()
    # Map user and permission
    user_permission_map = defaultdict(set)
    # Permission description
    permission_descriptions = {}

    print(f"Processing permissions for {len(users)} users...")

    for i, user in enumerate(users, 1):
        print(f"[{i}/{len(users)}] Processing: {user['username']}")

        perm_data = run_cmd(["sl", "user", "permissions", str(user["id"])])

        # JSON: [ {"Department": "...", "Permissions": [ {"KeyName": "...", "Assigned": "true/false"}, ... ]}, ... ]
        for dept in perm_data:
            perms = dept.get("Permissions", [])
            for p in perms:
                key_name = p.get("KeyName")
                assigned = str(p.get("Assigned", "")).lower()  # "true" or "false"
                desc = p.get("Description") or p.get("description")

                if key_name:
                    master_permissions.add(key_name)
                    if desc:
                        permission_descriptions.setdefault(key_name, desc)
                    if assigned == "true":
                        user_permission_map[user["username"]].add(key_name)

    sorted_permissions = sorted(list(master_permissions))

    return users, sorted_permissions, user_permission_map, permission_descriptions


def create_excel(users, permissions, user_permission_map, permission_descriptions):
    """Create Excel file."""

    today = datetime.now().strftime('%Y%m%d')
    sheetname = f"クラシックインフラストラクチャー権限一覧_{today}"
    filename = f"【IBM Cloud】{sheetname}.xlsx"

    wb = Workbook()
    ws = wb.active
    ws.title = sheetname

    USER_ROW = 2
    EMAIL_ROW = 3
    STATUS_ROW = 4
    PERM_ROW = 5
    NO_COL = 2
    PERM_COL = 3
    USER_COL = 4

    # Styles
    thin_side = Side(style="thin")
    thin_border = Border(left=thin_side, right=thin_side, top=thin_side, bottom=thin_side)

    align_center = Alignment(horizontal="center", vertical="center")
    align_left = Alignment(horizontal="left", vertical="center")
    align_bottom_center = Alignment(horizontal="center", vertical="bottom")

    header_fill = PatternFill(start_color="F4B084", end_color="F4B084", fill_type="solid")

    # Header

    # No.
    ws.merge_cells(start_row=USER_ROW, start_column=NO_COL, end_row=STATUS_ROW, end_column=NO_COL)
    no_cell = ws.cell(row=USER_ROW, column=NO_COL, value="No.")
    no_cell.alignment = align_bottom_center

    # C column label
    ws.cell(row=USER_ROW, column=PERM_COL, value="username").fill = header_fill
    ws.cell(row=EMAIL_ROW, column=PERM_COL, value="email").fill = header_fill
    ws.cell(row=STATUS_ROW, column=PERM_COL, value="status").fill = header_fill

    # User column
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

    # Permission Row
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

    # Footer

    # ユーザーIDの業務上必要性
    nec_row = current_row
    ws.merge_cells(start_row=nec_row, start_column=NO_COL, end_row=nec_row, end_column=PERM_COL)
    ws.cell(row=nec_row, column=NO_COL, value="ユーザーIDの業務上必要性").fill = header_fill
    current_row += 1

    # 特権
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

    # Styling & Dimensions
    max_row = current_row
    max_col = USER_COL + len(users) - 1

    # Border line and font
    for r in range(USER_ROW, max_row + 1):
        for c in range(NO_COL, max_col + 1):
            cell = ws.cell(row=r, column=c)
            cell.border = thin_border
            cell.font = Font(name="MS PGothic", size=11)

    # column widths
    ws.column_dimensions['A'].width = 2
    ws.column_dimensions['B'].width = 6
    ws.column_dimensions['C'].width = 35
    for idx in range(len(users)):
        ws.column_dimensions[get_column_letter(USER_COL + idx)].width = 10

    # Freeze Panes
    ws.freeze_panes = ws.cell(row=PERM_ROW, column=USER_COL)

    perm_ws = wb.create_sheet(title="パーミッションリスト")

    # Header style for permission list sheet (yellow)
    perm_header_fill = PatternFill(start_color="FFFF00", end_color="FFFF00", fill_type="solid")

    header_row = 2   # 1行目は空
    header_col = 2   # A列は空なのでB列から

    perm_ws.cell(row=header_row, column=header_col, value="No.").fill = perm_header_fill
    perm_ws.cell(row=header_row, column=header_col + 1, value="Permission").fill = perm_header_fill
    perm_ws.cell(row=header_row, column=header_col + 2, value="Description").fill = perm_header_fill

    for col in range(header_col, header_col + 3):
        perm_ws.cell(row=header_row, column=col).alignment = align_center
        perm_ws.cell(row=header_row, column=col).border = thin_border
        perm_ws.cell(row=header_row, column=col).font = Font(name="MS PGothic", size=11)

    for idx, perm_name in enumerate(permissions, start=1):
        row = header_row + idx
        perm_ws.cell(row=row, column=header_col, value=idx).alignment = align_left
        perm_ws.cell(row=row, column=header_col + 1, value=perm_name).alignment = align_left
        perm_ws.cell(row=row, column=header_col + 2, value=permission_descriptions.get(perm_name, "")).alignment = align_left

        for col in range(header_col, header_col + 3):
            cell = perm_ws.cell(row=row, column=col)
            cell.border = thin_border
            cell.font = Font(name="MS PGothic", size=11)

    # column widths
    perm_ws.column_dimensions['A'].width = 2
    perm_ws.column_dimensions['B'].width = 6
    perm_ws.column_dimensions['C'].width = 40
    perm_ws.column_dimensions['D'].width = 80

    try:
        wb.save(filename)
        print(f"Saved: {filename}")
    except Exception as e:
        print(f"Failed to save Excel file: {e}")


def main():
    if __name__ == "__main__":
        start_time = time()
        print("Task started...")

        users, permissions, user_permission_map, permission_descriptions = map_user_permissions()
        create_excel(users, permissions, user_permission_map, permission_descriptions)

        end_time = time()
        elapsed_time = timedelta(seconds=int(end_time - start_time))
        print(f"Task completed.\nElapsed time: {elapsed_time}")


if __name__ == "__main__":
    main()
```
