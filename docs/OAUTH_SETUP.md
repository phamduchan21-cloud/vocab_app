# Cấu hình đăng nhập Google và Facebook

Phần Flutter dùng Supabase OAuth và nhận callback tại:

- Web local: `http://localhost:3000/` và `http://127.0.0.1:3000/`
- Android: `com.vocabapp.vocab_app://login-callback/`
- Callback từ Google/Meta về Supabase: `https://tblagqcnhciqtmyhikoh.supabase.co/auth/v1/callback`

## 1. Supabase redirect allow list

Mở **Supabase Dashboard > Authentication > URL Configuration** và thêm:

```text
http://localhost:3000/**
http://127.0.0.1:3000/**
com.vocabapp.vocab_app://login-callback/**
```

Khi deploy production, thêm URL theo dạng `https://ten-mien-cua-ban/**`.

## 2. Google

1. Trong Google Auth Platform, tạo OAuth Client loại **Web application**.
2. Thêm JavaScript origins: `http://localhost:3000`, `http://127.0.0.1:3000` và origin production.
3. Thêm Authorized redirect URI chính xác:

```text
https://tblagqcnhciqtmyhikoh.supabase.co/auth/v1/callback
```

4. Bật scopes `openid`, `userinfo.email`, `userinfo.profile`.
5. Mở **Supabase > Authentication > Providers > Google**, bật provider và nhập Client ID/Client Secret.

## 3. Facebook

1. Tạo app trong Meta for Developers và thêm sản phẩm **Facebook Login**.
2. Trong Facebook Login Settings, thêm Valid OAuth Redirect URI chính xác:

```text
https://tblagqcnhciqtmyhikoh.supabase.co/auth/v1/callback
```

3. Bật quyền `public_profile` và `email` trong use case Authentication.
4. Mở **Supabase > Authentication > Providers > Facebook**, bật provider và nhập App ID/App Secret.
5. Khi app Meta còn ở Development mode, chỉ admin/developer/tester của app đăng nhập được. Chuyển Live khi sẵn sàng cho người dùng thật.

## 4. Kiểm tra

1. Mở `/login`, chọn Google hoặc Facebook.
2. Sau khi đồng ý, trình duyệt phải quay về app và Supabase phải có session.
3. Tài khoản xã hội đăng nhập lần đầu được chuyển tới `/setup`; sau khi hoàn thành sẽ vào trang chủ.
