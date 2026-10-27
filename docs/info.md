## Thiết kế này làm gì

Đây là bộ cảnh báo bốn kênh có mức ưu tiên (đề C03). Mạch nhận mức nghiêm trọng của 4 kênh cảnh báo, mỗi kênh gồm 2 bit (`00` = im lặng, `01` = thấp, `10` = trung bình, `11` = nghiêm trọng), tổng cộng 8 bit vào `ui_in`. Mạch xuất ra chỉ số của kênh nghiêm trọng nhất (2 bit), mức của kênh đó (2 bit) và một cờ `ALERT` bằng 1 khi có ít nhất một kênh mức lớn hơn 0. Nếu nhiều kênh cùng đạt mức cao nhất thì kênh có chỉ số nhỏ hơn được chọn. Đây là mạch tổ hợp thuần, đầu ra chỉ phụ thuộc vào đầu vào hiện tại.

## How it works

Mạch giữ một "kênh dẫn đầu hiện tại" (mức và chỉ số), rồi cho từng kênh tiếp theo so sánh với nó qua ba vòng nối tiếp. Kênh mới chỉ thay thế kênh dẫn đầu khi mức của nó **lớn hơn hẳn** (phép `>`, không phải `>=`), nhờ đó khi hoà thì kênh có chỉ số nhỏ hơn được giữ lại.

Mỗi vòng (`c03_round`) gồm một bộ so sánh lớn hơn 2 bit (`c03_gt2`) và hai bộ ghép kênh 2 bit (`c03_mux2_2b`), một cho mức và một cho chỉ số. Module top khởi tạo ba vòng:

```
Vòng 1:  s1 = gt(L1, L0)    (lvl1, idx1) = s1 ? (L1, 1) : (L0, 0)
Vòng 2:  s2 = gt(L2, lvl1)  (lvl2, idx2) = s2 ? (L2, 2) : (lvl1, idx1)
Vòng 3:  s3 = gt(L3, lvl2)  (lvl3, idx3) = s3 ? (L3, 3) : (lvl2, idx2)
Đầu ra:  IDX = idx3,  LVL = lvl3,  ALERT = lvl3[1] | lvl3[0]
```

Biểu thức của bộ so sánh 2 bit: `gt(a, b) = a1·¬b1 + ¬(a1 ⊕ b1)·a0·¬b0`. Bộ ghép kênh từng bit: `y = (s·x1) + (¬s·x0)`. Mã nguồn không dùng vòng lặp hay toán tử so sánh ở mức hành vi.

Do chỉ có 8 bit đầu vào nên không gian đầu vào có đúng 256 tổ hợp, và bảng chân lý đầy đủ được kiểm chứng bằng cách quét toàn bộ (xem phần kiểm thử).

## How to test

Giá trị mong đợi của 7 ca cố định được tính bằng tay trước khi chạy mô phỏng, theo quy ước `ui_in = {L3, L2, L1, L0}` và `uo_out = {000, ALERT, LVL, IDX}`:

| Ca | `ui_in` | Mức (L3,L2,L1,L0) | `uo_out` mong đợi | Loại |
|---|---|---|---|---|
| 1 | `0000_0000` | 0,0,0,0 | `0000_0000` | Biên: không có cảnh báo |
| 2 | `0010_0000` | 0,2,0,0 | `0001_1010` | Một kênh báo |
| 3 | `1100_1100` | 3,0,3,0 | `0001_1101` | Biên: hoà K1 và K3, K1 thắng |
| 4 | `0011_1001` | 0,3,2,1 | `0001_1110` | Bốn kênh khác mức |
| 5* | `0101_0101` | 1,1,1,1 | `0001_0100` | Biên: hoà toàn bộ, K0 thắng |
| 6* | `1101_0101` | 3,1,1,1 | `0001_1111` | Kênh 3 thắng duy nhất (vòng cuối) |
| 7* | `0000_0011` | 0,0,0,3 | `0001_1100` | Kênh 0 thắng duy nhất (người giữ ban đầu) |

