# DEVHAI PREMIUM — Hướng dẫn tiếng Việt

**DEVHAI PREMIUM** là bản **tùy biến mã nguồn của 3105 v2.0**, không phải ứng dụng được phát triển mới từ đầu. Nền tảng ban đầu do **YangJiii** cùng các tác giả/thành viên đóng góp xây dựng. Bản này thêm nhận diện DEVHAI, giao diện xanh đậm, màn hình nhập key demo, khu vực người dùng và **20 trang quản trị hoạt động trên dữ liệu demo của chính thiết bị**. Mã nguồn chức năng gốc được giữ lại trong `ThreeOneOSFive/`.

> **Trạng thái kiểm thử:** Tất cả tệp Swift mới đã được kiểm tra cú pháp bằng Swift parser, `project.pbxproj` và `Info.plist` đã qua kiểm tra định dạng trên Linux. **Chưa thể chạy `xcodebuild`, chưa xác nhận build trên iOS và chưa tạo IPA trong môi trường này**, do không có máy Mac/Xcode và tài khoản ký Apple trong môi trường thực hiện. GitHub Actions được cung cấp để biên dịch và chỉ upload IPA khi lệnh build thực sự thành công.

## 1. Hướng dẫn sử dụng

- Tên trên màn hình: `DEVHAI`, giao diện: dark navy + blue, app icon chữ D/DEVHAI riêng.
- Lần đầu chạy: đăng nhập key demo trước, sau đó hoàn thành onboarding gốc. Màn hình đăng nhập **không hiển thị các key demo bên dưới ô nhập**.
- **USER:** `USER123` — có các công cụ hỗ trợ tương thích và quyền truy cập phù hợp.
- **ADMIN:** `ADMINDEMO` — thêm `Home → ADMIN PANEL`, `Profile → ADMIN PANEL` hoặc tab `Admin` để vào 20 mục quản trị.
- **Files:** vẫn yêu cầu bật `Settings → Developer Mode` theo cơ chế hiển thị cũ. Việc hiển thị không cấp thêm đặc quyền hay vượt qua sandbox.
- **Các tab:** Home, Discover (repository, new, sources, search), Files, Tools (patch, wallpaper, cleaner, logs), Profile; tài khoản ADMIN có thêm tab Admin (trên iPhone có thể nằm trong More nếu thanh tab quá nhiều mục).
- Login session được lưu trong **iOS Keychain**, có ngày hết hạn và xác thực lại trạng thái license khi app hoạt động.

### 20 mục Admin Panel

| STT | Chức năng | Hoạt động ở demo |
|---:|---|---|
| 1 | Admin Dashboard | Thống kê người dùng, license, activation, recent activity |
| 2 | Create License | Tạo key theo role, số ngày, số thiết bị, random bảo mật |
| 3 | Key Manager | Tìm kiếm, xem trạng thái, sửa vai trò/ghi chú, copy key demo |
| 4 | Revoke License | Thu hồi và khôi phục license có xác nhận |
| 5 | Extend License | Gia hạn 1/7/30/90/365 ngày hoặc tùy chọn |
| 6 | Device Management | Xem ID ngắn gọn dạng app-scoped; reset activation |
| 7 | User Management | Tạo demo user, quản lý role và trạng thái disabled |
| 8 | Announcements | Đăng tin, bật/tắt công khai, xóa |
| 9 | Popup Announcements | Đăng popup bằng alert SwiftUI khi người dùng mở trang chính |
| 10 | Activity Logs | Lọc/tìm kiếm nhật ký và tải thêm từng trang |
| 11 | Analytics | Biểu đồ trạng thái license/sự kiện demo (Swift Charts) |
| 12 | App Settings | Lời chào, ngôn ngữ mặc định, ẩn/hiện thông báo |
| 13 | Maintenance Mode | Bật tắt màn bảo trì, thông báo, admin bypass |
| 14 | Feature Flags | Bật/tắt entry point (không nâng quyền hệ thống) |
| 15 | Release Information | Xem build, sửa ghi chú phiên bản và link HTTPS |
| 16 | Support Center | Tạo và cập nhật trạng thái/tin nhắn hỗ trợ |
| 17 | System Health | Thông số thiết bị/app có thực; mục không xác minh báo unavailable |
| 18 | Backup & Restore | Export/import cấu hình JSON đã lược bỏ key và dữ liệu nhạy cảm |
| 19 | Notification Center | Gửi thông báo trong app, lịch sử, đánh dấu đã đọc, xóa |
| 20 | Admin Security | Xem phiên hiện tại, logout/revoke local session, giới hạn login demo |

