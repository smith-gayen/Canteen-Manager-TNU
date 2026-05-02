import os
import re

log1 = r'C:\Users\USER\.gemini\antigravity\brain\5b659353-21d1-4cf5-9eea-1fb36e769b2b\.system_generated\logs\overview.txt'
with open(log1, 'r', encoding='utf-8') as f:
    text = f.read()

# find write_to_file calls for main.html
matches = re.findall(r'"CodeContent":\s*"(.*?)",\s*"Description"', text, re.DOTALL)
for i, m in enumerate(matches):
    if 'html' in m.lower():
        content = m.encode('utf-8').decode('unicode_escape')
        with open(f'main_extracted_{i}.html', 'w', encoding='utf-8') as out:
            out.write(content)
        print(f'Extracted main.html to main_extracted_{i}.html')

log2 = r'C:\Users\USER\.gemini\antigravity\brain\8ed1d428-ee00-4b90-acc4-5c662eb6da12\.system_generated\logs\overview.txt'
with open(log2, 'r', encoding='utf-8') as f:
    text2 = f.read()

matches2 = re.findall(r'"CodeContent":\s*"(.*?)",\s*"Description"', text2, re.DOTALL)
for i, m in enumerate(matches2):
    if 'html' in m.lower():
        content = m.encode('utf-8').decode('unicode_escape')
        with open(f'manue_extracted_{i}.html', 'w', encoding='utf-8') as out:
            out.write(content)
        print(f'Extracted manue.html to manue_extracted_{i}.html')
