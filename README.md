# DrawApp - Ứng dụng vẽ đa nền tảng

## ✨ Thông tin nhóm
*   **23120045** - Dương Khánh Khải Hưng
*   **23120065** - Nguyễn Trọng Nhân
*   **23120149** - Nguyễn Hưng Nguyên
*   **23120154** - Nguyễn Thanh Phong
*   **23120171** - Đặng Ngọc Tiên
*   **23120175** - Huỳnh Thái Toàn

🎬 **Video Demo:** [Đang cập nhật...]

## 📝 Tổng quan

**DrawApp** là một ứng dụng vẽ đồ họa vector đơn giản nhưng mạnh mẽ, được phát triển nhằm cung cấp một công cụ sáng tạo linh hoạt trên cả máy tính và thiết bị di động. Với giao diện trực quan và bộ công cụ đa dạng, người dùng có thể dễ dàng phác thảo ý tưởng, vẽ các hình khối cơ bản và lưu trữ sản phẩm dưới nhiều định dạng khác nhau.

Ứng dụng được tối ưu hóa cho trải nghiệm người dùng với khả năng tùy biến cao về màu sắc, kích thước và hỗ trợ các tính năng hiện đại như hoàn tác, chế độ tối và xuất ảnh chất lượng cao.

## 🚀 Các chức năng đã thực hiện
### Chức năng yêu cầu

Ứng dụng đáp ứng đầy đủ các yêu cầu cơ bản sau:

1.  **Hỗ trợ vẽ các đối tượng cơ bản:**
    *   Điểm (Point)
    *   Đường thẳng (Line)
    *   Hình Ellipse và Hình tròn (Circle)
    *   Hình chữ nhật (Rectangle) và Hình vuông (Square)
2.  **Hỗ trợ tô màu:** Cho phép chọn màu nền (Fill Color) cho các hình khối.
3.  **Tùy chỉnh đường viền:**
    *   Thay đổi độ dày đường viền (Stroke Width).
    *   Thay đổi màu sắc đường viền (Stroke Color).
4.  **Lưu và Nạp dữ liệu:**
    *   Hỗ trợ lưu bản vẽ dưới dạng tệp nhị phân tự định nghĩa (`.mydraw`).
    *   Nạp lại tệp đã lưu để tiếp tục chỉnh sửa.
5.  **Xuất ảnh:** Hỗ trợ xuất bản vẽ ra định dạng ảnh **PNG** hoặc **JPEG**.

### Chức năng nâng cao

Ngoài các yêu cầu cơ bản, ứng dụng còn tích hợp các tính năng bổ sung nhằm tối ưu trải nghiệm người dùng:

1.  **Hoàn tác & Làm lại (Undo/Redo):** Cho phép quay lại các bước vẽ trước đó hoặc khôi phục các thao tác vừa hoàn tác.
2.  **Vẽ tự do (Pencil):** Hỗ trợ công cụ bút chì để vẽ các đường nét tự do.
3.  **Chọn và Di chuyển đối tượng:**
    *   Công cụ **Select** cho phép chọn các hình đã vẽ trên canvas.
    *   Hỗ trợ di chuyển hoặc thay đổi thuộc tính của đối tượng sau khi vẽ.
4.  **Chế độ lưới (Grid View):** Hiển thị lưới tọa độ giúp căn chỉnh các đối tượng chính xác hơn.
5.  **Đổ màu (Paint Bucket):** Công cụ tô màu nhanh cho các vùng khép kín.
6.  **Giao diện tối/sáng (Dark/Light Mode):** Tự động thay đổi theo hệ thống hoặc tùy chỉnh thủ công, lưu lại trạng thái qua `SharedPreferences`.
7.  **Thiết kế đáp ứng (Responsive Design):** Giao diện tối ưu hóa riêng biệt cho máy tính (Desktop) và điện thoại (Mobile).
8.  **Quản lý quyền (Permissions):** Xử lý quyền truy cập bộ nhớ thông minh trên Android (bao gồm cả Android 13+).

## 🛠 Công nghệ sử dụng

*   **Framework:** Flutter & Dart
*   **State Management:** Provider
*   **Storage:** `path_provider`, `file_picker`, `shared_preferences`
*   **Permissions:** `permission_handler`

---
*Seminar Lập trình Windows - 2025*
