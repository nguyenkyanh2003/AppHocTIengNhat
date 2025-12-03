# Hướng dẫn test fix vấn đề dữ liệu bị trùng giữa các tài khoản

## Các thay đổi đã thực hiện:

### 1. Backend
- ✅ Thêm log debug vào `/profile/:id` để track requests
- ✅ Đảm bảo API trả về đúng user theo userId

### 2. Frontend - Core
- ✅ Thêm `clearAllData()` vào ApiClient để xóa toàn bộ cache
- ✅ Sửa `saveUserToLocal()` lưu theo `user_data_${userId}` thay vì chung 1 key
- ✅ Sửa `getUserFromLocal()` đọc theo `current_user_id`
- ✅ Sửa `logout()` xóa tất cả dữ liệu cached

### 3. Frontend - Providers
- ✅ Thêm method `clear()` vào tất cả 11 providers để reset state
- ✅ Tạo `ProviderResetService` để reset tất cả providers 1 lần
- ✅ Cập nhật `AuthProvider.init()` để load đúng user và có log debug
- ✅ Thêm `resetState()` vào AuthProvider

### 4. Frontend - Screens
- ✅ `LoginScreen`: Reset tất cả providers trước khi login
- ✅ `LoginScreen`: Dùng `pushAndRemoveUntil` để clear navigation stack
- ✅ `ProfileScreen`: Reset tất cả providers trước khi logout
- ✅ `ProfileScreen`: Dùng `pushNamedAndRemoveUntil` để clear navigation stack

## Cách test:

### Test 1: Đăng nhập liên tiếp 2 tài khoản khác nhau
1. **Hot restart app** (quan trọng!) hoặc **flutter run -d chrome**
2. Đăng nhập tài khoản `aaaa` (hoặc bất kỳ tài khoản nào)
3. **Kiểm tra màn hình Home:**
   - Tên user trên header
   - **Số XP (ví dụ: 49 XP)**
   - **Số ngày streak (ví dụ: 2 ngày)**
4. Mở menu → Đăng xuất
5. Đăng nhập tài khoản khác (ví dụ: `testuser` hoặc `Nguyen Thi B`)
6. **Kiểm tra màn hình Home:**
   - Tên user KHÁC
   - **Số XP KHÁC** (có thể là 0 XP nếu tài khoản mới)
   - **Số ngày streak KHÁC** (có thể là 0 ngày)
7. **PHẢI KHÁC HOÀN TOÀN** với tài khoản trước đó!

### Test 2: Tạo tài khoản mới và đăng nhập
1. Tạo tài khoản mới (ví dụ: `newuser`)
2. Đăng nhập với tài khoản mới
3. Kiểm tra dữ liệu - **PHẢI LÀ DỮ LIỆU MỚI, RỖNG**
4. Đăng xuất
5. Đăng nhập lại tài khoản `aaaa` hoặc `testuser`
6. Kiểm tra dữ liệu - **PHẢI TRỞ VỀ DỮ LIỆU CŨ**

### Test 3: Kiểm tra logs
**Backend logs** (trong terminal node):
```
📋 Profile request - Requester: 67abc123... (aaaa), Target: 67abc123..., Role: user
✅ Profile loaded: aaaa (67abc123...)
🔥 Streak request - User: aaaa (67abc123...)
✅ Streak found - User: aaaa, XP: 49, Streak: 2 days, Level: 1
```

**Frontend logs** (trong terminal dart):
```
✅ User loaded: aaaa (67abc123...)
🔄 User changed! Loading streak for user: 67abc123...
📊 Loading streak for user: aaaa (67abc123...)
🔥 Loading streak data from API...
✅ Streak loaded - XP: 49, Streak: 2 days, Level: 1
```

**Mỗi lần đăng nhập phải thấy:**
- userId KHÁC NHAU
- XP số KHÁC NHAU
- Streak days KHÁC NHAU

## Checklist kiểm tra:

- [ ] Backend log hiển thị đúng requester và target userId
- [ ] Backend log hiển thị đúng XP và streak cho từng user
- [ ] Frontend log hiển thị đúng username và userId sau login
- [ ] Frontend log hiển thị "User changed!" khi đăng nhập tài khoản khác
- [ ] Đăng nhập tài khoản A thấy: tên A, XP của A, streak của A
- [ ] Đăng xuất và đăng nhập tài khoản B thấy: tên B, XP của B, streak của B (KHÁC A)
- [ ] Đăng xuất B và đăng nhập lại A thấy: tên A, XP của A, streak của A (giống lần đầu)
- [ ] Tạo tài khoản mới có: XP = 0, streak = 0 days, level = 1
- [ ] Không có shared data giữa các tài khoản (đặc biệt là XP và streak)

## Nếu vẫn bị lỗi:

1. **Xóa app và cài đặt lại** (để clear SharedPreferences cũ)
2. Kiểm tra backend logs xem có request nào sai userId không
3. Kiểm tra frontend logs xem `getUserFromLocal()` có trả về đúng user không
4. Clear cache trong SharedPreferences:
   ```dart
   final prefs = await SharedPreferences.getInstance();
   await prefs.clear(); // XÓA TẤT CẢ
   ```

## Debug commands:

### Backend (node terminal):
```bash
cd BackEnd
npm start
# Xem logs khi có request tới /profile/:id
```

### Frontend (dart terminal):
```bash
cd FrontEnd
flutter clean
flutter pub get
flutter run
# Xem logs khi login/logout
```
