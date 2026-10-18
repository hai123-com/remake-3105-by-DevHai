# DEVHAI PREMIUM — BẢN FULL SOURCE CẬP NHẬT

Đây là **toàn bộ dự án Xcode** (không phải ZIP chỉ gồm 2 file). Các thay đổi được ghép trên bản DEVHAI_PREMIUM_IOS_SOURCE_FIXED và vẫn giữ code 3105 gốc.

## Thay đổi

1. Giữ sửa lỗi biên dịch `catch { self.error = error.localizedDescription }` ở `DevHaiShell.swift`.
2. Không hiển thị gợi ý `USER123` / `ADMINDEMO` bên dưới ô nhập key. Hai key vẫn tồn tại **chỉ trong chế độ DEMO local**.
3. Nút **ADMIN PANEL** xuất hiện trên Home khi `store.isAdmin`, và trong Profile.
4. Bổ sung mục **Admin** riêng khi có vai trò ADMIN; không cấp quyền cho USER.
5. Các ô module admin dùng điều hướng `NavigationLink(destination:)` trực tiếp, hoạt động trong NavigationStack của Home, Profile hoặc tab Admin.
6. Chặn giao diện các module quản trị từ đầu đối với phiên không phải ADMIN DEMO. Các thao tác ghi dữ liệu vẫn phải kiểm tra `requireAdmin()` ở store.
7. Giữ `.github/workflows/build-ipa.yml`, mục tiêu Xcode và bản quyền GPL / ghi công gốc.

## Kiểm tra và giới hạn

- Cần build **lại** bằng GitHub Actions. IPA cũ không tự cập nhật khi bạn thay nguồn.
- `unsigned` không dùng để cài lên iPhone nếu chưa ký hợp lệ.
- Quản lý key, người dùng và tin nhắn demo **chỉ có hiệu lực trên máy cục bộ**, không đồng bộ toàn hệ thống. Không phân phối rộng hai key demo dưới dạng mật khẩu bảo vệ admin thực sự. Cần một backend HTTPS có xác thực và phân quyền tại máy chủ để triển khai production.
- Một số khả năng của 3105 có thể không hoạt động nếu iOS / thiết bị / entitlement không hỗ trợ.
- Không tuyên bố đã build Xcode hoặc chạy được trên iPhone khi chưa có bằng chứng test.

## Upload lên GitHub qua CMD

Giải nén nội dung ZIP vào clone đã có Git (`devhai-fixed`):

```cmd
cd /d "%USERPROFILE%\Downloads\devhai-fixed"
tar -xf "%USERPROFILE%\Downloads\DEVHAI_PREMIUM_FULL_LATEST.zip"
git status
git add -A
git commit -m "Update full DEVHAI PREMIUM source and Admin Panel"
git push origin main
```

ZIP này chứa `.github/`, `ThreeOneOSFive/`, `ThreeOneOSFive.xcodeproj/` trực tiếp ở gốc, không có một thư mục bao ngoài.
