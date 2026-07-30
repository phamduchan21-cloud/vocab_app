# CI/CD cho SolVocab

## Tổng quan

Dự án có hai workflow:

- `CI`: tự chạy khi mở pull request hoặc push lên `main`/`codex/**`.
- `Deploy frontend to Vercel`: chạy thủ công, hỗ trợ `preview` và `production`.

## Kiểm tra tự động

Backend:

```bash
cd backend
python -m pip install -r requirements-dev.txt
python -m pytest
```

Frontend:

```bash
cd frontend
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter build web --release
```

## Cấu hình GitHub

Tạo hai GitHub Environments:

- `preview`
- `production`

Nên bật required reviewers cho environment `production` để deployment chỉ chạy sau khi được phê duyệt.

Thêm các secret vào cả hai environment:

| Tên | Nội dung |
|-----|----------|
| `VERCEL_TOKEN` | Token dùng riêng cho CI từ Vercel |
| `VERCEL_ORG_ID` | ID team/tài khoản Vercel |
| `VERCEL_PROJECT_ID` | ID project frontend trên Vercel |

Thêm environment variable:

| Tên | Nội dung |
|-----|----------|
| `API_BASE_URL` | URL HTTPS của FastAPI theo từng môi trường |

Không commit các giá trị này vào repository.

## Phát hành

1. Mở tab **Actions** trên GitHub.
2. Chọn **Deploy frontend to Vercel**.
3. Chọn **Run workflow**.
4. Chọn `preview` để kiểm tra trước.
5. Sau khi smoke test đạt, chạy lại với `production`.
6. GitHub sẽ yêu cầu phê duyệt nếu environment production đã bật required reviewers.

Workflow pin Vercel CLI ở phiên bản `56.5.0`, build Flutter trước, tạo Vercel artifact rồi mới deploy bằng `--prebuilt`.

## Health check backend

| Endpoint | Vai trò | Kết quả |
|----------|---------|---------|
| `/health/live` | Kiểm tra tiến trình FastAPI còn hoạt động | `200` nếu ứng dụng đang chạy |
| `/health` | Kiểm tra FastAPI và kết nối database | `200` khi sẵn sàng, `503` khi database lỗi |
| `/health/ai` | Kiểm tra cấu hình và circuit AI | `200` khi có provider sẵn sàng, `503` khi tất cả circuit đang mở |

Mỗi response có header `X-Request-ID`. Có thể dùng ID này để đối chiếu với log JSON của backend khi điều tra lỗi.

Workflow `Production smoke monitoring` chạy mỗi 30 phút. Có thể đặt repository
variables `PRODUCTION_WEB_URL` và `PRODUCTION_API_URL`; nếu bỏ trống workflow dùng
domain production hiện tại. Runbook chi tiết nằm tại `docs/AI_OPERATIONS.md`.

## Rollback

Frontend:

```bash
vercel rollback
```

Backend:

1. Chọn deployment ổn định gần nhất trên Render.
2. Redeploy commit tương ứng.
3. Kiểm tra `/health/live` và `/health`.

Database:

1. Không rollback code trước khi xác nhận schema tương thích.
2. Dùng downgrade của Alembic khi migration đã cung cấp đường lùi an toàn.
3. Luôn sao lưu trước migration phá hủy dữ liệu.