Các ca có dấu `*` là ca bổ sung ngoài danh sách của đề. Ngoài ra testbench quét đủ 256 tổ hợp `ui_in` và so với một mô hình tham chiếu viết bằng vòng lặp (chỉ có trong testbench, không có trong RTL), đồng thời kiểm `uio_out` và `uio_oe` luôn bằng 0.

Kết quả mô phỏng RTL bằng Icarus Verilog: 7 ca cố định 0 sai, phép quét 256 tổ hợp 0 sai.

Để kiểm tra chính testbench, thiết kế đã được cố ý làm sai bằng cách đổi `>` thành `>=` trong bộ so sánh. Khi đó 3/7 ca cố định (ca 1, 3, 5*) và 112/256 tổ hợp trong phép quét báo sai, nên testbench bắt được lỗi ở biên của luật hoà. Sau đó thiết kế đã được khôi phục về bản đúng.

## Ánh xạ chân

| Chân | Tín hiệu | Ý nghĩa |
|---|---|---|
| `ui_in[1:0]` | L0 | Mức nghiêm trọng kênh 0 |
| `ui_in[3:2]` | L1 | Mức nghiêm trọng kênh 1 |
| `ui_in[5:4]` | L2 | Mức nghiêm trọng kênh 2 |
| `ui_in[7:6]` | L3 | Mức nghiêm trọng kênh 3 |
| `uo_out[1:0]` | IDX | Chỉ số kênh thắng (0 đến 3) |
| `uo_out[3:2]` | LVL | Mức của kênh thắng |
| `uo_out[4]` | ALERT | Bằng 1 khi có ít nhất một kênh mức lớn hơn 0 |
| `uo_out[7:5]` | không dùng | Luôn bằng 0 |
| `uio[7:0]` | không dùng | `uio_out` và `uio_oe` luôn bằng 0 |

Các cổng `clk`, `rst_n` và `ena` được khai báo theo khung chân chung nhưng không được sử dụng.

## Giới hạn

- **Thứ tự kênh là giả định.** Đề chỉ ghi "4 kênh × 2 bit" mà không nêu thứ tự. Thiết kế giả định kênh 0 ở bit thấp nhất (`ui_in[1:0]`) và kênh 3 ở bit cao nhất. Nếu yêu cầu thực tế khác thì phải đổi cách gán chân.
- **Luật hoà là một lựa chọn.** Khi nhiều kênh cùng mức cao nhất, thiết kế chọn kênh có chỉ số nhỏ nhất. Khi cả bốn kênh bằng 0, `IDX` được cố định bằng 0 để đầu ra luôn xác định; giá trị này không mang ý nghĩa "kênh 0 đang báo động" (khi đó `ALERT` = 0).
- **Chỉ kiểm chứng ở mức mô phỏng RTL.** Chưa có mô phỏng mức cổng sau tổng hợp, nên kết quả PASS không chứng minh netlist hay layout đúng chức năng.
- **Mô hình tham chiếu và RTL cùng một cách hiểu đề.** Nếu cách hiểu về thứ tự kênh hoặc luật hoà sai thì cả hai cùng sai và testbench vẫn báo PASS. Giá trị tính tay ở 7 ca cố định cũng dựa trên cùng giả định.
- **Mạch tổ hợp nên số liệu thời gian chỉ mang tính tham khảo.** Không có đường thanh ghi → thanh ghi, nên slack (nếu có) chỉ phản ánh đường từ cổng vào tới cổng ra theo ràng buộc của công cụ, và không thể coi là tần số hoạt động của một mạch có xung nhịp.
- **Không suy ra được từ kết quả công cụ:** việc chạy qua chuỗi công cụ và có tệp layout không có nghĩa thiết kế đã tape-out, sign-off hay sẵn sàng sản xuất. Học phần này không chế tạo chip; tệp layout chỉ dùng để học. Việc DRC hay LVS sạch cũng không chứng minh thiết kế đúng chức năng, và các con số công suất, diện tích chỉ là ước lượng của công cụ, không phải số đo trên silicon.