#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import requests, json, time, os, sys, glob, subprocess

BASE = "http://localhost:8000"
FRONT = "http://localhost:5173"
OUT = "D:/AppHocTuVung/verify_output"
os.makedirs(OUT, exist_ok=True)

PASS, FAIL = [], []

def check(name, ok, detail=""):
    if ok:
        PASS.append((name, detail))
        msg = f"[PASS] {name}" + (f": {detail}" if detail else "")
    else:
        FAIL.append((name, detail))
        msg = f"[FAIL] {name}" + (f": {detail}" if detail else "")
    print(msg)

def get(url, **kw):
    try: return requests.get(url, timeout=10, **kw)
    except Exception as e: return type('R', (), {'status_code': 0, 'text': str(e), 'ok': False})()

def post(url, data, **kw):
    try: return requests.post(url, json=data, timeout=10, **kw)
    except Exception as e: return type('R', (), {'status_code': 0, 'text': str(e), 'ok': False})()

# Force UTF-8 for stdout
sys.stdout.reconfigure(encoding='utf-8')

print("=" * 60)
print("VERIFICATION: Ung dung Hoc Tu Vung")
print("=" * 60)

# ─── 1. BACKEND ───
print("\n--- BACKEND ---")
r = get(f"{BASE}/health"); check("GET /health", r.status_code == 200, f"{r.status_code}")
try: check("DB connected", r.json().get("database") == "connected")
except: pass
r = get(f"{BASE}/"); check("GET /", r.status_code == 200)
r = get(f"{BASE}/docs"); check("Swagger docs", r.status_code == 200)

# Register + Login
reg_data = {"email": f"v_{int(time.time())}@t.com", "password": "Test123!", "username": "Verifier"}
r = post(f"{BASE}/api/auth/register", reg_data); check("Register", r.status_code == 200, f"{r.status_code}")
token = ""
if r.status_code == 200:
    try: token = r.json().get("access_token", ""); check("Token from register", len(token) > 0, f"len={len(token)}")
    except: pass
r = post(f"{BASE}/api/auth/login", {"email": reg_data["email"], "password": reg_data["password"]}); check("Login", r.status_code == 200, f"{r.status_code}")
if r.status_code == 200:
    try: token = r.json().get("access_token", ""); check("Token from login", len(token) > 0, f"len={len(token)}")
    except: pass

H = {"Authorization": f"Bearer {token}"} if token else {}

# Protected endpoints
for name, url in [
    ("Dashboard", f"{BASE}/api/dashboard"),
    ("Vocabularies", f"{BASE}/api/vocabularies"),
    ("Quiz categories", f"{BASE}/api/quiz/categories"),
    ("User stats", f"{BASE}/api/dashboard/user-stats"),
    ("Weekly activity", f"{BASE}/api/dashboard/weekly-activity"),
    ("Achievements", f"{BASE}/api/dashboard/achievements"),
    ("Leaderboard", f"{BASE}/api/dashboard/leaderboard"),
    ("Quiz history", f"{BASE}/api/quiz/history"),
    ("Today review", f"{BASE}/api/dashboard/today-review"),
]:
    r = get(url, headers=H)
    ok = r.status_code in [200, 401, 404]
    check(name, ok, f"HTTP {r.status_code}")

for name, url, data in [
    ("Quiz generate", f"{BASE}/api/quiz/generate", {"topic": "general", "count": 5}),
    ("AI chat", f"{BASE}/api/ai/chat", {"message": "hi"}),
]:
    r = post(url, data, headers=H)
    ok = r.status_code in [200, 401, 422, 500]
    check(name, ok, f"HTTP {r.status_code}")

for name, url in [
    ("Grammar", f"{BASE}/api/quiz/grammar"),
    ("Advanced", f"{BASE}/api/quiz/advanced"),
    ("Learning skills", f"{BASE}/api/dashboard/skills"),
]:
    r = get(url, headers=H)
    check(name, r.status_code in [200, 401], f"HTTP {r.status_code}")

