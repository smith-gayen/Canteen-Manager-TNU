import json
import os

with open('main_extracted_1.html', 'r', encoding='utf-8') as f:
    text = f.read()

# The text might be JSON encoded. Let's decode it.
if text.startswith('"') and text.endswith('"'):
    content = json.loads(text)
else:
    # Try decoding unicode escapes
    content = text.encode('utf-8').decode('unicode_escape')
    if content.startswith('"') and content.endswith('"'):
        content = content[1:-1]

os.makedirs('web', exist_ok=True)
with open('web/main.html', 'w', encoding='utf-8') as f:
    f.write(content.replace('\\n', '\n').replace('\\"', '"'))
print('Decoded and saved web/main.html')
