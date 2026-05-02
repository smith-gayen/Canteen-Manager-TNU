import os

history_dir = os.path.expandvars(r'%APPDATA%\Code\User\History')
if not os.path.exists(history_dir):
    print('No VSCode history found')
else:
    for root, dirs, files in os.walk(history_dir):
        for file in files:
            path = os.path.join(root, file)
            try:
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                if '<title>KMS - Menu Planner</title>' in content or 'Menu Management</h1>' in content:
                    print(f'Found candidate in {path}')
            except Exception:
                pass
