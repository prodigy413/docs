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
        # ibmcloudコマンド実行
        cmd = ["ibmcloud"] + cmd_args + ["--output", "json"]
        result = subprocess.run(
            cmd,
            text=True,
            capture_output=True,
        )
        if result.returncode == 0:
            # 結果が空の場合は空リストを返す
            if not result.stdout.strip():
                return []
            return json.loads(result.stdout)
        else:
            # エラー時も処理を止めずに空を返すか、必要ならログ出力
            print(f"Error running command {' '.join(cmd)}: {result.stderr}")
            return []
    except FileNotFoundError:
        print('Command ibmcloud is not found.')
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"Failed to parse JSON output for command: {' '.join(cmd)}")
        return []


def get_classic_users() -> list:
    """Get Classic infrastructure user details (ID, Username, Email, Status)."""
    # Classicユーザーの一覧を取得
    data = run_cmd(["sl", "user", "list", "--columns", "id,username,email,status"])
    users = []
    for u in data:
        # Classicのステータス構造に対応
        status_val = u.get("userStatus", {}).get("name", "Unknown") if isinstance(u.get("userStatus"), dict) else str(u.get("userStatus"))
        
        user_info = {
            "id": u.get("id"),
            "username": u.get("username"),
            "email": u.get("email"),
            "status": status_val
        }
        if user_info["email"]:
            users.append(user_info)
    
    # Email順などでソート
    return sorted(users, key=lambda x: x["username"])


def get_user_permissions(user_id: int) -> set:
    """Get permissions for a specific Classic user."""
    # ユーザー個別の権限を取得
    data = run_cmd(["sl", "user", "permissions", str(user_id)])
    # keyNameを一意な識別子として使用
    perms = {p.get("keyName") for p in data if p.get("keyName")}
    return perms


def map_classic_data():
    """Map users to their classic permissions."""
    users = get_classic_users()
    all_permissions = set()
    user_permission_map = {}

    print(f"Found {len(users)} users. Fetching permissions (this may take a while)...")
    
    for user in users:
        u_perms = get_user_permissions(user["id"])
        user_permission_map[user["username"]] = u_perms
        all_permissions.update(u_perms)
    
    # Permission一覧をソートしてリスト化
    sorted_permissions = sorted(list(all_permissions))
    
    return users, sorted_permissions, user_permission_map


