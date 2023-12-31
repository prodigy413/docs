~~~
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -oyaml > key.yaml

kubeseal < /tmp/ss.yaml --recovery-unseal --recovery-private-key key.yaml -o yaml
~~~

~~~
##############################
# Title:
# History
# - 2024/01/xx First release / Choi
##############################

from datetime import datetime
from openpyxl import Workbook
from openpyxl.styles import Font
from openpyxl.styles import PatternFill
from subprocess import run
from csv import reader
from pathlib import Path

##############################
# 設定必要な変数
##############################
# SSH remote host
url = ''

# タイトル：
title = ''

# CSVファイル名
csv_file = ''

# kustomizeコマンド名
cmd = ''

##############################
# 固定変数（変更不要）
##############################
# レポートファイル設定変数
items = ['DATE: ', 'File: ', 'Command: ']

# EXCEL設定変数
default_font = Font(name='Consolas')
title_font = Font(name='Consolas', b=True)
describe_font = Font(b=True, color='00FF0000')
diff_format = PatternFill(fill_type='solid', fgColor='00FFFF00')

# CSVファイル読み取り
with open(csv_file) as f:
    csv_list = [csv for csv in reader(f) if '#filename' not in csv]

##############################
# 差分確認
##############################
for csv in csv_list:
    contents = []
    path_prod = Path(csv[1])
    path_reg = Path(csv[2])
    file_path_prod = path_prod.joinpath(csv[0])
    file_path_reg = path_reg.joinpath(csv[0])
    report_file = f'{csv[0].replace(".yaml", "")}.xlsx'
    check_time = datetime.now().strftime('%Y/%m/%d %H:%M:%S')
    command = f'ssh {url} \'diff -y {file_path_prod} {file_path_reg}\''
    contents += [items[0] + check_time, items[1] + csv[0], items[2], command, '', f'{"-"*40}']
    print(*contents, sep='\n')

    diff_result = run(['ssh', url, 'cksum', file_path_prod, file_path_reg, ';', 'echo', ';', 'diff', '-y', '-t', '-w', '200', file_path_prod, file_path_reg],
                      capture_output=True, text=True)
    if diff_result.returncode in [0, 1]:
        print(diff_result.stdout)
        contents += diff_result.stdout.split('\n')
        contents += "", ""
    else:
        raise Exception('Failed to diff files')

##############################
# EXCELファイル作成
##############################
# EXCEL book/sheet作成
wb = Workbook()
ws = wb.worksheets[0]
ws = wb.active
ws.sheet_view.showGridLines = False
ws.title = title

for idx in range(len(contents)):
    ws.cell(row=idx + 1, column=1, value=contents[idx])

for row in ws.iter_rows():
    for cell in row:
        res = [e for e in ['  |  ', ' <', ' > '] if e in cell.value]
        if res:
            for x in range(26):
                ws[f'{chr(x + 65)}{cell.row}'].fill = diff_format
                ws[f'A{chr(x + 65)}{cell.row}'].fill = diff_format
            ws[f'V{cell.row}'].font = describe_font
            ws[f'V{cell.row}'].value = 'Comment here'
        if cell.value.startswith(tuple(items)):
            cell.font = title_font
        else:
            cell.font = default_font

wb.save(filename=report_file)

# CSV Sample
# #filename,prod_path,reg_path
# xxxx.yaml,/prod/test,/reg/test

~~~
