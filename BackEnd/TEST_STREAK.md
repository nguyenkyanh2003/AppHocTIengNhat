## TEST STREAK SYSTEM

### Bước 1: Kiểm tra streak hiện tại
```bash
curl -X GET http://localhost:3000/api/streak/my-streak \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Bước 2: Test login (auto update streak)
```bash
curl -X POST http://localhost:3000/api/user/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "your_username",
    "password": "your_password"
  }'
```

Response sẽ có:
```json
{
  "message": "Đăng nhập thành công",
  "token": "...",
  "streak": {
    "current": 2,        // Streak hiện tại
    "longest": 2,        // Streak dài nhất
    "total_xp": 20,      // Tổng XP
    "is_new_day": true,  // Có phải ngày mới không
    "streak_broken": false
  }
}
```

### Bước 3: Test học từ vựng (cập nhật streak + XP)
```bash
curl -X POST http://localhost:3000/api/vocabulary/VOCAB_ID/learn \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"
```

### Bước 4: Kiểm tra log backend
Sau mỗi lần login hoặc học, backend sẽ log:
```
🕒 Streak check - VN Time: 2/12/2025, 9:23:00 CH, Today: 2025-12-02
📅 Last activity: 2025-12-01, Days diff: 1
✅ Daily login streak updated for user 6925...: 2 days (+10 XP)
```

### Debug:
Nếu streak vẫn = 1:
1. Kiểm tra `last_activity_date` trong database
2. Kiểm tra timezone có đúng không
3. Kiểm tra `daysDiff` có = 1 không

### MongoDB Query để kiểm tra:
```javascript
db.userstreaks.findOne({ user: ObjectId("YOUR_USER_ID") })
```

Kết quả nên có:
```json
{
  "current_streak": 2,
  "last_activity_date": "2025-12-02T00:00:00.000Z",
  "activity_dates": [
    "2025-12-01T00:00:00.000Z",
    "2025-12-02T00:00:00.000Z"
  ]
}
```