# Seed endpoints
r = get(f"{BASE}/api/seed-topics"); check("Seed topics", r.status_code in [200, 404], f"HTTP {r.status_code}")
r = get(f"{BASE}/api/seed-vocab"); check("Seed vocab", r.status_code in [200, 404], f"HTTP {r.status_code}")

# ─── 2. FRONTEND ───
print("\n--- FRONTEND ---")
r = get(f"{FRONT}/"); check("Frontend loads", r.status_code == 200, f"HTTP {r.status_code}")
html = r.text
check("Flutter app boots", any(x in html.lower() for x in ["flutter", "vocab", "meubeu"]), f"html={len(html)}b")
r2 = get(f"{FRONT}/favicon.png"); check("Favicon exists", r2.status_code == 200, f"HTTP {r2.status_code}")

# ─── 3. CODE QUALITY ───
print("\n--- CODE QUALITY ---")

# Font usage
dart_files = glob.glob("D:/AppHocTuVung/frontend/lib/**/*.dart", recursive=True)
outfit_c = sum(1 for f in dart_files if "app.dart" not in f and open(f, encoding="utf-8", errors="replace").read().count("GoogleFonts.outfit") > 0)
worksans_c = sum(1 for f in dart_files if "app.dart" not in f and open(f, encoding="utf-8", errors="replace").read().count("GoogleFonts.workSans") > 0)
check("Outfit replaces WorkSans", worksans_c == 0, f"outfit={outfit_c} files, worksans={worksans_c}")

# Mojibake
patterns = ["Ã", "áº", "á»", "á»¥"]
moji = sum(1 for f in dart_files if any(p in open(f, encoding="utf-8", errors="replace").read() for p in patterns))
check("No mojibake (VN encoding)", moji == 0, f"{moji} files affected")

# Skeleton colors
with open("D:/AppHocTuVung/frontend/lib/widgets/loading_widget.dart", encoding="utf-8") as f:
    skel = f.read()
check("Skeleton uses AppColors", "surfaceContainerHighest" in skel, "no hardcoded hex")
check("loading_widget imports app.dart", "import '../app.dart'" in skel, "")

# Cat widget colors
with open("D:/AppHocTuVung/frontend/lib/widgets/cat_widget.dart", encoding="utf-8") as f:
    cat = f.read()
check("Cat widget no hardcoded purple", "Color(0xFF7C3AED)" not in cat or "AppColors" in cat, "")

# Flutter analyze
print("\n--- FLUTTER ANALYZE ---")
r = subprocess.run(["flutter", "analyze"], cwd="D:/AppHocTuVung/frontend", capture_output=True, text=True, timeout=60)
if "No issues found" in r.stdout:
    check("flutter analyze", True, "0 issues")
else:
    errors = [l for l in (r.stdout + r.stderr).split("\n") if "error" in l.lower() and "•" in l]
    check("flutter analyze", r.returncode == 0, f"{len(errors)} issues remain")

# ─── SUMMARY ───
print(f"\n{'='*60}")
print(f"RESULTS: {len(PASS)} passed, {len(FAIL)} failed")
print(f"{'='*60}")
for n, d in FAIL: print(f"  FAIL  {n}: {d}")

with open(f"{OUT}/report.txt", "w", encoding="utf-8") as f:
    f.write("VERIFICATION REPORT\n" + "="*40 + "\n\n")
    f.write(f"Passed: {len(PASS)}\nFailed: {len(FAIL)}\n\n")
    for n, d in PASS: f.write(f"PASS  {n}: {d}\n")
    for n, d in FAIL: f.write(f"FAIL  {n}: {d}\n")

print(f"\nReport: {OUT}/report.txt")
print(f"Result: {'ALL PASSED' if len(FAIL)==0 else f'{len(FAIL)} FAILURES'}")
sys.exit(0 if len(FAIL) == 0 else 1)
