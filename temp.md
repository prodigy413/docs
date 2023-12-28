~~~
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -oyaml > key.yaml

kubeseal < /tmp/ss.yaml --recovery-unseal --recovery-private-key key.yaml -o yaml
~~~

~~~python
##############################
# Title:
##############################

from datetime import datetime
from openpyxl import Workbook
from openpyxl.styles import Font
from openpyxl.styles import PatternFill
from os import chdir
from subprocess import run
from csv import reader
from pathlib import Path

##############################
# 設定必要な変数
##############################
# SSH remote host
ssh_url = ''

# タイトル：
title = ''

# CSVファイル名
csv_file = ''

# kustomizeコマンド名
kustomize_cmd = ''

##############################
# 固定変数（変更不要）
##############################
# レポートファイル設定変数
report_file = f'/tmp/{title}.xlsx'
contents = []
# work_dir = '/tmp/'

# EXCEL設定変数
default_font = Font(name='Consolas')
title_font = Font(name='Consolas', b=True)
describe_font = Font(b=True, color='00FF0000')
diff_format = PatternFill(fill_type='solid', fgColor='00FFFF00')

# EXCELファイル作成
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
    path = Path(csv[2])
    file_path = path.joinpath(csv[0])
    check_time = datetime.now().strftime('%Y/%m/%d %H:%M:%S')
    cmd01 = f'cd {csv[1]}'
    cmd02 = f'kustomize build . | ssh {ssh_url} \'sdiff -lw 200 {file_path} -\''
    contents += [f'DATE: {check_time}', f'MS: {csv[0]}', 'Command: ', cmd01, cmd02, '', f'{"-"*40}']
    print(*contents, sep='\n')

    chdir(csv[1])
    build_result = run([kustomize_cmd, 'build', '.'], capture_output=True, text=True)
    if build_result.returncode == 0:
        diff_result = run(['ssh', ssh_url, 'cksum', file_path, ';', 'echo', ';', 'sdiff', '-t', '--tabsize', '2', '-lw', '200', file_path, '-'],
                          capture_output=True, text=True, input=build_result.stdout)
        if diff_result.returncode in [0, 1]:
            print(diff_result.stdout)
            contents += diff_result.stdout.split('\n')
            contents += "", ""

##############################
# EXCELに書き込み
##############################
for idx in range(len(contents)):
    ws.cell(row=idx + 1, column=1, value=contents[idx])

for row in ws.iter_rows():
    for cell in row:
        res = [e for e in [' | ', '<', '>'] if e in cell.value]
        if res:
            for x in range(26):
                ws[f'{chr(x + 65)}{cell.row}'].fill = diff_format
                ws[f'A{chr(x + 65)}{cell.row}'].fill = diff_format
        if cell.value.startswith(tuple('DATE: ', 'MS: ', 'Command: ')):
            cell.font = title_font
        else:
            cell.font = default_font

# chdir(work_dir)
wb.save(filename=report_file)

~~~
