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
from os import chdir
from subprocess import run
from csv import reader

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
report_file = f'/tmp/{title}.xlsx'
items = ['DATE: ', 'File: ', 'Command: ']
contents = []

# EXCEL設定変数
default_font = Font(name='Consolas')
title_font = Font(name='Consolas', b=True)
describe_font = Font(b=True, color='00FF0000')
diff_format = PatternFill(fill_type='solid', fgColor='00FFFF00')

# EXCEL book/sheet作成
wb = Workbook()
ws = wb.worksheets[0]
ws = wb.active
ws.sheet_view.showGridLines = False
ws.title = title

# CSVファイル読み取り
with open(csv_file) as f:
    csv_list = [csv for csv in reader(f) if '#filename' not in csv]

##############################
# 差分確認
##############################
for csv in csv_list:
    check_time = datetime.now().strftime('%Y/%m/%d %H:%M:%S')
    cmd01 = f'cd {csv[1]}'
    cmd02 = f'kustomize build . | kubectl diff -f -'
    contents += [items[0] + check_time, items[1] + csv[0], items[2], cmd01, cmd02, '', f'{"-"*40}']
    print(*contents, sep='\n')

    chdir(csv[1])
    build_result = run([cmd, 'build', '.'], capture_output=True, text=True)
    if build_result.returncode == 0:
        diff_result_01 = run(['kubectl', 'diff', '-f', '-'], capture_output=True, text=True, input=build_result.stdout)
        diff_result_02 = run(['kubectl', 'diff', '-f', '-'], capture_output=True, text=True, input=build_result.stdout)
        if diff_result_01.returncode == 0 and diff_result_02.returncode in [0, 1]:
            print(f'{diff_result_01.stdout}\n\n{diff_result_02.stdout}')
            contents += diff_result_01.stdout.split('\n')
            contents += diff_result_02.stdout.split('\n')
            contents += "", ""
        else:
            raise Exception('Failed to diff files')
    else:
        raise Exception('Failed to build kustomize.')

##############################
# EXCELファイル作成
##############################
for idx in range(len(contents)):
    ws.cell(row=idx + 1, column=1, value=contents[idx])

for row in ws.iter_rows():
    for cell in row:
        if cell.value.startswith(('+ ', '- ')):
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
# #filename,local_path
# xxxx.yaml,/home/test/test

~~~
