// =============================================================================
// Testbench de tai C03 - Bo canh bao bon kenh co muc uu tien
// Chay: iverilog -g2012 -o tb_sc.out test/tb_selfcheck.v src/project.v && vvp tb_sc.out
//
// Phan 1: 7 ca dinh san, gia tri mong doi TINH BANG TAY (khong lay tu mach).
//         ui_in = {L3,L2,L1,L0}; uo_out = {000, ALERT, LVL[1:0], IDX[1:0]}
// Phan 2: quet du 256 to hop ui_in, doi chieu voi mo hinh tham chieu viet
//         bang vong lap (chi dung trong testbench, khong co trong RTL).
// =============================================================================
`timescale 1ns/1ps

module tb_selfcheck;
    reg  [7:0] ui_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out, uio_oe;

    integer errors_dir;   // so ca sai o phan 1
    integer errors_sweep; // so ca sai o phan 2
    integer total_dir;
    integer i;

    tt_um_eee703128_MSSV dut (
        .ui_in  (ui_in),
        .uo_out (uo_out),
        .uio_in (8'b0),
        .uio_out(uio_out),
        .uio_oe (uio_oe),
        .ena    (1'b1),
        .clk    (1'b0),
        .rst_n  (1'b1)
    );

    // ---- Phan 1: ca dinh san ------------------------------------------------
    task check(input [7:0] in, input [7:0] exp, input [255:0] name);
        begin
            ui_in = in;
            #10;
            total_dir = total_dir + 1;
            if (uo_out !== exp) begin
                errors_dir = errors_dir + 1;
                $display("SAI  [%0s] ui_in=%b  mong doi=%b  nhan duoc=%b",
                         name, in, exp, uo_out);
            end else begin
                $display("DUNG [%0s] ui_in=%b -> uo_out=%b (%0d)", name, in, uo_out, uo_out);
            end
        end
    endtask

    // ---- Phan 2: mo hinh tham chieu (vong lap, chi cho testbench) -----------
    function [7:0] ref_model(input [7:0] in);
        integer k;
        reg [1:0] lv [0:3];
        reg [1:0] best_lvl, best_idx;
        begin
            lv[0] = in[1:0]; lv[1] = in[3:2]; lv[2] = in[5:4]; lv[3] = in[7:6];
            best_lvl = lv[0];
            best_idx = 2'd0;
            for (k = 1; k < 4; k = k + 1) begin
                if (lv[k] > best_lvl) begin     // lon hon HAN: hoa thi giu chi so nho
                    best_lvl = lv[k];
                    best_idx = k[1:0];
                end
            end
            ref_model = {3'b000, (best_lvl != 2'b00), best_lvl, best_idx};
        end
    endfunction

    initial begin
        // Xuat waveform de mo bang GTKWave (tb.vcd)
        $dumpfile("tb_selfcheck.vcd");
        $dumpvars(0, tb_selfcheck);

        errors_dir = 0; errors_sweep = 0; total_dir = 0;

        //     ui_in         uo_out mong doi     ten ca
        check(8'b0000_0000, 8'b0000_0000, "1: tat ca im lang      ");
        check(8'b0010_0000, 8'b0001_1010,                "2: mot kenh bao (K2,m2)");
        check(8'b1100_1100, 8'b0001_1101,                "3: hoa K1&K3 -> K1     ");
        check(8'b0011_1001, 8'b0001_1110,                "4: khac muc -> K2,m3   ");
        check(8'b0101_0101, 8'b0001_0100,                "5*: 4 kenh cung muc 1  ");
        check(8'b1101_0101, 8'b0001_1111,                "6*: K3 thang duy nhat  ");
        check(8'b0000_0011, 8'b0001_1100,                "7*: K0 thang duy nhat  ");

        // ---- Quet 256 to hop ----
        for (i = 0; i < 256; i = i + 1) begin
            ui_in = i[7:0];
            #10;
            if (uo_out !== ref_model(i[7:0])) begin
                errors_sweep = errors_sweep + 1;
                $display("SAI quet ui_in=%b mong doi=%b nhan duoc=%b",
                         i[7:0], ref_model(i[7:0]), uo_out);
            end
        end

        // ---- Kiem tra chan khong dung ----
        if (uio_out !== 8'b0 || uio_oe !== 8'b0) begin
            errors_dir = errors_dir + 1;
            $display("SAI uio_out/uio_oe phai bang 0");
        end

        $display("----------------------------------------");
        $display("Ca dinh san : %0d ca, %0d sai", total_dir, errors_dir);
        $display("Quet 256    : 256 ca, %0d sai", errors_sweep);
        if (errors_dir == 0 && errors_sweep == 0) $display("KET QUA: PASS");
        else                                       $display("KET QUA: FAIL");
        $finish;
    end
endmodule
