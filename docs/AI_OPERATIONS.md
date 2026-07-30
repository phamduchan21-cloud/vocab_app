# Vận hành và giám sát AI Sol

## Mục tiêu

Luồng AI phải tiếp tục hoạt động khi một nhà cung cấp hết credit, timeout hoặc trả
về dữ liệu sai định dạng. Không log prompt, nội dung hội thoại, token hay API key.

## Thứ tự provider

Backend thử provider theo thứ tự:

1. xAI Grok khi có `XAI_API_KEY`.
2. Gemini khi có `GEMINI_API_KEY`.
3. OpenAI khi có `OPENAI_API_KEY`.

Mỗi kết quả phải qua Pydantic validation. Khi một provider lỗi, request được chuyển
sang provider kế tiếp. Sau số lần lỗi liên tiếp quy định, circuit của provider tạm
mở để các request mới không tiếp tục chờ provider đang lỗi.

## Biến môi trường

| Biến | Mặc định | Vai trò |
|------|----------|---------|
| `XAI_API_KEY` | trống | Key xAI Grok |
| `XAI_MODEL` | `grok-4.3` | Model Grok |
| `GEMINI_API_KEY` | trống | Key Gemini fallback |
| `OPENAI_API_KEY` | trống | Key OpenAI fallback |
| `OPENAI_MODEL` | `gpt-4o-mini` | Model OpenAI fallback |
| `AI_PROVIDER_TIMEOUT_SECONDS` | `12` | Timeout cho một provider |
| `AI_REQUEST_TIMEOUT_SECONDS` | `28` | Ngân sách tối đa cho toàn bộ chuỗi fallback |
| `AI_CIRCUIT_FAILURE_THRESHOLD` | `3` | Số lỗi liên tiếp trước khi mở circuit |
| `AI_CIRCUIT_RECOVERY_SECONDS` | `60` | Thời gian chờ trước khi thử lại provider |

Không commit giá trị thật vào Git. Render phải có ít nhất hai provider để fallback
có ý nghĩa.

## Health check

| Endpoint | Xác thực | Ý nghĩa |
|----------|----------|---------|
| `/health/live` | Không | Tiến trình FastAPI đang chạy |
| `/health` | Không | FastAPI kết nối được database |
| `/health/ai` | Không | Có provider cấu hình và còn circuit sẵn sàng |
| `/api/ai/status` | Có | Calls, success, failure, latency và lỗi gần nhất theo provider |

`/health/ai` không gọi model nên không phát sinh chi phí. Endpoint này phản ánh cấu
hình và circuit state, không thay thế kiểm thử hội thoại thực tế.

## Log và điều tra lỗi

Mỗi response có `X-Request-ID`. Flutter gửi ID từ đầu request và hiển thị thông báo
an toàn cho người dùng. Log AI có các field:

- `request_id`
- `operation`
- `provider`
- `outcome`
- `error_code`
- `duration_ms`
- `attempt`
- `fallback`
- `circuit_state`

Quy trình điều tra:

1. Lấy `X-Request-ID` từ response hoặc log frontend.
2. Tìm cùng ID trong log Render.
3. Kiểm tra `error_code` và `provider`.
4. Nếu `quota_exhausted`, kiểm tra credit nhà cung cấp.
5. Nếu `provider_timeout`, kiểm tra latency và trạng thái upstream.
6. Nếu `invalid_response`, kiểm tra model/prompt nhưng không đưa prompt vào log.

## Monitoring production

Workflow `Production smoke monitoring` chạy mỗi 30 phút và kiểm tra:

- Frontend Vercel trả response thành công.
- Backend liveness hoạt động.
- Database readiness hoạt động.
- Có ít nhất một AI provider được cấu hình và circuit đang sẵn sàng.

Có thể cấu hình repository variables:

- `PRODUCTION_WEB_URL`
- `PRODUCTION_API_URL`

Nếu không cấu hình, workflow dùng domain production hiện tại của SolVocab.

## Kiểm thử

```bash
cd backend
python -m pytest

cd ../frontend
flutter analyze --fatal-infos
flutter test
```

Test AI sử dụng fake provider, không cần key thật, không gọi mạng và không tiêu
credit. CI từ chối khi backend coverage thấp hơn 50%.
