~~~
from openpyxl import load_workbook
from openpyxl.styles import Font

filename = 'diff2.xlsx'
title_font = Font(name='Consolas', b=True)

wb = load_workbook('20230530.xlsx')
ws = wb.worksheets[0]

for row in ws:
  for cell in row:
    try:
      if cell.value.startswith('DATE: ') or cell.value.startswith('MS: ') or cell.value.startswith('Command: ') or cell.value.startswith('metadata: '):
        cell.value = None
    except AttributeError:
      pass

wb.save(filename=filename)










from datetime import datetime
from openpyxl import Workbook
from openpyxl.styles import Font
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

wb = Workbook()
ws = wb.worksheets[0]
ws = wb.active
ws.sheet_view.showGridLines = False

for csv in csv_list:
    chdir(csv[1])
    contents.append(f"DATE: {datetime.now().strftime('%Y/%m/%d %H:%M:%S')}")
    print(f"DATE: {datetime.now().strftime('%Y/%m/%d %H:%M:%S')}")
    contents.append(f'MS: {csv[0]}')
    print(f'MS: {csv[0]}')
    contents.append('Command: ')
    print('Command: ')
    contents.append(f'cd {csv[1]}')
    print(f'cd {csv[1]}')
    contents += f'kustomize build . | ssh obi@192.168.245.101 sdiff -lw 240 {csv[2]} -', "", "----------------------------------------"
    print(f'kustomize build . | ssh obi@192.168.245.101 sdiff -lw 240 {csv[2]} -')
    print('\n----------------------------------------')
    build_result = run(["kustomize", "build", "."], capture_output=True, text=True)
    if build_result.returncode == 0:
        diff_result = run(["ssh", "obi@192.168.245.101", "sdiff", "-lw", "240", csv[2], "-"], capture_output=True, text=True, input=build_result.stdout)
        print(diff_result.stdout, "\n\n")
        contents += diff_result.stdout.split('\n')
        contents += "", ""

for idx in range(len(contents)):
    ws.cell(row=idx + 1, column=1, value=contents[idx])

for row in ws.iter_rows():
    for cell in row:
        try:
            if cell.value.startswith('DATE: ') or cell.value.startswith('MS: ') or cell.value.startswith('Command: '):
                cell.font = title_font
        except AttributeError:
            cell.font = default_font

chdir(work_dir)
wb.save(filename=filename)

~~~
