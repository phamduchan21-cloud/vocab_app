"""Fix double-UTF8 encoded Vietnamese text in all Dart files."""
import os, glob

def fix_file(path):
    with open(path, 'rb') as f:
        raw = f.read()

    # Decode as UTF-8 (this reads the current content)
    text = raw.decode('utf-8')

    # Try to fix: the bytes are double-encoded UTF-8
    # Strategy: if the string contains known mojibake patterns, fix them directly
    fixes = {
        'ChÃ\xa0o buá»\x95i sÃ¡ng': 'Chào buổi sáng',
        'ChÃ\xa0o buá»\x95i trÆ°a': 'Chào buổi trưa',
        'ChÃ\xa0o buá»\x95i chiá»\x81u': 'Chào buổi chiều',
        'ChÃ\xa0o buá»\x95i tá»\x91i': 'Chào buổi tối',
        'ChÃ\xa0o má»«ng': 'Chào mừng',
        'Báº¡n': 'Bạn',
        'Trang chá»§': 'Trang chủ',
        'Há»\x93 sÆ¡': 'Hồ sơ',
        'Cáº¤P': 'CẤP',
        'Sá»\x94 TAY Tá»ª Vá»°NG': 'SỔ TAY TỪ VỰNG',
        'Ä\x90Ä\x83ng nháº­p': 'Đăng nhập',
        'Ä\x90Ä\x83ng kÃ½': 'Đăng ký',
        'Ä\x90Ã£': 'Đã',
        'Ä\x90ang': 'Đang',
        'Ä\x83ng': 'ăng',
        'á»\x9f': 'ợ',
        'á»\x8b': 'ị',
        'á»\x91i': 'ối',
        'áº¡': 'ạ',
        'áº¥': 'ấ',
        'áº­': 'ậ',
        'á»¥': 'ụ',
        'á»©': 'ức',
        'á»§': 'ủ',
    }

    for old, new in fixes.items():
        if old in text:
            text = text.replace(old, new)
            print(f'  Fixed: {repr(old[:30])} -> {repr(new[:30])}')

    with open(path, 'wb') as f:
        f.write(text.encode('utf-8'))

# Fix screens and widgets
for pattern in ['frontend/lib/screens/*.dart', 'frontend/lib/widgets/*.dart']:
    for path in glob.glob(pattern):
        print(f'Processing: {path}')
        fix_file(path)

print('Done!')