**Lưu ý:** Các module này dùng một file dữ liệu **demo local** và không đồng bộ giữa máy khác. Chúng **không phải quản trị sản phẩm production qua Internet**. Những khả năng server-side (đổi credential admin thật, revoke mọi phiên trên nhiều máy, quản lý key tập trung, push notification APNs, đồng bộ người dùng, audit có tính toàn vẹn, lịch phát hành) phải triển khai backend được xác thực, không thể chỉ dựa vào IPA.

## 2. Tạo IPA bằng GitHub Actions (không cần cài Xcode trên Windows)

1. Giải nén `DEVHAI_PREMIUM_IOS_SOURCE.zip` trên Windows.
2. Mở [github.com/new](https://github.com/new) và tạo repository mới, ví dụ `DEVHAI-PREMIUM-IOS`. Có thể đặt Private để giữ mã nguồn chưa công khai, nhưng khi phân phối bản GPL phải thực hiện nghĩa vụ cung cấp mã nguồn tương ứng.
3. Trong repository bấm **Add file → Upload files**, kéo **toàn bộ nội dung** bên trong thư mục `DEVHAI_PREMIUM_IOS_SOURCE/` vào (nhớ bật chế độ hiện file ẩn để có `.github/workflows/build-ipa.yml`). Đối với nhiều file/thư mục, cách chắc chắn hơn là sử dụng Git trong thư mục đã giải nén:

   ```bash
   git init
   git add .
   git commit -m "DEVHAI PREMIUM source"
   git branch -M main
   git remote add origin https://github.com/USERNAME/REPOSITORY.git
   git push -u origin main
   ```

4. Vào GitHub repo → **Actions** → workflow **DEVHAI PREMIUM • iOS IPA** → **Run workflow**.
5. Chọn **mode = unsigned** nếu chưa có chứng chỉ Apple. Bấm **Run workflow** để GitHub chạy trên macOS. Chờ dấu xanh thành công; nếu có lỗi, mở job để xem log Swift/compiler.
6. Sau khi thành công, mở lượt chạy → phần **Artifacts** → tải `DEVHAI-PREMIUM-unsigned-IPA` về. Trong ZIP artifact có IPA unsigned và BUILD-INFO.

**Quan trọng:** `unsigned.ipa` là gói IPA *chưa ký*, chỉ phục vụ kiểm tra/để ký hợp lệ sau đó; không thể cài bình thường lên iPhone. GitHub Actions không thể tự cấp chứng chỉ Apple. Thành công ở bước upload artifact không xác nhận các chức năng privileged hoạt động trên thiết bị.

## 3. IPA đã ký (chỉ dùng giấy chứng nhận thuộc quyền quản lý của bạn)

Trong GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**, cấu hình các secrets (không ghi chúng vào mã nguồn):

- `IOS_P12_BASE64`: tệp chứng chỉ Apple `.p12` được mã hóa base64.
- `IOS_P12_PASSWORD`: mật khẩu tệp `.p12`.
- `IOS_PROFILE_BASE64`: provisioning profile `.mobileprovision` được mã hóa base64.
- `IOS_TEAM_ID`: Apple Developer Team ID tương ứng profile.
- `IOS_BUNDLE_ID`: định danh ứng dụng do Apple Developer của bạn sở hữu (không phải `com.apple.*`).

Chọn workflow **signed** và `export_method = development` (thiết bị được provision) hoặc `ad-hoc` (danh sách thiết bị đã được provision). Workflow kiểm tra dữ liệu ký, thêm keychain tạm thời, archive, export qua Xcode và upload `DEVHAI-PREMIUM-signed-IPA` khi thành công.

**Giới hạn đặc biệt của 3105:** mã gốc cố ý sử dụng Bundle ID `com.apple.mobile.MobileHouseArrest` để phục vụ cơ chế MHA-C2 và các quyền riêng; đổi sang Bundle ID cá nhân để ký thông thường **có thể làm các tính năng đó không hoạt động**. Chứng chỉ Developer/Ad Hoc thông thường không cấp các entitlement riêng của Apple. Bản này không phá bỏ kiểm tra tương thích, không cho phép giả mạo entitlement, không đảm bảo iOS 17/18/26/27 chạy các chức năng đặc quyền. Xem `README_ORIGINAL.md` và `README.vi.md` để biết giới hạn của nguồn 3105 gốc.

## 4. Mở trên Xcode

1. Dùng macOS cài Xcode tương thích, mở `ThreeOneOSFive.xcodeproj`.
2. Chọn scheme **3105**, target iOS device (minimum deployment target gốc: iOS 16).
3. Dùng Apple signing setup hợp lệ, giải quyết certificate/provisioning/entitlements trước khi build.
4. Build/Run hoặc Product → Archive; kiểm tra logs và tương thích thiết bị thực tế. Trên Simulator một số thao tác privilege và file manager không được hỗ trợ.

## 5. Kiến trúc và bảo mật

- `helpers/DevHaiPlatform.swift`: model Codable, store demo JSON, session Keychain, random key `SecRandomCopyBytes`, giao diện `DHRemoteLicensing` và `DHHTTPSClient` sử dụng HTTPS.
- `views/DevHaiShell.swift`: login, dashboard, tab điều hướng, profile, maintenance.
- `views/DevHaiAdminPanel.swift`: 20 module SwiftUI, Swift Charts, JSON backup.
- `views/DesignSystem.swift`: màu xanh và component giao diện dùng lại.
- `.github/workflows/build-ipa.yml`: build unsigned/signed và upload artifact có kiểm tra kết quả.
- `ThreeOneOSFive.xcodeproj/xcshareddata/xcschemes/3105.xcscheme`: Xcode shared scheme.

Dữ liệu admin demo nằm trong Application Support và key demo lưu **dạng rõ để mô phỏng**. Bất kỳ ai có IPA/thiết bị đều có thể phân tích/chỉnh sửa dữ liệu demo. Do đó **KHÔNG** dùng keys `USER123` / `ADMINDEMO` cho môi trường production, không coi role trên UI là chứng thực từ server. Production yêu cầu backend HTTPS xác thực, lưu **hash key**, ràng buộc thiết bị ở server, RBAC kiểm tra tại từng endpoint, audit logs có giám sát, rate-limit và session/token expiry. `DHHTTPSClient` là hợp đồng giao tiếp chuẩn bị trước, **chưa tích hợp backend API thật**; cấu hình `DEVHAI_API_BASE_URL` khi chưa có server hoàn chỉnh sẽ khiến đăng nhập bị chặn có chủ đích.

## 6. Những vấn đề cần xác minh

- Các thay đổi SwiftUI có kiểm tra cú pháp, nhưng chỉ Xcode trên macOS có thể xác minh compile và linkage với toàn bộ Objective-C/C code cũ.
- Tương thích Apple signing, scheme, Swift Charts, điều hướng SwiftUI trên iPhone/iPad thực tế.
- Hành vi từng chức năng file/patch và kernel/sandbox vốn phụ thuộc phiên bản iOS/đặc quyền.
- Hoàn thiện API production, APNs, upload telemetry (nếu có consent), quản trị người dùng từ xa.
- Các screens đã viết bằng native SwiftUI, không có webview/mockup thay thế; tuy nhiên mức độ test chức năng mới chỉ là kiểm tra mã nguồn trên Linux, chưa phải QA trên iPhone.

## 7. Bản quyền và ghi công

Nguồn 3105 gốc: [YangJiiii/3105](https://github.com/YangJiiii/3105). Tác giả gốc: **YangJiii**, với các nguồn và cộng tác viên nêu trong `THIRD_PARTY_NOTICES.md`. Các file `LICENSE` (GPL-3.0), `THIRD_PARTY_NOTICES.md`, `README_ORIGINAL.md`, `README.vi.md`, `CHANGELOG.md`, `docs/` được giữ lại. `Made by DevHai` và `Customized by DevHai` chỉ nói về bản tùy biến, **không** tuyên bố DevHai đã tạo dự án gốc. Khi phân phối phiên bản sửa đổi, hãy tuân thủ các nghĩa vụ cung cấp nguồn, thông báo thay đổi và giấy phép phù hợp.
