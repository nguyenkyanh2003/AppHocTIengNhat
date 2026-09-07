# Quy ước code (khuôn mẫu)

Trạng thái: **đã được áp dụng thật** ở cả hai đầu trong lát cắt `vocabulary` (Giai đoạn 1).
Bản mẫu để sao chép: `BackEnd/src/shared/http/`, `BackEnd/src/modules/vocabulary/`,
`BackEnd/src/modules/srs/srs-scheduling.js`, `FrontEnd/lib/core/state/view_state.dart`,
`FrontEnd/lib/shared/widgets/` và `FrontEnd/lib/features/vocabulary/`.

Tài liệu liên quan: [redesign-roadmap.md](redesign-roadmap.md),
[project-structure.md](project-structure.md).

## BackEnd

### Bốn tầng

```text
routes  ->  controller  ->  service  ->  repository  ->  model
```

| Tầng | Được phép | Không được phép |
| --- | --- | --- |
| `*.routes.js` | khai báo path, middleware, binding controller | logic, truy vấn DB |
| `*.controller.js` | đọc `req.valid`, gọi service, chọn status code | rule nghiệp vụ, truy vấn Mongoose, `try/catch` thủ công |
| `*.service.js` | rule nghiệp vụ, orchestration, ném `ApiError` | chạm `req`/`res`, chạm Mongoose trực tiếp |
| `*.repository.js` | mọi truy vấn Mongoose của domain | rule nghiệp vụ |

Controller mục tiêu < 150 dòng. Nếu vượt, phần thừa gần như luôn là logic phải nằm ở service.

Service nhận repository qua tham số (dependency injection) để test truyền repository giả:

```js
export const createVocabularyService = ({ vocabularyRepository, srsRepository }) => ({ ... });
```

### Validation

Mọi endpoint khai báo schema `zod` trong `<domain>.schema.js` và gắn middleware
`validate({ query, params, body })`. Controller chỉ đọc `req.valid`, không đọc `req.query`
hay `req.body` thô.

Phân trang dùng chung một schema: `page >= 1` (mặc định 1), `limit` mặc định 20, tối đa 100.

### Lỗi

Không `try/catch` trong controller. Bọc handler bằng `asyncHandler`, ném `ApiError` từ
service, để `error.middleware.js` dịch sang HTTP:

```js
router.get('/:id', authenticateUser, validate({ params: idParams }), asyncHandler(controller.getById));

// service
if (!vocabulary) throw ApiError.notFound('Không tìm thấy từ vựng.');
```

`error.middleware.js` xử lý: `ApiError`, `mongoose.Error.ValidationError` (400),
`CastError` (400), duplicate key `11000` (409), còn lại 500. Production không lộ stack.

### Response contract

```jsonc
// một tài nguyên
{ "data": { ... } }

// danh sách có phân trang
{ "data": [ ... ], "page": 1, "limit": 20, "total": 137, "totalPages": 7 }
```

Dùng `ok(res, data)` và `paginated(res, { items, page, limit, total })` trong
`src/shared/http/respond.js`. Danh sách rỗng là `200` với mảng rỗng — **không bao giờ 404**.
404 chỉ dành cho tài nguyên được định danh cụ thể mà không tồn tại.

Khi thay đổi route công khai, cập nhật `expectedCount` và `expectedSignatureHash` trong
`tests/route-contract.test.js` trong cùng commit.

### Test bắt buộc cho mỗi module

1. `tests/<domain>.service.test.js` — rule nghiệp vụ với repository giả.
2. `tests/<domain>.routes.test.js` — supertest với service stub: status code + hình dạng response.
3. Bổ sung case vào `tests/route-contract.test.js` nếu route thay đổi.

## FrontEnd

### Cấu trúc feature

```text
features/<feature>/
├── screens/     # bố cục + điều hướng, mục tiêu < 250 dòng, giới hạn cứng 300
├── widgets/     # thành phần trình bày của feature, không gọi service
├── providers/   # state, giữ ViewState, gọi service
├── services/    # gọi ApiClient, map JSON -> model
└── models/
```

Screen không gọi service trực tiếp và không chứa rule nghiệp vụ. Khi một screen vượt 300
dòng, tách phần trình bày sang `widgets/` trước khi thêm tính năng mới.

### State

Provider dùng `ViewState<T>` (`idle | loading | data | failure`) trong
`core/state/view_state.dart` thay cho bộ ba `_isLoading` / `_error` / `_data`. Việc bắt lỗi
nằm trong `ViewState.guard`, nên provider không tự `try/catch` và màn hình không bao giờ
nhận chuỗi `Exception: ...` thô:

```dart
Future<void> load() async {
  _list = const ViewState.loading();
  notifyListeners();
  _list = await ViewState.guard(() => _service.getVocabularies(page: 1));
  notifyListeners();
}
```

Provider nhận service qua constructor (`VocabularyProvider({VocabularyService? service})`)
để test truyền service giả. `ChangeNotifierProvider` của package `provider` vốn đã lazy —
chỉ truyền `lazy: false` khi thật sự cần khởi tạo sớm.

### Trạng thái màn hình

Không tự viết `if (isLoading) ... else if (error != null) ...` trong screen. Dùng
`shared/widgets/async_view.dart`, nơi định nghĩa một lần cách hiển thị loading, lỗi (kèm
nút thử lại) và trạng thái rỗng.

### Giao diện

Màu, spacing, radius, typography lấy từ `app/theme/app_tokens.dart` và
`app_typography.dart`. Không hardcode `Color(0x...)`, `EdgeInsets.all(17)` hay `TextStyle`
rời rạc trong screen. Spacing chỉ dùng các bậc 4/8/12/16/24/32.

### Network

`core/network/api_client.dart` giữ HTTP, token và map lỗi. Offline cache nằm ở
`core/network/offline_cache.dart`; call site tự khai báo có cache hay không thay vì
hardcode danh sách endpoint trong client. Service của feature dựng query bằng
`Uri.queryParameters`, không nối chuỗi tay.

Service của feature trả về **kiểu dữ liệu**, không trả `Map<String, dynamic>` cho provider
tự đoán khoá — xem `VocabularyPage` trong
`features/vocabulary/services/vocabulary_service.dart`.

### Test bắt buộc cho mỗi feature

1. `test/<feature>_provider_test.dart` — chuyển trạng thái với service giả: tải thành công,
   tải thêm trang, lỗi API, lỗi lạ, danh sách rỗng.
2. Cập nhật `test/navigation_contract_test.dart` khi route công khai thay đổi.

## Quality gate

Chạy trước mỗi commit và trong CI (`.github/workflows/ci.yml`):

```powershell
cd BackEnd;  npm test
cd FrontEnd; dart analyze; flutter test
```

`dart analyze` phải sạch hoàn toàn: 0 error, 0 warning, 0 info.
