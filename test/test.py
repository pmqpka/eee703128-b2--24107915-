# SPDX-License-Identifier: Apache-2.0
# Test cocotb cho de C03 - Bo canh bao bon kenh co muc uu tien
#   ui_in  = {L3, L2, L1, L0}  (moi kenh 2 bit)
#   uo_out = {000, ALERT, LVL[1:0], IDX[1:0]}

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


def ref_model(ui):
    """Mo hinh tham chieu (vong lap, chi dung trong test)."""
    lv = [(ui >> (2 * k)) & 3 for k in range(4)]
    best_lvl, best_idx = lv[0], 0
    for k in range(1, 4):
        if lv[k] > best_lvl:          # lon hon HAN: hoa thi giu chi so nho
            best_lvl, best_idx = lv[k], k
    return ((1 if best_lvl else 0) << 4) | (best_lvl << 2) | best_idx


# Ca co dinh: gia tri mong doi TINH BANG TAY
FIXED_CASES = [
    (0b0000_0000, 0b0000_0000, "1: tat ca im lang"),
    (0b0010_0000, 0b0001_1010, "2: mot kenh bao (K2, muc 2)"),
    (0b1100_1100, 0b0001_1101, "3: hoa K1 va K3 -> K1 thang"),
    (0b0011_1001, 0b0001_1110, "4: khac muc -> K2, muc 3"),
    (0b0101_0101, 0b0001_0100, "5*: bon kenh cung muc 1 -> K0"),
    (0b1101_0101, 0b0001_1111, "6*: K3 thang duy nhat"),
    (0b0000_0011, 0b0001_1100, "7*: K0 thang duy nhat"),
]


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Mach to hop nen khong can xung nhip, nhung van khoi dong cho dung khung chan
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # --- Phan 1: ca co dinh ---
    for ui, expected, name in FIXED_CASES:
        dut.ui_in.value = ui
        await Timer(1, unit="us")
        got = int(dut.uo_out.value)
        dut._log.info(f"[{name}] ui_in={ui:08b} -> uo_out={got:08b} ({got})")
        assert got == expected, (
            f"[{name}] ui_in={ui:08b}: mong doi {expected:08b}, nhan duoc {got:08b}")

    # --- Phan 2: quet du 256 to hop ---
    for ui in range(256):
        dut.ui_in.value = ui
        await Timer(1, unit="us")
        got = int(dut.uo_out.value)
        exp = ref_model(ui)
        assert got == exp, f"quet ui_in={ui:08b}: mong doi {exp:08b}, nhan duoc {got:08b}"

    # --- Chan khong dung phai bang 0 ---
    assert int(dut.uio_out.value) == 0, "uio_out phai bang 0"
    assert int(dut.uio_oe.value) == 0, "uio_oe phai bang 0"
