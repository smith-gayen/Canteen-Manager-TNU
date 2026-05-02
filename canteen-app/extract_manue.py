import json
import re
import os

log2 = r'C:\Users\USER\.gemini\antigravity\brain\8ed1d428-ee00-4b90-acc4-5c662eb6da12\.system_generated\logs\overview.txt'
with open(log2, 'r', encoding='utf-8') as f:
    text2 = f.read()

# Let's search for CodeContent strings
matches = re.findall(r'"CodeContent":\s*"(.*?)"', text2, re.DOTALL)
count = 0
for i, m in enumerate(matches):
    if 'html' in m.lower():
        try:
            content = m.encode('utf-8').decode('unicode_escape')
            with open(f'candidate_manue_{count}.html', 'w', encoding='utf-8') as out:
                out.write(content)
            count += 1
        except Exception:
            pass

# Also look for any large HTML blocks if they exist plainly
plain_matches = re.findall(r'<!DOCTYPE html>.*?(?=</html>)</html>', text2, re.DOTALL)
for i, m in enumerate(plain_matches):
    with open(f'candidate_plain_{i}.html', 'w', encoding='utf-8') as out:
        out.write(m)

print(f'Done extracting {count} candidates.')
