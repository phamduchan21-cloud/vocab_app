#!/usr/bin/env python3
"""Verify toàn bộ Ứng dụng Học Từ Vựng — screenshots + API check."""

import json, os, sys, time, traceback
from playwright.sync_api import sync_playwright

BASE_URL = "http://localhost:5173"
API_URL = "http://localhost:8000"
OUTPUT_DIR = "D:/AppHocTuVung/verify_output"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def screenshot(page, name):
    path = os.path.join(OUTPUT_DIR, f"{name}.png")
    page.screenshot(path=path, full_page=True)
    print(f"  [SS] {name}.png")
    return path

def log(msg):
    print(f"  {msg}")

def check_api():
    """Test backend API endpoints."""
    results = []
    endpoints = [
        ("GET", f"{API_URL}/", "Root"),
        ("GET", f"{API_URL}/health", "Health"),
        ("GET", f"{API_URL}/api/vocabularies", "Vocabularies"),
        ("GET", f"{API_URL}/docs", "Swagger"),
    ]
    for method, url, name in endpoints:
        try:
            import requests
            r = requests.request(method, url, timeout=5)
            ok = r.status_code < 500
            results.append((name, "✅" if ok else "❌", r.status_code))
        except Exception as e:
            results.append((name, "❌", str(e)))
    return results

def run():
    api_results = check_api()
    print("\n=== API RESULTS ===")
    for name, status, detail in api_results:
        print(f"  {status} {name}: {detail}")

    print("\n=== FRONTEND VERIFICATION ===")
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True, args=["--no-sandbox"])
        context = browser.new_context(
            viewport={"width": 1280, "height": 800},
            device_scale_factor=2,
        )
        page = context.new_page()

        # 1. Splash screen
        print("\n1. SPLASH SCREEN")
        page.goto(f"{BASE_URL}/splash", wait_until="networkidle")
        time.sleep(1.5)
        screenshot(page, "01_splash")
        log(f"Title visible: {page.is_visible('text=Bắt đầu ngay')}")

        # 2. Click "Bắt đầu ngay" → Onboarding
        print("\n2. ONBOARDING")
        page.click("text=Bắt đầu ngay")
        time.sleep(1)
        screenshot(page, "02_onboarding_welcome")
        # Click through all 8 questions
        for q in range(8):
            time.sleep(0.5)
            # Pick first option
            first_option = page.locator("text=Tiếng Anh,text=Mới bắt đầu,text=Đi làm / CV,text=5 phút,text=Nhìn,text=Giao tiếp cơ bản,text=Sáng sớm,text=Có, 8:00").first
            if first_option.is_visible():
                first_option.click()
            page.click("text=Tiếp tục >> visible=true,text=Bắt đầu hành trình! >> visible=true")
            time.sleep(0.5)
        screenshot(page, "03_onboarding_complete")

        # 3. Should reach login
        print("\n3. LOGIN SCREEN")
        time.sleep(1)
        screenshot(page, "04_login")
        log(f"Login form visible: {page.is_visible('text=Đăng nhập')}")

        # 4. Click "Tôi đã có tài khoản" from splash
        page.goto(f"{BASE_URL}/splash", wait_until="networkidle")
        time.sleep(1)
        page.click("text=Tôi đã có tài khoản")
        time.sleep(1)
        screenshot(page, "05_login_splash")

        # 5. Register screen
        page.click("text=Đăng ký")
        time.sleep(1)
        screenshot(page, "06_register")

        # 6. Try login with test account
        page.goto(f"{BASE_URL}/login", wait_until="networkidle")
        time.sleep(0.5)
        page.fill("input[type=email]", "test@verify.com")
        page.fill("input[type=password]", "Test123!")
        page.click("button:has-text('Đăng nhập')")
        time.sleep(2)
        screenshot(page, "07_after_login")

        # 7. Dashboard
        print("\n7. DASHBOARD")
        page.goto(f"{BASE_URL}/", wait_until="networkidle")
        time.sleep(2)
        screenshot(page, "08_dashboard")
        log(f"Hero stats visible: {page.is_visible('text=Streak')}")

        # 8. Flashcard
        print("\n8. FLASHCARD")
        page.goto(f"{BASE_URL}/flashcard", wait_until="networkidle")
        time.sleep(2)
        screenshot(page, "09_flashcard")

        # 9. Quiz list
        print("\n9. QUIZ LIST")
        page.goto(f"{BASE_URL}/quiz", wait_until="networkidle")
        time.sleep(2)
        screenshot(page, "10_quiz_list")

        # 10. Mock test
        print("\n10. MOCK TEST")
        page.goto(f"{BASE_URL}/test", wait_until="networkidle")
        time.sleep(2)
        screenshot(page, "11_mock_test")

        # 11. Topic Browser
        print("\n11. TOPIC BROWSER")
        page.goto(f"{BASE_URL}/topics", wait_until="networkidle")
        time.sleep(1)
        screenshot(page, "12_topic_browser")

        # 12. AI Chat
        print("\n12. AI CHAT")
        page.goto(f"{BASE_URL}/ai-chat", wait_until="networkidle")
        time.sleep(2)
        screenshot(page, "13_ai_chat")

        # 13. Profile
        print("\n13. PROFILE")
        page.goto(f"{BASE_URL}/profile", wait_until="networkidle")
        time.sleep(2)
        screenshot(page, "14_profile")

        # 14. Bookmark
        print("\n14. BOOKMARK")
        page.goto(f"{BASE_URL}/bookmark", wait_until="networkidle")
        time.sleep(2)
        screenshot(page, "15_bookmark")

        # 15. Progress
        print("\n15. PROGRESS")
        page.goto(f"{BASE_URL}/progress", wait_until="networkidle")
        time.sleep(2)
        screenshot(page, "16_progress")

        # 16. Quiz History
        print("\n16. QUIZ HISTORY")
        page.goto(f"{BASE_URL}/quiz/history", wait_until="networkidle")
        time.sleep(2)
        screenshot(page, "17_quiz_history")

        # Check font rendering (Outfit)
        print("\n[FONT CHECK]")
        font_info = page.evaluate("""() => {
            const el = document.querySelector('body *');
            if (!el) return 'no element';
            const style = window.getComputedStyle(el);
            return `font-family: ${style.fontFamily}`;
        }""")
        log(font_info)

        browser.close()

    print(f"\n=== DONE === Screenshots saved to {OUTPUT_DIR}")
    return api_results

if __name__ == "__main__":
    try:
        run()
    except Exception as e:
        print(f"ERROR: {e}")
        traceback.print_exc()
        sys.exit(1)
