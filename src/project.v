// =============================================================================
// De tai C03 - Bo canh bao bon kenh co muc uu tien (4-Channel Priority Alarm)
// Hoc phan EEE703128 - Bai kiem tra so 2
//
// Chuc nang : chon kenh co muc nghiem trong cao nhat trong 4 kenh (moi kenh 2 bit).
//             Neu nhieu kenh bang muc, kenh co chi so NHO HON thang.
// Loai mach : to hop thuan (clk, rst_n duoc khai bao nhung khong dung).
// Cau truc  : chuoi 3 "vong thi dau" noi tiep, moi vong = 1 GT2 + 2 MUX 2-bit.
//
// Khung chan:
//   ui_in[1:0]=L0  ui_in[3:2]=L1  ui_in[5:4]=L2  ui_in[7:6]=L3
//   uo_out[1:0]=IDX  uo_out[3:2]=LVL  uo_out[4]=ALERT  uo_out[7:5]=0
//
// LUU Y: doi "MSSV" trong ten module top thanh ma so sinh vien cua em
//        (vi du tt_um_eee703128_20123456) va cap nhat top_module trong info.yaml.
// =============================================================================

`default_nettype none

// -----------------------------------------------------------------------------
// GT2: gt = 1 khi a > b (so 2 bit khong dau)
//   gt = (a1 & ~b1) | (~(a1 ^ b1) & a0 & ~b0)
// -----------------------------------------------------------------------------
module c03_gt2 (
    input  wire [1:0] a,
    input  wire [1:0] b,
    output wire       gt
);
    wire hi_greater = a[1] & ~b[1];            // bit cao cua a lon hon
    wire hi_equal   = ~(a[1] ^ b[1]);          // bit cao bang nhau
    wire lo_greater = a[0] & ~b[0];            // bit thap cua a lon hon

    assign gt = hi_greater | (hi_equal & lo_greater);
endmodule

// -----------------------------------------------------------------------------
// MUX2 rong 2 bit: y = s ? x1 : x0   (viet tung bit bang AND/OR)
// -----------------------------------------------------------------------------
module c03_mux2_2b (
    input  wire       s,
    input  wire [1:0] x0,
    input  wire [1:0] x1,
    output wire [1:0] y
);
    assign y = ({2{s}} & x1) | ({2{~s}} & x0);
endmodule

// -----------------------------------------------------------------------------
// ROUND: mot vong thi dau
//   Kenh moi chi thay the kenh dang giu khi muc cua no LON HON HAN (>).
//   Dung ">" (khong phai ">=") de khi hoa, kenh chi so nho (da co mat truoc) duoc giu.
// -----------------------------------------------------------------------------
module c03_round (
    input  wire [1:0] new_lvl,
    input  wire [1:0] new_idx,
    input  wire [1:0] hold_lvl,
    input  wire [1:0] hold_idx,
    output wire [1:0] win_lvl,
    output wire [1:0] win_idx
);
    wire challenger_wins;

    c03_gt2 u_gt (
        .a (new_lvl),
        .b (hold_lvl),
        .gt(challenger_wins)
    );

    c03_mux2_2b u_mux_lvl (
        .s (challenger_wins),
        .x0(hold_lvl),
        .x1(new_lvl),
        .y (win_lvl)
    );

    c03_mux2_2b u_mux_idx (
        .s (challenger_wins),
        .x0(hold_idx),
        .x1(new_idx),
        .y (win_idx)
    );
endmodule

// -----------------------------------------------------------------------------
// TOP
// -----------------------------------------------------------------------------
module tt_um_eee703128_24107915 (
    input  wire [7:0] ui_in,    // 8 chan vao rieng
    output wire [7:0] uo_out,   // 8 chan ra rieng
    input  wire [7:0] uio_in,   // 8 chan hai chieu - chieu vao (khong dung)
    output wire [7:0] uio_out,  // 8 chan hai chieu - chieu ra  (khong dung)
    output wire [7:0] uio_oe,   // 1 = chan do la dau ra         (khong dung)
    input  wire       ena,      // luon = 1
    input  wire       clk,      // xung nhip (khong dung - mach to hop)
    input  wire       rst_n     // reset tich cuc muc thap (khong dung)
);

    // Tach 4 kenh dau vao
    wire [1:0] l0 = ui_in[1:0];
    wire [1:0] l1 = ui_in[3:2];
    wire [1:0] l2 = ui_in[5:4];
    wire [1:0] l3 = ui_in[7:6];

    // Ket qua trung gian cua tung vong
    wire [1:0] lvl1, idx1;
    wire [1:0] lvl2, idx2;
    wire [1:0] lvl3, idx3;

    // Vong 1: kenh 1 thach dau kenh 0 (kenh 0 dang giu, chi so 0)
    c03_round u_r1 (
        .new_lvl (l1),   .new_idx (2'd1),
        .hold_lvl(l0),   .hold_idx(2'd0),
        .win_lvl (lvl1), .win_idx (idx1)
    );

    // Vong 2: kenh 2 thach dau nguoi thang vong 1
    c03_round u_r2 (
        .new_lvl (l2),   .new_idx (2'd2),
        .hold_lvl(lvl1), .hold_idx(idx1),
        .win_lvl (lvl2), .win_idx (idx2)
    );

    // Vong 3: kenh 3 thach dau nguoi thang vong 2
    c03_round u_r3 (
        .new_lvl (l3),   .new_idx (2'd3),
        .hold_lvl(lvl2), .hold_idx(idx2),
        .win_lvl (lvl3), .win_idx (idx3)
    );

    // Co ALERT = 1 neu muc thang > 0
    wire alert = lvl3[1] | lvl3[0];

    // Ghep dau ra: {000, ALERT, LVL[1:0], IDX[1:0]}
    assign uo_out  = {3'b000, alert, lvl3, idx3};
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // Chan dau vao khong dung: tranh canh bao lint
    wire _unused = &{ena, clk, rst_n, uio_in, 1'b0};

endmodule

`default_nettype wire
