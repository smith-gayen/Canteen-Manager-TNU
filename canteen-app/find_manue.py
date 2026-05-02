import re

log2 = r'C:\Users\USER\.gemini\antigravity\brain\8ed1d428-ee00-4b90-acc4-5c662eb6da12\.system_generated\logs\overview.txt'
with open(log2, 'r', encoding='utf-8') as f:
    text2 = f.read()

matches2 = re.findall(r'"CodeContent":\s*"(.*?)",\s*"Description"', text2, re.DOTALL)
for i, m in enumerate(matches2):
    if 'html' in m.lower() or 'doctype' in m.lower():
        print(f'Match {i} starts with {m[:50]}')
