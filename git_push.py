import subprocess, os

os.chdir(r"D:\AppHocTuVung")
cmds = [
    ["git", "add", "-A"],
    ["git", "commit", "-m", "Fix: AI quiz and expand MINI TEST data"],
    ["git", "push", "origin", "master"],
]
for cmd in cmds:
    r = subprocess.run(cmd, capture_output=True, text=True)
    print(" ".join(cmd))
    if r.returncode == 0:
        print(r.stdout[:300])
    else:
        print("STDERR:", r.stderr[:300])
        break
print("Done!")
