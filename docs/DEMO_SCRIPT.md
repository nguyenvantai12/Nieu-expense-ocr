# Kịch bản demo — 2 đến 3 phút

## Chuẩn bị

- Cài bản debug/release trên thiết bị Android và mở ứng dụng.
- Chuẩn bị một ảnh biên lai rõ nét, tốt nhất có dòng số tiền/ngày và tên cửa hàng hoặc người nhận.
- Nếu dùng emulator, chọn ảnh từ thư viện. Kiểm tra trước để ảnh đã có trong thư viện máy ảo.

## Trình tự quay

1. **Danh sách (15 giây):** giới thiệu các khoản chi đã lưu, lọc theo danh mục, mở một khoản để xem ảnh và văn bản OCR.
2. **Quét và review (45–60 giây):** nhấn Quét, chọn Chụp ảnh hoặc Chọn từ thư viện. Chờ OCR hoàn tất; chỉ rõ tên cửa hàng/người nhận, số tiền, ngày và danh mục được điền. Sửa một trường để minh họa người dùng kiểm tra kết quả trước khi lưu.
3. **Lưu và chống trùng (20 giây):** lưu khoản chi, quay lại danh sách và mở chi tiết. Nếu tiện, quét lại cùng hóa đơn để hiện cảnh báo trùng; hủy lần lưu thứ hai hoặc chọn tiếp tục để minh họa lựa chọn của người dùng.
4. **Báo cáo (30–40 giây):** mở Báo cáo, duyệt tháng, chỉ tổng theo danh mục, ngân sách, biểu đồ theo tuần và 7 ngày. Chọn một lát donut nếu chart có tương tác.
5. **Cài đặt và hoàn tất (15 giây):** bật theme tối, quay lại danh sách; cho thấy card vẫn đọc được. Kết thúc bằng một câu về lưu offline trên thiết bị.

## Lời dẫn ngắn

“Ứng dụng đọc hóa đơn ngay trên thiết bị. Vì OCR có thể sai, mọi trường đều được hiển thị để kiểm tra và chỉnh sửa trước khi ghi xuống SQLite. Từ các khoản đã xác nhận, ứng dụng cập nhật danh sách và báo cáo theo tháng, danh mục và thời gian.”

## Nộp sản phẩm

Quay màn hình thiết bị/emulator ở độ phân giải dễ đọc, bật chế độ không làm phiền và tránh để lộ thông báo hay dữ liệu cá nhân thật. Lưu video demo riêng, không commit video lớn vào source nếu nền tảng nộp bài không yêu cầu. Nộp kèm APK release ký bằng keystore của bạn và báo cáo `docs/REPORT.md`.