def create_excel(users, permissions, user_permission_map):
    """Create Excel file matching the specified image layout."""

    today = datetime.now().strftime('%Y%m%d')
    sheetname = f"ibmcloud_classic_perms_{today}"
    filename = f"{sheetname}.xlsx"

    wb = Workbook()
    ws = wb.active
    ws.title = "Permissions"

    # --- Layout Constants ---
    # 画像に基づき行番号を設定
    # Row 2: Header (No, username, User1, User2...)
    # Row 3: Email
    # Row 4: Status
    # Row 5~: Permissions
    
    HEADER_ROW_START = 2
    USERNAME_ROW = 2
    EMAIL_ROW = 3
    STATUS_ROW = 4
    FIRST_PERM_ROW = 5
    
    COL_NO = 2       # B列
    COL_LABEL = 3    # C列
    FIRST_USER_COL = 4 # D列

    # --- Styles ---
    # Border
    thin_side = Side(style="thin")
    thin_border = Border(
        left=thin_side, right=thin_side, top=thin_side, bottom=thin_side
    )

    # Alignment
    align_center = Alignment(horizontal="center", vertical="center")
    align_left = Alignment(horizontal="left", vertical="center")
    
    # Header Fill Color (Orange/Peach like image)
    header_fill = PatternFill(
        start_color="F4B084", # Excelの「アクセント2」に近い色
        end_color="F4B084",
        fill_type="solid"
    )

    # --- 1. Header Area (Rows 2-4) ---

    # B2: No. (Merged vertically for header rows? Image shows just "No." at B4 level conceptually, 
    # but let's follow the block style. Image shows No. centered in B2-B4 merge block usually, 
    # but strictly looking at image: "No." is above numbers. Let's merge B2:B4)
    ws.merge_cells(start_row=USERNAME_ROW, start_column=COL_NO, end_row=STATUS_ROW, end_column=COL_NO)
    cell_no = ws.cell(row=USERNAME_ROW, column=COL_NO, value="No.")
    cell_no.alignment = Alignment(horizontal="center", vertical="bottom") 

    # C Column Labels
    ws.cell(row=USERNAME_ROW, column=COL_LABEL, value="username").fill = header_fill
    ws.cell(row=EMAIL_ROW, column=COL_LABEL, value="Email").fill = header_fill
    ws.cell(row=STATUS_ROW, column=COL_LABEL, value="Status").fill = header_fill

    # User Columns (D ~)
    for idx, user in enumerate(users):
        col = FIRST_USER_COL + idx
        
        # Username
        c_user = ws.cell(row=USERNAME_ROW, column=col, value=user["username"])
        c_user.alignment = align_left
        
        # Email (String only, no hyperlink)
        c_email = ws.cell(row=EMAIL_ROW, column=col, value=user["email"])
        c_email.alignment = align_left
        
        # Status
        c_status = ws.cell(row=STATUS_ROW, column=col, value=user["status"])
        c_status.alignment = align_left

    # --- 2. Permission Rows (Row 5 ~) ---
    current_row = FIRST_PERM_ROW
    
    for idx, perm_name in enumerate(permissions, start=1):
        # No. Column (B)
        c_num = ws.cell(row=current_row, column=COL_NO, value=idx)
        c_num.alignment = Alignment(horizontal="right", vertical="center")

        # Permission Name (C)
        c_pname = ws.cell(row=current_row, column=COL_LABEL, value=perm_name)
        c_pname.fill = header_fill # C列はオレンジ背景
        c_pname.alignment = align_left

        # Checkboxes (D ~)
        for u_idx, user in enumerate(users):
            col = FIRST_USER_COL + u_idx
            user_perms = user_permission_map.get(user["username"], set())
            
            # 黒四角(■) or 白四角(□)
            val = "■" if perm_name in user_perms else "□"
            c_mark = ws.cell(row=current_row, column=col, value=val)
            c_mark.alignment = align_center
        
        current_row += 1

    # --- 3. Footer Fixed Rows (Image Style) ---
    
    # ユーザーIDの業務上必要性 (Merged B-C)
    r_nec = current_row
    ws.merge_cells(start_row=r_nec, start_column=COL_NO, end_row=r_nec, end_column=COL_LABEL)
    c_nec = ws.cell(row=r_nec, column=COL_NO, value="ユーザーIDの業務上必要性")
    c_nec.fill = header_fill
    c_nec.alignment = align_left
    current_row += 1
    
    # 特権 Section
    r_priv = current_row
    # "特権" Merged vertically B(r)-B(r+1)
    ws.merge_cells(start_row=r_priv, start_column=COL_NO, end_row=r_priv+1, end_column=COL_NO)
    c_priv = ws.cell(row=r_priv, column=COL_NO, value="特権")
    c_priv.fill = header_fill
    c_priv.alignment = align_center

    # "有" / "無" in Column C
    c_yes = ws.cell(row=r_priv, column=COL_LABEL, value="有")
    c_yes.fill = header_fill
    c_yes.alignment = align_center
    
    c_no = ws.cell(row=r_priv+1, column=COL_LABEL, value="無")
    c_no.fill = header_fill
    c_no.alignment = align_center
    
    current_row += 2
    
    # 特権の業務上必要性 (Merged B-C)
    r_pnec = current_row
    ws.merge_cells(start_row=r_pnec, start_column=COL_NO, end_row=r_pnec, end_column=COL_LABEL)
    c_pnec = ws.cell(row=r_pnec, column=COL_NO, value="特権の業務上必要性")
    c_pnec.fill = header_fill
    c_pnec.alignment = align_left
    current_row += 1

    # 退職者検証 (Merged B-C)
    r_ret = current_row
    ws.merge_cells(start_row=r_ret, start_column=COL_NO, end_row=r_ret, end_column=COL_LABEL)
    c_ret = ws.cell(row=r_ret, column=COL_NO, value="退職者検証")
    c_ret.fill = header_fill
    c_ret.alignment = align_left
    current_row += 1

    # 削除・変更理由 (Merged B-C)
    r_del = current_row
    ws.merge_cells(start_row=r_del, start_column=COL_NO, end_row=r_del, end_column=COL_LABEL)
    c_del = ws.cell(row=r_del, column=COL_NO, value="削除・変更理由")
    c_del.fill = header_fill
    c_del.alignment = align_left

    # --- 4. Global Styling & Formatting ---
    max_row = current_row
    max_col = FIRST_USER_COL + len(users) - 1

    # Apply Borders and Font to the whole table area
    for r in range(HEADER_ROW_START, max_row + 1):
        for c in range(COL_NO, max_col + 1):
            cell = ws.cell(row=r, column=c)
            cell.border = thin_border
            # 日本語フォント対応
            cell.font = Font(name="MS PGothic", size=11)

    # Column Widths
    ws.column_dimensions['A'].width = 2
    ws.column_dimensions[get_column_letter(COL_NO)].width = 6   # B列 No.
    ws.column_dimensions[get_column_letter(COL_LABEL)].width = 30 # C列 Permission名など
    
    for idx in range(len(users)):
        col_letter = get_column_letter(FIRST_USER_COL + idx)
        ws.column_dimensions[col_letter].width = 15 # ユーザー列

    # Freeze Panes (Permision start)
    ws.freeze_panes = ws.cell(row=FIRST_PERM_ROW, column=FIRST_USER_COL)

    try:
        wb.save(filename)
        print(f"Successfully saved Excel file: {filename}")
    except Exception as e:
        print(f"Failed to save Excel file: {e}")


def main():
    if __name__ == "__main__":
        start_time = time()
        print("Task started...")

        # Classicデータの取得とマッピング
        users, permissions, user_permission_map = map_classic_data()
        
        # Excel作成
        if users:
            create_excel(users, permissions, user_permission_map)
        else:
            print("No users found or failed to retrieve data.")

        end_time = time()
        elapsed_time = timedelta(seconds=int(end_time - start_time))
        print(f"Task completed in {elapsed_time}.")


if __name__ == "__main__":
    main()
```
