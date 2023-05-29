~~~
from datetime import datetime
from openpyxl import Workbook
from openpyxl.styles import Font
from openpyxl.styles import PatternFill
from os import chdir
from subprocess import run
from csv import reader

work_dir = r'/home/obi/test/develop-code/python/kubernets/diff_with_excel_01'
filename = 'diff.xlsx'
contents = []

with open('lists.csv') as f:
    csv_list = [csv for csv in reader(f)]

title_font = Font(b=True)
describe_font = Font(b=True, color='00FF0000')
diff_format = PatternFill(fill_type='solid', fgColor='00FFFF00')

wb = Workbook()
ws = wb.worksheets[0]
ws = wb.active
ws.sheet_view.showGridLines = False

for csv in csv_list:
    chdir(csv[1])
    contents.append(f"DATE: {datetime.now().strftime('%Y/%m/%d %H:%M:%S')}")
    contents.append(f'MS: {csv[0]}')
    contents.append('Command: ')
    contents.append(f'cd {csv[1]}')
    contents += 'kustomize build . | kubectl diff -f -', "", "----------------------------------------"
    build_result = run(["kustomize", "build", "."], capture_output=True, text=True)
    if build_result.returncode == 0:
        diff_result = run(["kubectl", "diff", "-f", "-"], capture_output=True, text=True, input=build_result.stdout)
        contents += diff_result.stdout.split('\n')
        contents += "", ""

for idx in range(len(contents)):
    ws.cell(row=idx + 1, column=1, value=contents[idx])

for row in ws.iter_rows():
    for cell in row:
        try:
            if cell.value.startswith('+ ') or cell.value.startswith('- '):
                for x in range(26):
                    ws[f'{chr(x + 65)}{cell.row}'].fill = diff_format
                ws[f'M{cell.row}'].font = describe_font
                ws[f'M{cell.row}'].value = 'Comment here.'
            elif cell.value.startswith('DATE: ') or cell.value.startswith('MS: ') or cell.value.startswith('Command: '):
                cell.font = title_font
        except AttributeError:
            pass

chdir(work_dir)
wb.save(filename=filename)





nginx01,/home/obi/test/develop-code/python/kubernets/diff_with_excel_01/kustomize/nginx01
nginx02,/home/obi/test/develop-code/python/kubernets/diff_with_excel_01/kustomize/nginx02
nginx03,/home/obi/test/develop-code/python/kubernets/diff_with_excel_01/kustomize/nginx03





from datetime import datetime
from openpyxl import Workbook
from openpyxl.styles import Font
from openpyxl.styles import PatternFill
from os import chdir
from subprocess import run
from csv import reader

work_dir = r'/home/obi/test/develop-code/python/kubernets/diff_with_excel_02'
filename = 'diff.xlsx'
contents = []

with open('lists.csv') as f:
    csv_list = [csv for csv in reader(f)]

default_font = Font(name='Consolas')
title_font = Font(name='Consolas', b=True)
describe_font = Font(b=True, color='00FF0000')
diff_format = PatternFill(fill_type='solid', fgColor='00FFFF00')

wb = Workbook()
ws = wb.worksheets[0]
ws = wb.active
ws.sheet_view.showGridLines = False

for csv in csv_list:
    chdir(csv[1])
    contents.append(f"DATE: {datetime.now().strftime('%Y/%m/%d %H:%M:%S')}")
    contents.append(f'MS: {csv[0]}')
    contents.append('Command: ')
    contents.append(f'cd {csv[1]}')
    contents += f'kustomize build . | sdiff -lw 240 {csv[2]} -', "", "----------------------------------------"
    build_result = run(["kustomize", "build", "."], capture_output=True, text=True)
    if build_result.returncode == 0:
        diff_result = run(["sdiff", "-lw", "240", csv[2], "-"], capture_output=True, text=True, input=build_result.stdout)
        contents += diff_result.stdout.split('\n')
        contents += "", ""

for idx in range(len(contents)):
    ws.cell(row=idx + 1, column=1, value=contents[idx])

for row in ws.iter_rows(min_col=1, max_col=26):
    for cell in row:
        try:
            if cell.value.startswith('+ ') or cell.value.startswith('- '):
                for x in range(26):
                    ws[f'{chr(x + 65)}{cell.row}'].fill = diff_format
                ws[f'M{cell.row}'].font = describe_font
                ws[f'M{cell.row}'].value = 'Comment here.'
            elif cell.value.startswith('DATE: ') or cell.value.startswith('MS: ') or cell.value.startswith('Command: '):
                cell.font = title_font
        except AttributeError:
            cell.font = default_font

chdir(work_dir)
wb.save(filename=filename)





nginx01,/home/obi/test/develop-code/python/kubernets/diff_with_excel_02/kustomize/nginx01,/home/obi/test/develop-code/python/kubernets/diff_with_excel_02/kustomize/nginx01/test01.yaml
nginx02,/home/obi/test/develop-code/python/kubernets/diff_with_excel_02/kustomize/nginx02,/home/obi/test/develop-code/python/kubernets/diff_with_excel_02/kustomize/nginx01/test01.yaml
nginx03,/home/obi/test/develop-code/python/kubernets/diff_with_excel_02/kustomize/nginx03,/home/obi/test/develop-code/python/kubernets/diff_with_excel_02/kustomize/nginx01/test01.yaml

~~~
