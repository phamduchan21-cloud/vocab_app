"""Restore all screens and widgets from git HEAD with proper UTF-8 encoding."""
import subprocess
import os
import glob

BASE = "D:/AppHocTuVung"
FILES = (
    glob.glob(f"{BASE}/frontend/lib/screens/*.dart")
    + glob.glob(f"{BASE}/frontend/lib/widgets/*.dart")
)

for fpath in sorted(FILES):
    rel = os.path.relpath(fpath, BASE).replace("\\", "/")
    result = subprocess.run(
        ["git", "show", f"HEAD:{rel}"],
        capture_output=True,
        cwd=BASE,
    )
    if result.returncode != 0:
        print(f"FAIL: {rel}")
        continue
    with open(fpath, "wb") as f:
        f.write(result.stdout)
    print(f"OK: {os.path.basename(fpath)} ({len(result.stdout)} bytes)")

print("\nAll restored!")
