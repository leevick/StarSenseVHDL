--*****************************************************************************
-- DISCLAIMER OF LIABILITY
--
-- This file contains proprietary and confidential information of
-- Xilinx, Inc. ("Xilinx"), that is distributed under a license
-- from Xilinx, and may be used, copied and/or disclosed only
-- pursuant to the terms of a valid license agreement with Xilinx.
--
-- XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
-- ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
-- EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
-- LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
-- MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
-- does not warrant that functions included in the Materials will
-- meet the requirements of Licensee, or that the operation of the
-- Materials will be uninterrupted or error-free, or that defects
-- in the Materials will be corrected. Furthermore, Xilinx does
-- not warrant or make any representations regarding use, or the
-- results of the use, of the Materials in terms of correctness,
-- accuracy, reliability or otherwise.
--
-- Xilinx products are not designed or intended to be fail-safe,
-- or for use in any application requiring fail-safe performance,
-- such as life-support or safety devices or systems, Class III
-- medical devices, nuclear facilities, applications related to
-- the deployment of airbags, or any other applications that could
-- lead to death, personal injury or severe property or
-- environmental damage (individually and collectively, "critical
-- applications"). Customer assumes the sole risk and liability
-- of any use of Xilinx products in critical applications,
-- subject only to applicable laws and regulations governing
-- limitations on product liability.
--
-- Copyright 2005, 2006, 2007, 2008 Xilinx, Inc.
-- All rights reserved.
--
-- This disclaimer and copyright notice must be retained as part
-- of this file at all times.
--*****************************************************************************
--   ____  ____
--  /   /\/   /
-- /___/  \  /   Vendor             : Xilinx
-- \   \   \/    Version            : 3.6.1
--  \   \        Application        : MIG
--  /   /        Filename           : DDR2_ddr2_controller_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module is the main control logic of the memory interface.
--               All commands are issued from here according to the burst,
--               CAS Latency and the user commands.
-- Revision History:
--   Rev 1.1 - Changes for V4 no edge straddle calibration scheme.
--             Added cal_first_loop input to issue a second pattern calibration
--             read if the first one does not result in a successful
--             calibration. Various other changes. PK. 12/22/07
--   Rev 1.2 - Modified the logic of 3-state enable for the data I/O to enable
--             write data output one-half clock cycle before
--             the first data word, and disable the write data
--             one-half clock cycle after the last data word. PK. 11/11/08
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity DDR2_ddr2_controller_0 is
  generic
    (
     COL_WIDTH : integer := COLUMN_ADDRESS;
     ROW_WIDTH : integer := ROW_ADDRESS
    );
  port(
    -- controller inputs
    clk0                   : in  std_logic;
    rst                    : in  std_logic;
    -- FIFO  signals
    af_addr                : in  std_logic_vector(35 downto 0);
    af_empty               : in  std_logic;
    -- Input signal for the Dummy Reads
    phy_dly_slct_done      : in  std_logic;
    cal_first_loop         : in  std_logic;
    comp_done              : in  std_logic;
    ctrl_dummyread_start   : out std_logic;

    ctrl_dummy_wr_sel      : out std_logic;
    burst_length_div2      : out std_logic_vector(2 downto 0);
    -- FIFO read enable signals
    ctrl_af_rden           : out std_logic;
    ctrl_wdf_rden          : out std_logic;
    -- Rst and Enable signals for DQS logic
    ctrl_dqs_rst           : out std_logic;
    ctrl_dqs_en            : out std_logic;
    -- Read and Write Enable signals to the phy interface
    ctrl_wren              : out std_logic;
    ctrl_rden              : out std_logic;

    ctrl_ddr2_address      : out std_logic_vector((ROW_ADDRESS-1) downto 0);
    ctrl_ddr2_ba           : out std_logic_vector((BANK_ADDRESS-1) downto 0);
    ctrl_ddr2_ras_l        : out std_logic;
    ctrl_ddr2_cas_l        : out std_logic;
    ctrl_ddr2_we_l         : out std_logic;
    ctrl_ddr2_cs_l         : out std_logic_vector((CS_WIDTH-1) downto 0);
    ctrl_ddr2_cs_l_cpy         : out std_logic_vector((CS_WIDTH-1) downto 0);
    ctrl_ddr2_cke          : out std_logic_vector((CKE_WIDTH-1) downto 0);
    ctrl_ddr2_odt          : out std_logic_vector((ODT_WIDTH-1) downto 0);
    ctrl_ddr2_odt_cpy          : out std_logic_vector((ODT_WIDTH-1) downto 0);
    init_done_r            : out std_logic;

    -- Debug Signals
    dbg_init_done          : out std_logic
    );

    attribute syn_maxfan : integer;
    attribute IOB        : string;
    attribute syn_maxfan of af_empty : signal is 10;
    attribute IOB of ctrl_ddr2_address : signal is "FORCE";
    attribute IOB of ctrl_ddr2_ba      : signal is "FORCE";
    attribute IOB of ctrl_ddr2_ras_l   : signal is "FORCE";
    attribute IOB of ctrl_ddr2_cas_l   : signal is "FORCE";
    attribute IOB of ctrl_ddr2_we_l    : signal is "FORCE";
    attribute IOB of ctrl_ddr2_cs_l    : signal is "TRUE";
    attribute IOB of ctrl_ddr2_cs_l_cpy    : signal is "TRUE";
    attribute IOB of ctrl_ddr2_cke     : signal is "FORCE";
    attribute IOB of ctrl_ddr2_odt     : signal is "TRUE";
    attribute IOB of ctrl_ddr2_odt_cpy     : signal is "TRUE";

end entity ;

architecture arc_controller of DDR2_ddr2_controller_0 is

  -- time to wait after initialization-related writes and reads (used as a
  -- generic delay - exact number doesn't matter as long as it's large enough)
  constant CNTNEXT                 : std_logic_vector(6 downto 0)  := "1101110";

  constant INIT_IDLE               : std_logic_vector(21 downto 0) := "0000000000000000000001";  --  0
  constant INIT_LOAD_MODE          : std_logic_vector(21 downto 0) := "0000000000000000000010";  --  1
  constant INIT_MODE_REGISTER_WAIT : std_logic_vector(21 downto 0) := "0000000000000000000100";  --  2
  constant INIT_PRECHARGE          : std_logic_vector(21 downto 0) := "0000000000000000001000";  --  3
  constant INIT_PRECHARGE_WAIT     : std_logic_vector(21 downto 0) := "0000000000000000010000";  --  4
  constant INIT_AUTO_REFRESH       : std_logic_vector(21 downto 0) := "0000000000000000100000";  --  5
  constant INIT_AUTO_REFRESH_WAIT  : std_logic_vector(21 downto 0) := "0000000000000001000000";  --  6
  constant INIT_COUNT_200          : std_logic_vector(21 downto 0) := "0000000000000010000000";  --  7
  constant INIT_COUNT_200_WAIT     : std_logic_vector(21 downto 0) := "0000000000000100000000";  --  8
  constant INIT_DUMMY_READ_CYCLES  : std_logic_vector(21 downto 0) := "0000000000001000000000";  --  9
  constant INIT_DUMMY_ACTIVE       : std_logic_vector(21 downto 0) := "0000000000010000000000";  --  10
  constant INIT_DUMMY_ACTIVE_WAIT  : std_logic_vector(21 downto 0) := "0000000000100000000000";  --  11
  constant INIT_DUMMY_WRITE        : std_logic_vector(21 downto 0) := "0000000001000000000000";  --  12
  constant INIT_DUMMY_WRITE_READ   : std_logic_vector(21 downto 0) := "0000000010000000000000";  --  13
  constant INIT_DUMMY_READ         : std_logic_vector(21 downto 0) := "0000000100000000000000";  --  14
  constant INIT_DUMMY_READ_WAIT    : std_logic_vector(21 downto 0) := "0000001000000000000000";  --  15
  constant INIT_DUMMY_FIRST_READ   : std_logic_vector(21 downto 0) := "0000010000000000000000";  --  16
  constant INIT_DEEP_MEMORY_ST     : std_logic_vector(21 downto 0) := "0000100000000000000000";  --  17
  constant INIT_PATTERN_WRITE      : std_logic_vector(21 downto 0) := "0001000000000000000000";  --  18
  constant INIT_PATTERN_WRITE_READ : std_logic_vector(21 downto 0) := "0010000000000000000000";  --  19
  constant INIT_PATTERN_READ       : std_logic_vector(21 downto 0) := "0100000000000000000000";  --  20
  constant INIT_PATTERN_READ_WAIT  : std_logic_vector(21 downto 0) := "1000000000000000000000";  --  21

  constant IDLE                    : std_logic_vector(16 downto 0) := "00000000000000001";  --  0
  constant LOAD_MODE               : std_logic_vector(16 downto 0) := "00000000000000010";  --  1
  constant MODE_REGISTER_WAIT      : std_logic_vector(16 downto 0) := "00000000000000100";  --  2
  constant PRECHARGE               : std_logic_vector(16 downto 0) := "00000000000001000";  --  3
  constant PRECHARGE_WAIT          : std_logic_vector(16 downto 0) := "00000000000010000";  --  4
  constant AUTO_REFRESH            : std_logic_vector(16 downto 0) := "00000000000100000";  --  5
  constant AUTO_REFRESH_WAIT       : std_logic_vector(16 downto 0) := "00000000001000000";  --  6
  constant ACTIVE                  : std_logic_vector(16 downto 0) := "00000000010000000";  --  7
  constant ACTIVE_WAIT             : std_logic_vector(16 downto 0) := "00000000100000000";  --  8
  constant FIRST_READ              : std_logic_vector(16 downto 0) := "00000001000000000";  --  9
  constant BURST_READ              : std_logic_vector(16 downto 0) := "00000010000000000";  --  10
  constant READ_WAIT               : std_logic_vector(16 downto 0) := "00000100000000000";  --  11
  constant FIRST_WRITE             : std_logic_vector(16 downto 0) := "00001000000000000";  --  12
  constant BURST_WRITE             : std_logic_vector(16 downto 0) := "00010000000000000";  --  13
  constant WRITE_WAIT              : std_logic_vector(16 downto 0) := "00100000000000000";  --  14
  constant WRITE_READ              : std_logic_vector(16 downto 0) := "01000000000000000";  --  15
  constant READ_WRITE              : std_logic_vector(16 downto 0) := "10000000000000000";  --  16

  -- INTERNAL SIGNALS--

  signal init_count           : std_logic_vector(3 downto 0);
  signal init_count_cp        : std_logic_vector(3 downto 0);
  signal init_memory          : std_logic;
  signal count_200_cycle      : std_logic_vector(7 downto 0);
  signal ref_flag             : std_logic;
  signal ref_flag_0           : std_logic;
  signal ref_flag_0_r         : std_logic;
  signal auto_ref             : std_logic;

  signal next_state           : std_logic_vector(16 downto 0);
  signal state                : std_logic_vector(16 downto 0);
  signal state_r2             : std_logic_vector(16 downto 0);
  signal state_r3             : std_logic_vector(16 downto 0);

  signal init_next_state      : std_logic_vector(21 downto 0);
  signal init_state           : std_logic_vector(21 downto 0);
  signal init_state_r2        : std_logic_vector(21 downto 0);

  signal row_addr_r           : std_logic_vector((ROW_ADDRESS -1) downto 0);
  signal ddr2_address_init_r  : std_logic_vector((ROW_ADDRESS -1) downto 0);
  signal ddr2_address_r1      : std_logic_vector((ROW_ADDRESS -1) downto 0);
  signal ddr2_address_r2      : std_logic_vector((ROW_ADDRESS -1) downto 0);
  signal ddr2_ba_r1           : std_logic_vector((BANK_ADDRESS -1) downto 0);
  signal ddr2_ba_r2           : std_logic_vector((BANK_ADDRESS -1) downto 0);

  -- counters for DDR2 controller
  signal mrd_count            : std_logic;
  signal rp_count             : std_logic_vector(2 downto 0);
  signal rfc_count            : std_logic_vector(7 downto 0);
  signal rcd_count            : std_logic_vector(2 downto 0);
  signal ras_count            : std_logic_vector(4 downto 0);
  signal wr_to_rd_count       : std_logic_vector(3 downto 0);
  signal rd_to_wr_count       : std_logic_vector(3 downto 0);
  signal rtp_count            : std_logic_vector(3 downto 0);
  signal wtp_count            : std_logic_vector(3 downto 0);

  signal refi_count           : std_logic_vector((MAX_REF_WIDTH-1) downto 0);
  signal cas_count            : std_logic_vector(2 downto 0);
  signal cas_check_count      : std_logic_vector(3 downto 0);
  signal wrburst_cnt          : std_logic_vector(2 downto 0);
  signal read_burst_cnt       : std_logic_vector(2 downto 0);
  signal ctrl_wren_cnt        : std_logic_vector(2 downto 0);
  signal rdburst_cnt          : std_logic_vector(3 downto 0);
  signal af_addr_r            : std_logic_vector(35 downto 0);
  signal af_addr_r1           : std_logic_vector(35 downto 0);

  signal wdf_rden_r           : std_logic;
  signal wdf_rden_r2          : std_logic;
  signal wdf_rden_r3          : std_logic;
  signal wdf_rden_r4          : std_logic;
  signal ctrl_wdf_rden_int    : std_logic;

  signal af_rden              : std_logic;
  signal ddr2_ras_r2          : std_logic;
  signal ddr2_cas_r2          : std_logic;
  signal ddr2_we_r2           : std_logic;
  signal ddr2_ras_r           : std_logic;
  signal ddr2_cas_r           : std_logic;
  signal ddr2_we_r            : std_logic;
  signal ddr2_ras_r3          : std_logic;
  signal ddr2_cas_r3          : std_logic;
  signal ddr2_we_r3           : std_logic;

  signal idle_cnt             : std_logic_vector(3 downto 0);

  signal ctrl_dummyread_start_r1  : std_logic;
  signal ctrl_dummyread_start_r2  : std_logic;
  signal ctrl_dummyread_start_r3  : std_logic;
  signal ctrl_dummyread_start_r4  : std_logic;
  signal ctrl_dummyread_start_r5  : std_logic;
  signal ctrl_dummyread_start_r6  : std_logic;
  signal ctrl_dummyread_start_r7  : std_logic;
  signal ctrl_dummyread_start_r8  : std_logic;
  signal ctrl_dummyread_start_r9  : std_logic;

  signal conflict_resolved_r      : std_logic;

  signal dqs_reset                : std_logic;
  signal dqs_reset_r1             : std_logic;
  signal dqs_reset_r2             : std_logic;
  signal dqs_reset_r3             : std_logic;
  signal dqs_reset_r4             : std_logic;
  signal dqs_reset_r5             : std_logic;
  signal dqs_reset_r6             : std_logic;

  signal dqs_en                   : std_logic;
  signal dqs_en_r1                : std_logic;
  signal dqs_en_r2                : std_logic;
  signal dqs_en_r3                : std_logic;
  signal dqs_en_r4                : std_logic;
  signal dqs_en_r5                : std_logic;
  signal dqs_en_r6                : std_logic;

  signal ctrl_wdf_read_en         : std_logic;
  signal ctrl_wdf_read_en_r1      : std_logic;
  signal ctrl_wdf_read_en_r2      : std_logic;
  signal ctrl_wdf_read_en_r3      : std_logic;
  signal ctrl_wdf_read_en_r4      : std_logic;
  signal ctrl_wdf_read_en_r5      : std_logic;
  signal ctrl_wdf_read_en_r6      : std_logic;

  signal ddr2_cs_r1               : std_logic_vector((CS_WIDTH-1) downto 0);
  signal ddr2_cs_r                : std_logic_vector((CS_WIDTH-1) downto 0);
  signal ddr2_cke_r               : std_logic_vector((CKE_WIDTH-1) downto 0);
  signal chip_cnt                 : std_logic_vector(1 downto 0);
  signal auto_cnt                 : std_logic_vector(2 downto 0);

  -- Precharge fix for deep memory
  signal pre_cnt                  : std_logic_vector(2 downto 0);

  -- FIFO read enable signals
  -- Rst and Enable signals for DQS logic
  -- Read and Write Enable signals to the phy interface

  signal dummy_read_en            : std_logic;
  signal ctrl_init_done           : std_logic;

  signal count_200cycle_done_r    : std_logic;

  signal init_done                : std_logic;

  signal burst_cnt                : std_logic_vector(2 downto 0);

  signal ctrl_write_en            : std_logic;
  signal ctrl_write_en_r1         : std_logic;
  signal ctrl_write_en_r2         : std_logic;
  signal ctrl_write_en_r3         : std_logic;
  signal ctrl_write_en_r4         : std_logic;
  signal ctrl_write_en_r5         : std_logic;
  signal ctrl_write_en_r6         : std_logic;

  signal ctrl_read_en             : std_logic;
  signal ctrl_read_en_r           : std_logic;
  signal ctrl_read_en_r1          : std_logic;
  signal ctrl_read_en_r2          : std_logic;
  signal ctrl_read_en_r3          : std_logic;
  signal ctrl_read_en_r4          : std_logic;

  signal odt_cnt                  : std_logic_vector(3 downto 0);
  signal odt_en_cnt               : std_logic_vector(3 downto 0);
  signal odt_en                   : std_logic_vector((ODT_WIDTH-1) downto 0);

  signal conflict_detect          : std_logic;
  signal conflict_detect_r        : std_logic;

  signal load_mode_reg            : std_logic_vector((ROW_ADDRESS-1) downto 0);
  signal ext_mode_reg             : std_logic_vector((ROW_ADDRESS-1) downto 0);

  signal cas_latency_value        : std_logic_vector(2 downto 0);
  signal burst_length_value       : std_logic_vector(2 downto 0);
  signal additive_latency_value   : std_logic_vector(2 downto 0);
  signal odt_enable               : std_logic;
  signal registered_dimm          : std_logic;
  signal ecc_value                : std_logic;

  signal wr                       : std_logic;
  signal rd                       : std_logic;
  signal lmr                      : std_logic;
  signal pre                      : std_logic;
  signal ref                      : std_logic;
  signal act                      : std_logic;

  signal wr_r                     : std_logic;
  signal rd_r                     : std_logic;
  signal lmr_r                    : std_logic;
  signal pre_r                    : std_logic;
  signal ref_r                    : std_logic;
  signal act_r                    : std_logic;
  signal af_empty_r               : std_logic;
  signal lmr_pre_ref_act_cmd_r    : std_logic;
  signal cke_200us_cnt            : std_logic_vector(4 downto 0);
  signal done_200us               : std_logic;
  signal dummy_write_state_r      : std_logic;

  signal dummy_write_state        : std_logic;
  signal ctrl_dummy_write         : std_logic;

  signal command_address          : std_logic_vector(2 downto 0);
  signal ctrl_odt                 : std_logic_vector((ODT_WIDTH-1) downto 0);
  signal ctrl_odt_cpy             : std_logic_vector((ODT_WIDTH-1) downto 0);
  signal cs_width0                : std_logic_vector(1 downto 0);
  signal cs_width1                : std_logic_vector(2 downto 0);

  signal s1_h, s2_h, s3_h ,s5_h   : std_logic_vector(3 downto 0);
  signal s4_h                     : std_logic_vector(2 downto 0);
  signal comp_done_r              : std_logic;

  signal ctrl_dqs_rst_r1          : std_logic;
  signal ctrl_dqs_en_r1           : std_logic;
  signal ctrl_wren_r1             : std_logic;
  signal ctrl_wren_r1_i           : std_logic;
  signal ctrl_rden_r1             : std_logic;

  signal ddr2_cs_r_out            : std_logic_vector((CS_WIDTH-1) downto 0);
  signal ddr2_cs_r_out_cpy            : std_logic_vector((CS_WIDTH-1) downto 0);
  signal ddr2_cs_r_odt            : std_logic_vector((CS_WIDTH-1) downto 0);

  signal count6                   : std_logic_vector(6 downto 0);


  signal rst_r1                   : std_logic;

  signal odt_en_single            : std_logic;
  signal ddr2_cs_r_odt_r1         : std_logic_vector((CS_WIDTH-1) downto 0);
  signal ddr2_cs_r_odt_r2         : std_logic_vector((CS_WIDTH-1) downto 0);

  signal dummy_read_state         : std_logic;
  signal ddr_addr_col             : std_logic_vector(ROW_ADDRESS-1 downto 0);

  attribute equivalent_register_removal : string;
  attribute syn_preserve                : boolean;
  attribute equivalent_register_removal of ddr2_cke_r    : signal is "no";
  attribute syn_preserve of ddr2_cke_r                   : signal is true;
  attribute equivalent_register_removal of ddr2_cs_r_odt : signal is "no";
  attribute syn_preserve of ddr2_cs_r_odt                : signal is true;
  attribute equivalent_register_removal of rst_r1        : signal is "no";
  attribute syn_preserve of rst_r1                       : signal is true;

  attribute max_fanout               : string;
  attribute max_fanout of odt_cnt    : signal is "1";
  attribute syn_maxfan of odt_cnt    : signal is 1;
  attribute max_fanout of odt_en_cnt : signal is "1";
  attribute syn_maxfan of odt_en_cnt : signal is 1;
  attribute max_fanout of odt_en     : signal is "1";
  attribute syn_maxfan of odt_en     : signal is 1;

begin

  --***************************************************************************

  --***************************************************************************
  -- Debug output ("dbg_*")
  -- NOTES:
  --  1. All debug outputs coming out of DDR2_CONTROLLER are clocked off CLK0,
  --     although they are also static after calibration is complete. This
  --     means the user can either connect them to a Chipscope ILA, or to
  --     either a sync/async VIO input block. Using an async VIO has the
  --     advantage of not requiring these paths to meet cycle-to-cycle timing.
  -- SIGNAL DESCRIPTION:
  --  1. init_done: 1 bit - asserted if both per bit and pattern calibration
  --                are completed.
  --***************************************************************************

  dbg_init_done <= init_done;

  --*****************************************************************
  -- Mode Register (MR):
  --   [15:14] - unused          - 00
  --   [13]    - reserved        - 0
  --   [12]    - Power-down mode - 0 (normal)
  --   [11:9]  - write recovery  - same value as written to CAS_LATENCY_VALUE
  --   [8]     - DLL reset       - 0 or 1
  --   [7]     - Test Mode       - 0 (normal)
  --   [6:4]   - CAS latency     - CAS_LATENCY_VALUE
  --   [3]     - Burst Type      - BURST_TYPE
  --   [2:0]   - Burst Length    - BURST_LENGTH_VALUE
  --*****************************************************************

  cas_latency_value      <= load_mode_reg(6 downto 4);
  burst_length_value     <= load_mode_reg(2 downto 0);

  --*****************************************************************
  -- Extended Mode Register (MR):
  --   [15:14] - unused          - 00
  --   [13]    - reserved        - 0
  --   [12]    - output enable   - 0 (enabled)
  --   [11]    - RDQS enable     - 0 (disabled)
  --   [10]    - DQS# enable     - 0 (enabled)
  --   [9:7]   - OCD Program     - 111 or 000 (first 111, then 000 during init)
  --   [6]     - RTT[1]          - RTT[1:0] = 0(no ODT), 1(75), 2(150), 3(50)
  --   [5:3]   - Additive CAS    - ADDITIVE_LATENCY_VALUE
  --   [2]     - RTT[0]
  --   [1]     - Output drive    - REDUCE_DRV (= 0(full), = 1 (reduced)
  --   [0]     - DLL enable      - 0 (normal)
  --*****************************************************************

  additive_latency_value <= ext_mode_reg(5 downto 3);
  odt_enable             <= ext_mode_reg(2) or ext_mode_reg(6);

  registered_dimm <= '0';

  burst_length_div2      <= burst_cnt;
  command_address        <= af_addr(34 downto 32);

  ecc_value <= '0';

  -- fifo control signals
  ctrl_af_rden    <= af_rden;
  conflict_detect <= af_addr(35) and ctrl_init_done and (not af_empty);
  cs_width1       <= (('0' & cs_width0) + "001");

  dummy_read_state <= '1' when ((init_state_r2(14) = '1') or
                                (init_state_r2(15) = '1')) else '0';

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      init_done_r <= init_done;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      rst_r1 <= rst;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ctrl_dummy_write <= '1';
      elsif(init_state(20) = '1') then  -- INIT_PATTERN_READ_WAIT
        ctrl_dummy_write <= '0';
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        comp_done_r <= '0';
      else
        comp_done_r <= comp_done;
      end if;
    end if;
  end process;

  ctrl_wdf_rden <= ctrl_wdf_rden_int;

  -- commands
  process(command_address, ctrl_init_done, af_empty)
  begin
    wr  <= '0';
    rd  <= '0';
    lmr <= '0';
    pre <= '0';
    ref <= '0';
    act <= '0';
    if (ctrl_init_done = '1' and af_empty = '0') then

      case command_address is
        when "000"  => lmr <= '1';
        when "001"  => ref <= '1';
        when "010"  => pre <= '1';
        when "011"  => act <= '1';
        when "100"  => wr  <= '1';
        when "101"  => rd  <= '1';
        when others => null;
      end case;

    end if;
  end process;

  -- register address outputs
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        wr_r                  <= '0';
        rd_r                  <= '0';
        lmr_r                 <= '0';
        pre_r                 <= '0';
        ref_r                 <= '0';
        act_r                 <= '0';
        af_empty_r            <= '0';
        lmr_pre_ref_act_cmd_r <= '0';
      else
        wr_r                  <= wr;
        rd_r                  <= rd;
        lmr_r                 <= lmr;
        pre_r                 <= pre;
        ref_r                 <= ref;
        act_r                 <= act;
        af_empty_r            <= af_empty;
        lmr_pre_ref_act_cmd_r <= lmr or pre or ref or act;
      end if;
    end if;
  end process;

  -- register address outputs
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        af_addr_r         <= (others => '0');
        af_addr_r1        <= (others => '0');
        conflict_detect_r <= '0';
      else
        af_addr_r         <= af_addr;
        af_addr_r1        <= af_addr_r;
        conflict_detect_r <= conflict_detect;
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        load_mode_reg <= LOAD_MODE_REGISTER((ROW_ADDRESS-1) downto 0);
      elsif((state(1) = '1') and (lmr_r = '1') and
            (af_addr_r(((BANK_ADDRESS + ROW_ADDRESS + COLUMN_ADDRESS)-1) downto
                       (COLUMN_ADDRESS + ROW_ADDRESS))="00")) then
        load_mode_reg <= af_addr((ROW_ADDRESS-1) downto 0);
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ext_mode_reg <= EXT_LOAD_MODE_REGISTER((ROW_ADDRESS-1) downto 0);
      elsif((state(1) = '1') and (lmr_r = '1') and
            (af_addr_r(((BANK_ADDRESS + ROW_ADDRESS + COLUMN_ADDRESS)-1) downto
                       (COLUMN_ADDRESS + ROW_ADDRESS)) ="01")) then
        ext_mode_reg <= af_addr((ROW_ADDRESS-1) downto 0);
      end if;
    end if;
  end process;

  -- to initialize memory
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if ((rst_r1 = '1') or (init_state(17) = '1')) then
        init_memory <= '1';
      elsif (init_count_cp = "1111") then
        init_memory <= '0';
      else
        init_memory <= init_memory;
      end if;
    end if;
  end process;

  --*****************************************************************
  -- Various delay counters
  --*****************************************************************

  -- mrd count
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        mrd_count <= '0';
      elsif (state(1) = '1') then
        mrd_count <= MRD_COUNT_VALUE;
      elsif (mrd_count /= '0') then
        mrd_count <= '0';
      else
        mrd_count <= '0';
      end if;
    end if;
  end process;

  -- rp count
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        rp_count(2 downto 0) <= "000";
      elsif (state(3) = '1') then
        rp_count(2 downto 0) <= RP_COUNT_VALUE;
      elsif (rp_count(2 downto 0) /= "000") then
        rp_count(2 downto 0) <= rp_count(2 downto 0) - "001";
      else
        rp_count(2 downto 0) <= "000";
      end if;
    end if;
  end process;

  -- rfc count
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        rfc_count <= (others => '0');
      elsif (state(5) = '1') then
        rfc_count <= RFC_COUNT_VALUE;
      elsif (rfc_count /= "00000000") then
        rfc_count <= rfc_count - "00000001";
      else
        rfc_count <= (others => '0');
      end if;
    end if;
  end process;

  --  rcd count - 20ns
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        rcd_count(2 downto 0) <= "000";
      elsif (state(7) = '1') then
        rcd_count(2 downto 0) <= RCD_COUNT_VALUE - additive_latency_value -
                                 "001";
      elsif (rcd_count(2 downto 0) /= "000") then
        rcd_count(2 downto 0) <= rcd_count(2 downto 0) - "001";
      else
        rcd_count(2 downto 0) <= "000";
      end if;
    end if;
  end process;

  -- ras count - active to precharge
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ras_count <= (others => '0');
      elsif (state(7) = '1') then
        ras_count <= RAS_COUNT_VALUE;
      elsif (ras_count(4 downto 1) = "0000") then
        if (ras_count(0) /= '0') then
          ras_count(0) <= '0';
        end if;
      else
        ras_count <= ras_count - "00001";
      end if;
    end if;
  end process;

  -- AL+BL/2+TRTP-2
  -- rtp count - read to precharge
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        rtp_count(3 downto 0) <= "0000";
      elsif ((state(9) = '1') or (state(10) = '1')) then
        rtp_count(3 downto 0) <= (('0' & TRTP_COUNT_VALUE) + ('0' & burst_cnt) +
                                  ('0' & additive_latency_value) -"0010") ;
      elsif (rtp_count(3 downto 1) = "000") then
        if (rtp_count(0) /= '0') then
          rtp_count(0) <= '0';
        end if;
      else
        rtp_count(3 downto 0) <= rtp_count(3 downto 0) - "0001";
      end if;
    end if;
  end process;

  -- WL+BL/2+TWR
  -- wtp count - write to precharge
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        wtp_count(3 downto 0) <= "0000";
      elsif ((state(12) = '1') or (state(13) = '1')) then
        wtp_count(3 downto 0) <= (('0' & TWR_COUNT_VALUE) + ('0' & burst_cnt) +
                                  ('0' & cas_latency_value) +
                                  ('0' & additive_latency_value) -"0011");
      elsif (wtp_count(3 downto 1) = "000") then
        if (wtp_count(0) /= '0') then
          wtp_count(0) <= '0';
        end if;
      else
        wtp_count(3 downto 0) <= wtp_count(3 downto 0) - "0001";
      end if;
    end if;
  end process;

  -- write to read counter
  -- write to read includes : write latency + burst time + tWTR

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        wr_to_rd_count(3 downto 0) <= "0000";
      elsif ((state(12) = '1') or (state(13) = '1')) then
        wr_to_rd_count(3 downto 0) <= (('0' & TWTR_COUNT_VALUE) +
                                       ('0' & burst_cnt) +
                                       ('0' & additive_latency_value) +
                                       ('0' & cas_latency_value) - "0001");
      elsif (wr_to_rd_count(3 downto 0) /= "0000") then
        wr_to_rd_count(3 downto 0) <= wr_to_rd_count(3 downto 0) - "0001";
      else
        wr_to_rd_count(3 downto 0) <= "0000";
      end if;
    end if;
  end process;

  -- read to write counter
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        rd_to_wr_count(3 downto 0) <= "0000";
      elsif ((state(9) = '1') or (state(10) = '1')) then
        rd_to_wr_count(3 downto 0) <= (('0' & cas_latency_value) +
                                       ("0" & additive_latency_value) +
                                       ('0' & burst_cnt) - "0010");
      elsif (rd_to_wr_count(3 downto 0) /= "0000") then
        rd_to_wr_count(3 downto 0) <= rd_to_wr_count(3 downto 0) - "0001";
      else
        rd_to_wr_count(3 downto 0) <= "0000";
      end if;
    end if;
  end process;

  -- auto refresh interval counter in clk0 domain
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        refi_count <= (others => '0');
      elsif (refi_count = MAX_REF_CNT) then
        refi_count <= (others => '0');
      else
        refi_count <= refi_count + ADD_CONST6((MAX_REF_WIDTH-1) downto 0);
      end if;
    end if;
  end process;

  process(refi_count, done_200us)
  begin
    if ((refi_count = MAX_REF_CNT) and (done_200us = '1')) then
      ref_flag <= '1';
    else
      ref_flag <= '0';
    end if;
  end process;

  --***************************************************************************
  -- Initial delay after power-on
  --***************************************************************************

  -- 200us counter for cke
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        cke_200us_cnt <= "11011";
        -- cke_200us_cnt <= "00001";

      elsif (refi_count = MAX_REF_CNT) then
        cke_200us_cnt <= cke_200us_cnt - "00001";
      else
        cke_200us_cnt <= cke_200us_cnt;
      end if;
    end if;
  end process;

  -- refresh detect
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ref_flag_0   <= '0';
        ref_flag_0_r <= '0';
        done_200us     <= '0';
      else
        ref_flag_0   <= ref_flag;
        ref_flag_0_r <= ref_flag_0;
        if (done_200us = '0') then
          if (cke_200us_cnt = "00000") then
            done_200us <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

  -- refresh flag detect
  -- auto_ref high indicates auto_refresh requirement
  -- auto_ref is held high until auto refresh command is issued.

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        auto_ref <= '0';
      elsif (ref_flag_0 = '1' and ref_flag_0_r = '0') then
        auto_ref <= '1';
      elsif (state(5) = '1') then
        auto_ref <= '0';
      else
        auto_ref <= auto_ref;
      end if;
    end if;
  end process;

  -- 200 clocks counter - count value : C8
  -- required for initialization
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        count_200_cycle(7 downto 0) <= "00000000";
      elsif (init_state(7) = '1') then
        count_200_cycle(7 downto 0) <= X"C8";
      elsif (count_200_cycle(7 downto 0) /= "00000000") then
        count_200_cycle(7 downto 0) <= count_200_cycle(7 downto 0) - "00000001";
      else
        count_200_cycle(7 downto 0) <= "00000000";
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        count_200cycle_done_r <= '0';
      elsif ((init_memory = '1') and (count_200_cycle = "00000000")) then
        count_200cycle_done_r <= '1';
      else
        count_200cycle_done_r <= '0';
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        init_done <= '0';
      elsif ((init_count_cp = "1101") and (count_200cycle_done_r = '1') and
             (PHY_MODE = '0'))then
        init_done <= '1';
      --  Precharge fix after pattern read
      -- 2.1: Main controller state machine should start after
      -- initialization state machine completed.
      elsif ((PHY_MODE = '1') and (comp_done_r = '1') and
             (init_state_r2(0) = '1')) then
        init_done <= '1';
      else
        init_done <= init_done;
      end if;
    end if;
  end process;

  --synthesis translate_off
  process(init_done)
  begin
    if (init_done = '1' and init_done'event) then
      report "Calibration completed at time " & time'image(now);
    end if;
  end process;
  --synthesis translate_on

  ctrl_init_done <= init_done;

  process(burst_length_value)
  begin
    if (burst_length_value = "010") then
      burst_cnt <= "010";
    elsif (burst_length_value = "011") then
      burst_cnt <= "100";
    else
      burst_cnt <= "000";
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if ((rst_r1 = '1') or (init_state(17) = '1'))then
        init_count(3 downto 0) <= "0000";
      elsif (init_memory = '1') then
        if (init_state(1) = '1' or init_state(3) = '1' or init_state(5) = '1' or
            init_state(9) = '1' or init_state(7) = '1' or init_state(17) = '1'
            or init_state(18) = '1'or init_state(12) = '1') then
          init_count(3 downto 0) <= init_count(3 downto 0) + "0001";
        elsif(init_count = "1111") then
          init_count(3 downto 0) <= "0000";
        else
          init_count(3 downto 0) <= init_count(3 downto 0);
        end if;
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if ((rst_r1 = '1') or (init_state(17) = '1')) then
        init_count_cp(3 downto 0) <= "0000";
      elsif (init_memory = '1') then
        if (init_state(1) = '1' or init_state(3) = '1' or init_state(5) = '1' or
            init_state(9) = '1' or init_state(7) = '1' or init_state(17) = '1'
            or init_state(18) = '1' or init_state(12) = '1') then
          init_count_cp(3 downto 0) <= init_count_cp(3 downto 0) + "0001";
        elsif(init_count_cp = "1111") then
          init_count_cp(3 downto 0) <= "0000";
        else
          init_count_cp(3 downto 0) <= init_count_cp(3 downto 0);
        end if;
      end if;
    end if;
  end process;

  --*****************************************************************
  -- handle deep memory configuration:
  --   During initialization: Repeat initialization sequence once for each
  --   chip select.
  --   Once initialization complete, assert only Last chip for calibration.
  --*****************************************************************

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        chip_cnt <= "00";
      elsif (init_state(17) = '1') then
        chip_cnt <= chip_cnt + "01";
      else
        chip_cnt <= chip_cnt;
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1' or state(3) = '1') then
        auto_cnt <= "000";
      elsif (state(5) = '1' and init_memory = '0') then
        auto_cnt <= auto_cnt + "001";
      else
        auto_cnt <= auto_cnt;
      end if;
    end if;
  end process;

  --  Precharge fix for deep memory
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1' or state(5) = '1') then
        pre_cnt <= "000";
      elsif (state(3) = '1' and init_memory = '0' and
             (auto_ref = '1' or ref_r = '1')) then
        pre_cnt <= pre_cnt + "001";
      else
        pre_cnt <= pre_cnt;
      end if;
    end if;
  end process;

  -- write burst count
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        wrburst_cnt(2 downto 0) <= "000";
      elsif (state(12) = '1' or state(13) = '1' or init_state(18) = '1' or
             init_state(12) = '1') then
        wrburst_cnt(2 downto 0) <= burst_cnt(2 downto 0);
      elsif (wrburst_cnt(2 downto 0) /= "000") then
        wrburst_cnt(2 downto 0) <= wrburst_cnt(2 downto 0) - "001";
      else
        wrburst_cnt(2 downto 0) <= "000";
      end if;
    end if;
  end process;

  -- read burst count for state machine
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        read_burst_cnt(2 downto 0) <= "000";
      elsif (state(9) = '1' or state(10) = '1') then
        read_burst_cnt(2 downto 0) <= burst_cnt(2 downto 0);
      elsif (read_burst_cnt(2 downto 0) /= "000") then
        read_burst_cnt(2 downto 0) <= read_burst_cnt(2 downto 0) - "001";
      else
        read_burst_cnt(2 downto 0) <= "000";
      end if;
    end if;
  end process;

  -- count to generate write enable to the data path
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ctrl_wren_cnt(2 downto 0) <= "000";
      elsif (wdf_rden_r = '1' or dummy_write_state_r = '1') then
        ctrl_wren_cnt(2 downto 0) <= burst_cnt(2 downto 0);
      elsif (ctrl_wren_cnt(2 downto 0) /= "000") then
        ctrl_wren_cnt(2 downto 0) <= ctrl_wren_cnt(2 downto 0)- "001";
      else
        ctrl_wren_cnt(2 downto 0) <= "000";
      end if;
    end if;
  end process;

  -- write enable to data path
  process(ctrl_wren_cnt)
  begin
    if (ctrl_wren_cnt(2 downto 0) /= "000") then
      ctrl_write_en <= '1';
    else
      ctrl_write_en <= '0';
    end if;
  end process;

  -- 3-state enable for the data I/O generated such that to enable
  -- write data output one-half clock cycle before
  -- the first data word, and disable the write data
  -- one-half clock cycle after the last data word

  -- write enable to data path
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      ctrl_write_en_r1 <= ctrl_write_en;
      ctrl_write_en_r2 <= ctrl_write_en_r1;
      ctrl_write_en_r3 <= ctrl_write_en_r2;
      ctrl_write_en_r4 <= ctrl_write_en_r3;
      ctrl_write_en_r5 <= ctrl_write_en_r4;
      ctrl_write_en_r6 <= ctrl_write_en_r5;
    end if;
  end process;

  -- internal signal to calculate the value of expression used in CASE
  s1_h <= (('0' & additive_latency_value) + ('0' & cas_latency_value) +
           ("000" & registered_dimm) + ("000" & ecc_value)) - "0001";

  ctrl_wren_r1 <= ctrl_write_en when (s1_h = "0010") else ctrl_wren_r1_i;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      case s1_h is
        when "0011" => ctrl_wren_r1_i <= ctrl_write_en;
        when "0100" => ctrl_wren_r1_i <= ctrl_write_en_r1;
        when "0101" => ctrl_wren_r1_i <= ctrl_write_en_r2;
        when "0110" => ctrl_wren_r1_i <= ctrl_write_en_r3;
        when "0111" => ctrl_wren_r1_i <= ctrl_write_en_r4;
        when "1000" => ctrl_wren_r1_i <= ctrl_write_en_r5;
        when "1001" => ctrl_wren_r1_i <= ctrl_write_en_r6;
        when others => ctrl_wren_r1_i <= '0';
      end case;
    end if;
  end process;

  -- DQS enable to data path

  process(state, init_state)
  begin
    if (state(12) = '1' or init_state(18) = '1' or init_state(12) = '1') then
      dqs_reset <= '1';
    else
      dqs_reset <= '0';
    end if;
  end process;

  s2_h <= (('0' & additive_latency_value) + ('0' & cas_latency_value) +
           ("000" & registered_dimm)+ ("000" & ecc_value));

  process(clk0)
  begin

    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ctrl_dqs_rst_r1 <= '0';
        dqs_reset_r1    <= '0';
        dqs_reset_r2    <= '0';
        dqs_reset_r3    <= '0';
        dqs_reset_r4    <= '0';
        dqs_reset_r5    <= '0';
        dqs_reset_r6    <= '0';
      else
        dqs_reset_r1 <= dqs_reset;
        dqs_reset_r2 <= dqs_reset_r1;
        dqs_reset_r3 <= dqs_reset_r2;
        dqs_reset_r4 <= dqs_reset_r3;
        dqs_reset_r5 <= dqs_reset_r4;
        dqs_reset_r6 <= dqs_reset_r5;

        case s2_h is

          when "0011" => ctrl_dqs_rst_r1 <= dqs_reset;
          when "0100" => ctrl_dqs_rst_r1 <= dqs_reset_r1;
          when "0101" => ctrl_dqs_rst_r1 <= dqs_reset_r2;
          when "0110" => ctrl_dqs_rst_r1 <= dqs_reset_r3;
          when "0111" => ctrl_dqs_rst_r1 <= dqs_reset_r4;
          when "1000" => ctrl_dqs_rst_r1 <= dqs_reset_r5;
          when "1001" => ctrl_dqs_rst_r1 <= dqs_reset_r6;
          when others => ctrl_dqs_rst_r1 <= '0';

        end case;
      end if;
    end if;
  end process;

  process(state , init_state, wrburst_cnt)
  begin
    if ((state(12) = '1') or (state(13) = '1') or (init_state(18) = '1') or
        (init_state(12) = '1') or (wrburst_cnt /= "000")) then
      dqs_en <= '1';
    else
      dqs_en <= '0';
    end if;
  end process;

  s3_h <= (('0' & additive_latency_value) + ('0' & cas_latency_value) +
           ("000" & registered_dimm) + ("000" & ecc_value));

  process(clk0)
  begin

    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ctrl_dqs_en_r1 <= '0';
        dqs_en_r1      <= '0';
        dqs_en_r2      <= '0';
        dqs_en_r3      <= '0';
        dqs_en_r4      <= '0';
        dqs_en_r5      <= '0';
        dqs_en_r6      <= '0';
      else
        dqs_en_r1 <= dqs_en;
        dqs_en_r2 <= dqs_en_r1;
        dqs_en_r3 <= dqs_en_r2;
        dqs_en_r4 <= dqs_en_r3;
        dqs_en_r5 <= dqs_en_r4;
        dqs_en_r6 <= dqs_en_r5;

        case s3_h is

          when "0011" => ctrl_dqs_en_r1 <= dqs_en;
          when "0100" => ctrl_dqs_en_r1 <= dqs_en_r1;
          when "0101" => ctrl_dqs_en_r1 <= dqs_en_r2;
          when "0110" => ctrl_dqs_en_r1 <= dqs_en_r3;
          when "0111" => ctrl_dqs_en_r1 <= dqs_en_r4;
          when "1000" => ctrl_dqs_en_r1 <= dqs_en_r5;
          when "1001" => ctrl_dqs_en_r1 <= dqs_en_r6;
          when others => ctrl_dqs_en_r1 <= '0';
        end case;

      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      odt_en_single <= dqs_en or dqs_en_r1 or dqs_en_r2 or dqs_en_r3 or
                       dqs_en_r4 or dqs_en_r5;
    end if;
  end process;

  -- cas count
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        cas_count(2 downto 0) <= "000";
      elsif (init_state(16) = '1') then
        cas_count(2 downto 0) <= cas_latency_value + ("00" & registered_dimm);
      elsif (cas_count(2 downto 0) /= "000") then
        cas_count(2 downto 0) <= cas_count(2 downto 0) - "001";
      else
        cas_count(2 downto 0) <= "000";
      end if;
    end if;
  end process;

  -- dummy_read enable
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        dummy_read_en <= '0';
      elsif (init_state(14) = '1') then
        dummy_read_en <= '1';
      elsif (phy_dly_slct_done = '1') then
        dummy_read_en <= '0';
      else
        dummy_read_en <= dummy_read_en;
      end if;
    end if;
  end process;

  -- ctrl_dummyread_start signal generation to the data path module
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ctrl_dummyread_start_r1 <= '0';
      elsif ((dummy_read_en = '1') and (cas_count = "000")) then
        ctrl_dummyread_start_r1 <= '1';
      elsif (phy_dly_slct_done = '1') then
        ctrl_dummyread_start_r1 <= '0';
      else
        ctrl_dummyread_start_r1 <= ctrl_dummyread_start_r1;
      end if;
    end if;
  end process;

  -- register ctrl_dummyread_start signal
  -- To account ECC and Aditive latency, it is registered.
  -- Counter cas_count considers CAS Latency and RDIMM.
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ctrl_dummyread_start_r2 <= '0';
        ctrl_dummyread_start_r3 <= '0';
        ctrl_dummyread_start_r4 <= '0';
        ctrl_dummyread_start_r5 <= '0';
        ctrl_dummyread_start_r6 <= '0';
        ctrl_dummyread_start_r7 <= '0';
        ctrl_dummyread_start_r8 <= '0';
        ctrl_dummyread_start_r9 <= '0';
        ctrl_dummyread_start    <= '0';
        ctrl_dummyread_start    <= '0';
      else
        ctrl_dummyread_start_r2 <= ctrl_dummyread_start_r1;
        ctrl_dummyread_start_r3 <= ctrl_dummyread_start_r2;
        ctrl_dummyread_start_r4 <= ctrl_dummyread_start_r3;
        ctrl_dummyread_start_r5 <= ctrl_dummyread_start_r4;
        ctrl_dummyread_start_r6 <= ctrl_dummyread_start_r5;
        ctrl_dummyread_start_r7 <= ctrl_dummyread_start_r6;
        ctrl_dummyread_start_r8 <= ctrl_dummyread_start_r7;
        ctrl_dummyread_start_r9 <= ctrl_dummyread_start_r8;
        ctrl_dummyread_start    <= ctrl_dummyread_start_r9;
      end if;
    end if;
  end process;

  -- read_wait/write_wait to idle count
  -- the state machine waits for 15 clock cycles in the write wait state for any
  -- wr/rd commands to be issued. If no commands are issued in 15 clock cycles,
  -- the statemachine issues enters the idle state and stays in the idle state
  -- until an auto refresh is required.

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        idle_cnt(3 downto 0) <= "0000";
      elsif (state(9) = '1' or state(12) = '1' or state(10) = '1' or
             state(13) = '1') then
        idle_cnt(3 downto 0) <= "1111";
      elsif (idle_cnt(3 downto 0) /= "0000") then
        idle_cnt(3 downto 0) <= idle_cnt(3 downto 0) - "0001";
      else
        idle_cnt(3 downto 0) <= "0000";
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        cas_check_count(3 downto 0) <= "0000";
      elsif ((state_r2(9) = '1') or (init_state_r2(20) = '1')) then
        cas_check_count(3 downto 0) <= (('0' & CAS_LATENCY_VALUE) - "0001");
      elsif (cas_check_count(3 downto 0) /= "0000") then
        cas_check_count(3 downto 0) <= cas_check_count(3 downto 0) - "0001";
      else
        cas_check_count(3 downto 0) <= "0000";
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        rdburst_cnt(3 downto 0) <= "0000";
      elsif(state_r3(10) = '1') then
        if(burst_cnt(2) = '1') then
          rdburst_cnt(3 downto 0) <= ((burst_cnt(2 downto 0) & '0') -
                                      ("0111" - ('0' & cas_latency_value)));
        else
          rdburst_cnt(3 downto 0) <= ((burst_cnt(2 downto 0) & '0') -
                                      ("0101" - ('0' & cas_latency_value)));
        end if;
      elsif (cas_check_count = "0010") then
        rdburst_cnt(3 downto 0) <= ('0' & burst_cnt(2 downto 0));
      elsif (rdburst_cnt(3 downto 0) /= "0000") then
        rdburst_cnt(3 downto 0) <= rdburst_cnt(3 downto 0) - "0001";
      else
        rdburst_cnt(3 downto 0) <= "0000";
      end if;
    end if;
  end process;

  -- read enable to data path
  process(rdburst_cnt)
  begin
    if (rdburst_cnt = "0000") then
      ctrl_read_en <= '0';
    else
      ctrl_read_en <= '1';
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ctrl_read_en_r  <= '0';
        ctrl_read_en_r1 <= '0';
        ctrl_read_en_r2 <= '0';
        ctrl_read_en_r3 <= '0';
        ctrl_read_en_r4 <= '0';
      else
        ctrl_read_en_r  <= ctrl_read_en;
        ctrl_read_en_r1 <= ctrl_read_en_r;
        ctrl_read_en_r2 <= ctrl_read_en_r1;
        ctrl_read_en_r3 <= ctrl_read_en_r2;
        ctrl_read_en_r4 <= ctrl_read_en_r3;
      end if;
    end if;
  end process;

  s4_h <= (additive_latency_value + ("00" & ecc_value) +
           ("00" & registered_dimm));

  process(clk0)
  begin

    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ctrl_RdEn_r1 <= '0';
      else
        case s4_h is
          when "000"  => ctrl_rden_r1 <= ctrl_read_en;
          when "001"  => ctrl_rden_r1 <= ctrl_read_en_r;
          when "010"  => ctrl_rden_r1 <= ctrl_read_en_r1;
          when "011"  => ctrl_rden_r1 <= ctrl_read_en_r2;
          when "100"  => ctrl_rden_r1 <= ctrl_read_en_r3;
          when others => ctrl_rden_r1 <= '0';
        end case;
      end if;  -- else: !if(rst_r1)
    end if;
  end process;

  -- write address FIFO read enable signals

  af_rden <= '1' when ((state(12) = '1') or (state(9) = '1') or
                       (state(13) = '1') or (state(10) = '1') or
                       ((state(2) = '1') and (lmr_r = '1') and
                        (mrd_count = '0')) or
                       ((state(3) = '1') and (pre_r = '1')) or
                       ((state(5) = '1') and (ref_r = '1')) or
                       ((state(7) = '1') and (act_r = '1'))) else '0';

  -- write data fifo read enable
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        wdf_rden_r <= '0';
      elsif ((state(12) = '1') or (state(13) = '1') or (init_state(18) = '1') or
             (init_state(12) = '1')) then
        wdf_rden_r <= '1';
      else
        wdf_rden_r <= '0';
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        wdf_rden_r2 <= '0';
        wdf_rden_r3 <= '0';
        wdf_rden_r4 <= '0';
      else
        wdf_rden_r2 <= wdf_rden_r;
        wdf_rden_r3 <= wdf_rden_r2;
        wdf_rden_r4 <= wdf_rden_r3;
      end if;  --else: !if(rst_r1)
    end if;
  end process;

  -- Read enable to the data fifo

  process(burst_cnt, wdf_rden_r, wdf_rden_r2, wdf_rden_r3, wdf_rden_r4)
  begin
    if (burst_cnt = "010") then
      ctrl_wdf_read_en <= (wdf_rden_r or wdf_rden_r2);
    elsif (burst_cnt = "100") then
      ctrl_wdf_read_en <= (wdf_rden_r or wdf_rden_r2 or
                           wdf_rden_r3 or wdf_rden_r4);
    else
      ctrl_wdf_read_en <= '0';
    end if;
  end process;

  s5_h <= (('0' & additive_latency_value) + ('0' & cas_latency_value) +
           ("000" & registered_dimm));

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ctrl_wdf_rden_int   <= '0';
        ctrl_wdf_read_en_r1 <= '0';
        ctrl_wdf_read_en_r2 <= '0';
        ctrl_wdf_read_en_r3 <= '0';
        ctrl_wdf_read_en_r4 <= '0';
        ctrl_wdf_read_en_r5 <= '0';
        ctrl_wdf_read_en_r6 <= '0';
      else
        ctrl_wdf_read_en_r1 <= ctrl_wdf_read_en;
        ctrl_wdf_read_en_r2 <= ctrl_wdf_read_en_r1;
        ctrl_wdf_read_en_r3 <= ctrl_wdf_read_en_r2;
        ctrl_wdf_read_en_r4 <= ctrl_wdf_read_en_r3;
        ctrl_wdf_read_en_r5 <= ctrl_wdf_read_en_r4;
        ctrl_wdf_read_en_r6 <= ctrl_wdf_read_en_r5;
        case s5_h is
          when "0011" => ctrl_wdf_rden_int <= ctrl_wdf_read_en;
          when "0100" => ctrl_wdf_rden_int <= ctrl_wdf_read_en_r1;
          when "0101" => ctrl_wdf_rden_int <= ctrl_wdf_read_en_r2;
          when "0110" => ctrl_wdf_rden_int <= ctrl_wdf_read_en_r3;
          when "0111" => ctrl_wdf_rden_int <= ctrl_wdf_read_en_r4;
          when "1000" => ctrl_wdf_rden_int <= ctrl_wdf_read_en_r5;
          when "1001" => ctrl_wdf_rden_int <= ctrl_wdf_read_en_r6;
          when others => ctrl_wdf_rden_int <= '0';
        end case;
      end if;  -- else: !if(rst_r1)
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        count6 <= "0000000";
      elsif((init_state(4) = '1') or (init_state(2) = '1') or
            (init_state(6) = '1') or (init_state(19) = '1') or
            (init_state(13) = '1') or (init_state(21) = '1') or
            (init_state(15) = '1') or (init_state(11) = '1')) then
        count6 <= count6 + "0000001";
      else
        count6 <= "0000000";
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        init_state <= INIT_IDLE;
      else
        init_state <= init_next_state;
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        state <= IDLE;
      else
        state <= next_state;
      end if;
    end if;
  end process;

  dummy_write_state <= '1' when ((init_state(18) = '1') or
                                 (init_state(12) = '1')) else '0';

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        dummy_write_state_r <= '0';
      else
        dummy_write_state_r <= dummy_write_state;
      end if;
    end if;
  end process;

  cs_width0 <= "00" when CS_WIDTH = 1 else
               "01" when CS_WIDTH = 2 else
               "10" when CS_WIDTH = 3 else
               "11" when CS_WIDTH = 4;

  --***************************************************************************
  -- Initialization state machine
  --***************************************************************************

  process(chip_cnt, count_200cycle_done_r, init_count, init_memory,
          phy_dly_slct_done, init_state, done_200us, cs_width0,
          comp_done_r, count6, cal_first_loop)
  begin
    init_next_state <= init_state;
    case init_state is
      when INIT_IDLE =>
        if (init_memory = '1' and done_200us = '1') then
          case init_count is            -- synthesis parallel_case full_case

            when "0000" =>
              init_next_state <= INIT_COUNT_200;

            when "0001" =>
              if (count_200cycle_done_r = '1') then
                init_next_state <= INIT_PRECHARGE;
              else
                init_next_state <= INIT_IDLE;
              end if;

            when "0010" =>
              init_next_state <= INIT_LOAD_MODE;  -- emr(2)

            when "0011" =>
              init_next_state <= INIT_LOAD_MODE;  -- emr(3)

            when "0100" =>
              init_next_state <= INIT_LOAD_MODE;  -- emr

            when "0101" =>
              init_next_state <= INIT_LOAD_MODE;  -- lmr

            when "0110" =>
              init_next_state <= INIT_PRECHARGE;

            when "0111" =>
              init_next_state <= INIT_AUTO_REFRESH;

            when "1000" =>
              init_next_state <= INIT_AUTO_REFRESH;

            when "1001" =>
              init_next_state <= INIT_LOAD_MODE;

            when "1010" =>              -- EMR OCD DEFAULT
              init_next_state <= INIT_LOAD_MODE;

            when "1011" =>              -- EMR OCD EXIT
              init_next_state <= INIT_LOAD_MODE;

            when "1100" =>
              init_next_state <= INIT_COUNT_200;

            when "1101" =>
              if (chip_cnt < cs_width0) then
                init_next_state <= INIT_DEEP_MEMORY_ST;
              elsif (PHY_MODE = '1' and count_200cycle_done_r = '1') then
                init_next_state <= INIT_DUMMY_READ_CYCLES;
              else
                init_next_state <= INIT_IDLE;
              end if;

            when "1110" =>
              if (phy_dly_slct_done = '1') then
                init_next_state <= INIT_PRECHARGE;
              else
                init_next_state <= INIT_IDLE;
              end if;

            when "1111" =>
              if (comp_done_r = '1') then
                init_next_state <= INIT_IDLE;
              end if;

            when others => init_next_state <= INIT_IDLE;

          end case;  -- case(init_count)

        end if;  -- case: INIT_IDLE

      when INIT_DEEP_MEMORY_ST =>
        init_next_state <= INIT_IDLE;

      when INIT_COUNT_200 =>
        init_next_state <= INIT_COUNT_200_WAIT;

      when INIT_COUNT_200_WAIT =>
        if (count_200cycle_done_r = '1') then
          init_next_state <= INIT_IDLE;
        else
          init_next_state <= INIT_COUNT_200_WAIT;
        end if;

      when INIT_DUMMY_READ_CYCLES =>
        init_next_state <= INIT_DUMMY_ACTIVE;

      when INIT_DUMMY_ACTIVE =>
        init_next_state <= INIT_DUMMY_ACTIVE_WAIT;

      when INIT_DUMMY_ACTIVE_WAIT =>
        if (count6 = CNTNEXT) then
          init_next_state <= INIT_DUMMY_WRITE;
        else
          init_next_state <= INIT_DUMMY_ACTIVE_WAIT;
        end if;

      when INIT_DUMMY_WRITE =>
        init_next_state <= INIT_DUMMY_WRITE_READ;

      when INIT_DUMMY_WRITE_READ =>
        if(count6 = CNTNEXT) then
          init_next_state <= INIT_DUMMY_FIRST_READ;
        else
          init_next_state <= INIT_DUMMY_WRITE_READ;
        end if;

      when INIT_DUMMY_FIRST_READ =>
        init_next_state <= INIT_DUMMY_READ_WAIT;

      when INIT_DUMMY_READ =>
        init_next_state <= INIT_DUMMY_READ_WAIT;

      when INIT_DUMMY_READ_WAIT =>
        if (phy_dly_slct_done = '1') then
          if(count6 = CNTNEXT) then
            init_next_state <= INIT_PATTERN_WRITE;
          else
            init_next_state <= INIT_DUMMY_READ_WAIT;
          end if;
        else
          init_next_state <= INIT_DUMMY_READ;
        end if;

      when INIT_PRECHARGE =>
        init_next_state <= INIT_PRECHARGE_WAIT;

      when INIT_PRECHARGE_WAIT =>
        if (count6 = CNTNEXT) then
          init_next_state <= INIT_IDLE;
        else
          init_next_state <= INIT_PRECHARGE_WAIT;
        end if;

      when INIT_LOAD_MODE =>
        init_next_state <= INIT_MODE_REGISTER_WAIT;

      when INIT_MODE_REGISTER_WAIT =>
        if (count6 = CNTNEXT) then
          init_next_state <= INIT_IDLE;
        else
          init_next_state <= INIT_MODE_REGISTER_WAIT;
        end if;

      when INIT_AUTO_REFRESH =>
        init_next_state <= INIT_AUTO_REFRESH_WAIT;

      when INIT_AUTO_REFRESH_WAIT =>
        if (count6 = CNTNEXT) then
          init_next_state <= INIT_IDLE;
        else
          init_next_state <= INIT_AUTO_REFRESH_WAIT;
        end if;

      when INIT_PATTERN_WRITE =>
        init_next_state <= INIT_PATTERN_WRITE_READ;

      when INIT_PATTERN_WRITE_READ =>
        if (count6 = CNTNEXT) then
          init_next_state <= INIT_PATTERN_READ;
        else
          init_next_state <= INIT_PATTERN_WRITE_READ;
        end if;

      when INIT_PATTERN_READ =>
        init_next_state <= INIT_PATTERN_READ_WAIT;

      when INIT_PATTERN_READ_WAIT =>
        -- Precharge fix after pattern read
        if (comp_done_r = '1') then
          init_next_state <= INIT_PRECHARGE;
        -- Controller issues a second pattern calibration read
            -- if the first one does not result in a successful calibration
        elsif((not(cal_first_loop)) = '1') then
          init_next_state <= INIT_PATTERN_READ;
        else
          init_next_state <= INIT_PATTERN_READ_WAIT;
        end if;

      when others => init_next_state <= INIT_IDLE;

    end case;
  end process;

  --***************************************************************************
  -- main control state machine
  --***************************************************************************

  process(rd, rd_r, wr, wr_r, lmr_r, act_r, ref_r,
          auto_ref, auto_cnt, conflict_detect, conflict_detect_r,
          conflict_resolved_r, idle_cnt, init_memory, mrd_count,
          lmr_pre_ref_act_cmd_r, ras_count, rcd_count, rd_to_wr_count,
          read_burst_cnt, rfc_count, rp_count, rtp_count, pre_cnt,
          state, wr_to_rd_count, wrburst_cnt, wtp_count, cs_width1,
          init_done, af_empty_r)
  begin
    next_state <= state;
    case state is

      when IDLE =>
        if ((conflict_detect_r = '1' or lmr_pre_ref_act_cmd_r = '1' or
             auto_ref = '1') and ras_count = "00000" and init_done = '1') then
          next_state <= PRECHARGE;
        elsif ((wr_r = '1' or rd_r = '1') and (ras_count = "00000")) then
          next_state <= ACTIVE;
        end if;

      when PRECHARGE =>
        next_state <= PRECHARGE_WAIT;

      --  Precharge fix for deep memory
      when PRECHARGE_WAIT =>
        if (rp_count = "000") then
          if (auto_ref = '1' or ref_r = '1') then
            if ((pre_cnt < cs_width1) and init_memory = '0')then
              next_state <= PRECHARGE;
            else
              next_state <= AUTO_REFRESH;
            end if;
          elsif (lmr_r = '1') then
            next_state <= LOAD_MODE;
          elsif (conflict_detect_r = '1' or act_r = '1') then
            next_state <= ACTIVE;
          else
            next_state <= IDLE;
          end if;
        else
          next_state <= PRECHARGE_WAIT;
        end if;

      when LOAD_MODE =>
        next_state <= MODE_REGISTER_WAIT;

      when MODE_REGISTER_WAIT =>
        if (mrd_count = '0') then
          next_state <= IDLE;
        else
          next_state <= MODE_REGISTER_WAIT;
        end if;

      when AUTO_REFRESH =>
        next_state <= AUTO_REFRESH_WAIT;

      when AUTO_REFRESH_WAIT =>
        if ((auto_cnt < cs_width1) and rfc_count = "00000001" and
            init_memory = '0')then
          next_state <= AUTO_REFRESH;
        elsif ((rfc_count = "00000001") and (conflict_detect_r = '1')) then
          next_state <= ACTIVE;
        elsif (rfc_count = "00000001") then
          next_state <= IDLE;
        else
          next_state <= AUTO_REFRESH_WAIT;
        end if;

      when ACTIVE =>
        next_state <= ACTIVE_WAIT;

      when ACTIVE_WAIT =>
        if (rcd_count = "000") then  -- first active or when a new row is opened
          if (wr = '1') then
            next_state <= FIRST_WRITE;
          elsif (rd = '1') then
            next_state <= FIRST_READ;
          else
            next_state <= IDLE;
          end if;
        else
          next_state <= ACTIVE_WAIT;
        end if;

      when FIRST_WRITE =>
        next_state <= WRITE_WAIT;

      when BURST_WRITE =>
        next_state <= WRITE_WAIT;

      when WRITE_WAIT =>
        if (((conflict_detect = '1') and (conflict_resolved_r = '0')) or
            (auto_ref = '1')) then
          if ((wtp_count = "0000") and (ras_count = "00000")) then
            next_state <= PRECHARGE;
          else
            next_state <= WRITE_WAIT;
          end if;
        elsif (rd = '1') then
          next_state <= WRITE_READ;
        elsif ((wr = '1') and (wrburst_cnt = "010")) then
          next_state <= BURST_WRITE;
        elsif ((wr = '1') and (wrburst_cnt = "000")) then -- added to improve the efficiency
          next_state <= FIRST_WRITE;
        elsif (idle_cnt = "0000") then
          next_state <= PRECHARGE;
        else
          next_state <= WRITE_WAIT;
        end if;

      when WRITE_READ =>
        if (wr_to_rd_count = "0000") then
          next_state <= FIRST_READ;
        else
          next_state <= WRITE_READ;
        end if;

      when FIRST_READ =>
        next_state <= READ_WAIT;

      when BURST_READ =>
        next_state <= READ_WAIT;

      when READ_WAIT =>
        if (((conflict_detect = '1') and (conflict_resolved_r = '0'))
            or (auto_ref = '1')) then
          if(rtp_count = "0000" and ras_count = "00000") then
            next_state <= PRECHARGE;
          else
            next_state <= READ_WAIT;
          end if;
        elsif (wr = '1')then
          next_state <= READ_WRITE;
        elsif ((rd = '1') and (read_burst_cnt <= "010")) then
          if(af_empty_r = '1') then
            next_state <= FIRST_READ;
          else
            next_state <= BURST_READ;
          end if;
        elsif (idle_cnt = "0000") then
          next_state <= PRECHARGE;
        else
          next_state <= READ_WAIT;
        end if;

      when READ_WRITE =>
        if (rd_to_wr_count = "0000") then
          next_state <= FIRST_WRITE;
        else
          next_state <= READ_WRITE;
        end if;

      when others => next_state <= IDLE;

    end case;
  end process;

  -- register command outputs
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      state_r2      <= state;
      state_r3      <= state_r2;
      init_state_r2 <= init_state;
    end if;
  end process;

  --***************************************************************************
  -- Memory control/address
  --***************************************************************************

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ddr2_ras_r <= '1';
      elsif (state(1) = '1' or state(3) = '1' or state(7) = '1' or
             state(5) = '1' or init_state(1) = '1' or init_state(3) = '1' or
             init_state(5) = '1' or init_state(10) = '1') then
        ddr2_ras_r <= '0';
      else
        ddr2_ras_r <= '1';
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ddr2_cas_r <= '1';
      elsif (state(1) = '1' or state(12) = '1' or state(13) = '1' or
             state(9) = '1' or state(10) = '1' or state(5) = '1' or
             init_state(16) = '1' or init_state(1) = '1' or
             init_state(5) = '1' or  init_state(14) = '1' or
             init_state(20) = '1' or init_state(18) = '1' or
             init_state(12) = '1') then
        ddr2_cas_r <= '0';
      else
        ddr2_cas_r <= '1';
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ddr2_we_r <= '1';
      elsif (state(1) = '1' or state(3) = '1' or state(12) = '1' or
             state(13) = '1' or init_state(18) = '1' or init_state(12) = '1' or
             init_state(1) = '1' or init_state(3) = '1') then
        ddr2_we_r <= '0';
      else
        ddr2_we_r <= '1';
      end if;
    end if;
  end process;

  -- register commands to the memory
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ddr2_ras_r2 <= '1';
        ddr2_cas_r2 <= '1';
        ddr2_we_r2  <= '1';
      else
        ddr2_ras_r2 <= ddr2_ras_r;
        ddr2_cas_r2 <= ddr2_cas_r;
        ddr2_we_r2  <= ddr2_we_r;
      end if;
    end if;
  end process;

  -- register commands to the memory
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ddr2_ras_r3 <= '1';
        ddr2_cas_r3 <= '1';
        ddr2_we_r3  <= '1';
      else
        ddr2_ras_r3 <= ddr2_ras_r2;
        ddr2_cas_r3 <= ddr2_cas_r2;
        ddr2_we_r3  <= ddr2_we_r2;
      end if;  -- else: !if(rst_r1)
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        row_addr_r <= (others => '0');
      else
        row_addr_r <= af_addr(((ROW_ADDRESS + COLUMN_ADDRESS)-1)
                              downto COLUMN_ADDRESS);
      end if;
    end if;
  end process;

  -- chip enable generation logic
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ddr2_cs_r((CS_WIDTH-1) downto 0) <= (others => '0');
      else
        if (af_addr_r((CHIP_ADDRESS + BANK_ADDRESS +ROW_ADDRESS + (COLUMN_ADDRESS-1)) downto
                      (BANK_ADDRESS + ROW_ADDRESS + COLUMN_ADDRESS)) =  CS_H0((CHIP_ADDRESS - 1) downto 0)) then
          ddr2_cs_r((CS_WIDTH-1) downto 0) <= CS_HE((CS_WIDTH-1) downto 0);
        elsif (af_addr_r((CHIP_ADDRESS + BANK_ADDRESS + ROW_ADDRESS + (COLUMN_ADDRESS-1)) downto
                         (BANK_ADDRESS +ROW_ADDRESS + COLUMN_ADDRESS)) =  CS_H1((CHIP_ADDRESS - 1) downto 0)) then
          ddr2_cs_r((CS_WIDTH-1) downto 0) <= CS_HD((CS_WIDTH-1) downto 0);
        elsif (af_addr_r((CHIP_ADDRESS + BANK_ADDRESS +ROW_ADDRESS + (COLUMN_ADDRESS-1)) downto
                         (BANK_ADDRESS + ROW_ADDRESS + COLUMN_ADDRESS)) = CS_H2((CHIP_ADDRESS - 1) downto 0)) then
          ddr2_cs_r((CS_WIDTH-1) downto 0) <= CS_HB((CS_WIDTH-1) downto 0);
        elsif (af_addr_r((CHIP_ADDRESS + BANK_ADDRESS +ROW_ADDRESS + (COLUMN_ADDRESS-1)) downto
                         (BANK_ADDRESS + ROW_ADDRESS + COLUMN_ADDRESS)) = CS_H3((CHIP_ADDRESS - 1) downto 0)) then
          ddr2_cs_r((CS_WIDTH-1) downto 0) <= CS_H7((CS_WIDTH-1) downto 0);
        else
          ddr2_cs_r((CS_WIDTH-1) downto 0) <= CS_HF((CS_WIDTH-1) downto 0);
        end if;
      end if;
    end if;
  end process;

  -- address during init
  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ddr2_address_init_r <= (others => '0');
      else
        if (init_state_r2(3) = '1') then
          -- A10 = 1 for precharge all
          ddr2_address_init_r <= (10 => '1' , others => '0');
        elsif (init_state_r2(1) = '1' and init_count_cp = "0101") then
          -- A0 == 0 for DLL enable
          ddr2_address_init_r <= ext_mode_reg;
        elsif (init_state_r2(1) = '1' and init_count_cp = "0110") then
          ddr2_address_init_r <= ADD_CONST1((ROW_ADDRESS-1) downto 0) or
                                 load_mode_reg;
        elsif (init_state_r2(1) = '1' and init_count_cp = "1010") then
          ddr2_address_init_r <= load_mode_reg;
        elsif (init_state_r2(1) = '1' and init_count_cp = "1011") then
          ddr2_address_init_r <= (ADD_CONST2((ROW_ADDRESS-1) downto 0) or
                                  ext_mode_reg); -- OCD DEFAULT
        elsif (init_state_r2(1) = '1' and init_count_cp = "1100") then
          ddr2_address_init_r <= (ADD_CONST3((ROW_ADDRESS-1) downto 0) or
                                  ext_mode_reg); -- OCD EXIT
        elsif(init_state_r2(10) = '1') then
          ddr2_address_init_r <= row_addr_r;
        else
          ddr2_address_init_r <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  -- turn off auto-precharge when issuing commands (A10 = 0)
  -- mapping the col add for linear addressing.
  gen_ddr_addr_col_0: if (COL_WIDTH = ROW_WIDTH-1) generate
    ddr_addr_col <= (af_addr_r1(COL_WIDTH-1 downto 10) & '0' &
                     af_addr_r1(9 downto 0));
  end generate;
  gen_ddr_addr_col_1: if ((COL_WIDTH > 10) and
                          not(COL_WIDTH = ROW_WIDTH-1)) generate
    ddr_addr_col(ROW_WIDTH-1 downto COL_WIDTH+1) <= (others => '0');
    ddr_addr_col(COL_WIDTH downto 0) <=
      (af_addr_r1(COL_WIDTH-1 downto 10) & '0' & af_addr_r1(9 downto 0));
  end generate;
  gen_ddr_addr_col_2: if (not((COL_WIDTH > 10) or
                              (COL_WIDTH = ROW_WIDTH-1))) generate
    ddr_addr_col(ROW_WIDTH-1 downto COL_WIDTH+1) <= (others => '0');
    ddr_addr_col(COL_WIDTH downto 0) <=
      ('0' & af_addr_r1(COL_WIDTH-1 downto 0));
  end generate;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ddr2_address_r1 <= (others => '0');
      elsif ((state_r2(7) = '1')) then
        ddr2_address_r1 <= row_addr_r;
      elsif (state_r2(12) = '1' or state_r2(13) = '1' or
             state_r2(9) = '1' or state_r2(10) = '1') then
        ddr2_address_r1 <= ddr_addr_col;
      elsif (state_r2(3) = '1') then
          ddr2_address_r1 <= (10 => '1', others => '0');
      elsif (state_r2(1) = '1') then
        ddr2_address_r1 <= af_addr_r1((ROW_ADDRESS-1) downto 0);
      else
        ddr2_address_r1 <= (others => '0');
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ddr2_address_r2 <= (others => '0');
      elsif (init_memory = '1') then
        ddr2_address_r2 <= ddr2_address_init_r;
      else
        ddr2_address_r2 <= ddr2_address_r1;
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ddr2_ba_r1 <= (others => '0');
      elsif ((init_memory = '1') and (init_state_r2(1) = '1')) then
        if (init_count_cp = X"3") then
          ddr2_ba_r1 <= (1 => '1', others => '0'); -- emr2
        elsif (init_count_cp = X"4") then
          ddr2_ba_r1 <= (0 | 1 => '1', others => '0'); -- emr3
        elsif (init_count_cp = X"5" or init_count_cp = X"B" or
               init_count_cp = X"C") then
          ddr2_ba_r1 <= (0 => '1', others => '0');  -- emr
        else
          ddr2_ba_r1 <= (others => '0');
        end if;
      elsif ((state_r2(7) = '1') or (init_state_r2(10) = '1') or
             (state_r2(1) = '1') or ((state_r2(3) = '1') and (pre_r = '1')) or
             (init_state_r2(1) = '1') or (init_state_r2(3) = '1')) then
        ddr2_ba_r1 <= af_addr_r(((BANK_ADDRESS +ROW_ADDRESS +COLUMN_ADDRESS)-1)
                                downto (COLUMN_ADDRESS + ROW_ADDRESS));
      else
        ddr2_ba_r1 <= ddr2_ba_r1((BANK_ADDRESS-1) downto 0);
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ddr2_ba_r2((BANK_ADDRESS-1) downto 0) <= (others => '0');
      else
        ddr2_ba_r2((BANK_ADDRESS-1) downto 0) <= ddr2_ba_r1;
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ddr2_cs_r1((CS_WIDTH-1) downto 0) <= (others => '1');
      elsif (init_memory = '1') then
        if (chip_cnt = "00") then
          ddr2_cs_r1((CS_WIDTH-1) downto 0) <= CS_HE((CS_WIDTH-1) downto 0);
        elsif (chip_cnt = "01") then
          ddr2_cs_r1((CS_WIDTH-1) downto 0) <= CS_HD((CS_WIDTH-1) downto 0);
        elsif (chip_cnt = "10") then
          ddr2_cs_r1((CS_WIDTH-1) downto 0) <= CS_HB((CS_WIDTH-1) downto 0);
        elsif (chip_cnt = "11") then
          ddr2_cs_r1((CS_WIDTH-1) downto 0) <= CS_H7((CS_WIDTH-1) downto 0);
        else
          ddr2_cs_r1((CS_WIDTH-1) downto 0) <= CS_HF((CS_WIDTH-1) downto 0);
        end if;

      --  Precharge fix for deep memory
      elsif (state_r2(3) = '1') then
        if (pre_cnt = "001") then
          ddr2_cs_r1((CS_WIDTH-1) downto 0) <= CS_HE((CS_WIDTH-1) downto 0);
        elsif (pre_cnt = "010") then
          ddr2_cs_r1((CS_WIDTH-1) downto 0) <= CS_HD((CS_WIDTH-1) downto 0);
        elsif (pre_cnt = "011") then
          ddr2_cs_r1((CS_WIDTH-1) downto 0) <= CS_HB((CS_WIDTH-1) downto 0);
        elsif (pre_cnt = "100") then
          ddr2_cs_r1((CS_WIDTH-1) downto 0) <= CS_H7((CS_WIDTH-1) downto 0);
        elsif (pre_cnt = "000") then
          ddr2_cs_r1((CS_WIDTH-1) downto 0) <= ddr2_cs_r1((CS_WIDTH-1) downto 0);
        else
          ddr2_cs_r1((CS_WIDTH-1) downto 0) <= CS_HF((CS_WIDTH-1) downto 0);
        end if;

      elsif (state_r2(5) = '1') then
        if (auto_cnt = "001") then
          ddr2_cs_r1((CS_WIDTH-1) downto 0) <= CS_HE((CS_WIDTH-1) downto 0);
        elsif (auto_cnt = "010") then
          ddr2_cs_r1((CS_WIDTH-1) downto 0) <= CS_HD((CS_WIDTH-1) downto 0);
        elsif (auto_cnt = "011") then
          ddr2_cs_r1((CS_WIDTH-1) downto 0) <= CS_HB((CS_WIDTH-1) downto 0);
        elsif (auto_cnt = "100") then
          ddr2_cs_r1((CS_WIDTH-1) downto 0) <= CS_H7((CS_WIDTH-1) downto 0);
        else
          ddr2_cs_r1((CS_WIDTH-1) downto 0) <= CS_HF((CS_WIDTH-1) downto 0);
        end if;

      elsif ((state_r2(7) = '1') or (init_state_r2(10) = '1') or
             (state_r2(1) = '1') or (state_r2(4) = '1') or
             (init_state_r2(1) = '1') or (init_state_r2(4) = '1'))  then
        ddr2_cs_r1((CS_WIDTH-1) downto 0) <= ddr2_cs_r((CS_WIDTH-1) downto 0);

      else
        ddr2_cs_r1((CS_WIDTH-1) downto 0) <= ddr2_cs_r1((CS_WIDTH-1) downto 0);
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ddr2_cs_r_out <= (others => '1');
        ddr2_cs_r_out_cpy <= (others => '1');
        ddr2_cs_r_odt <= (others => '1');
      else
        ddr2_cs_r_out <= ddr2_cs_r1;
        ddr2_cs_r_out_cpy <= ddr2_cs_r1;
        ddr2_cs_r_odt <= ddr2_cs_r1;
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ddr2_cs_r_odt_r1 <= (others => '1');
        ddr2_cs_r_odt_r2 <= (others => '1');
      else
        ddr2_cs_r_odt_r1 <= ddr2_cs_r_odt;
        ddr2_cs_r_odt_r2 <= ddr2_cs_r_odt_r1;
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        conflict_resolved_r <= '0';
      else
        if ((state(4) = '1') and (conflict_detect_r = '1')) then
          conflict_resolved_r <= '1';
        elsif(af_rden = '1') then
          conflict_resolved_r <= '0';
        end if;
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        ddr2_cke_r <= CS_H0((CKE_WIDTH-1) downto 0);
      elsif (done_200us = '1') then
        ddr2_cke_r <= CS_HF((CKE_WIDTH-1) downto 0);
      end if;
    end if;
  end process;

  -- odt

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        odt_en_cnt <= "0000";
      elsif(((state(12) = '1') or (init_state(12) = '1')
             or (init_state(18) = '1')) and (odt_enable = '1')) then
        odt_en_cnt <= (('0' & additive_latency_value) +
                       ('0' & cas_latency_value) - "0010");
      elsif(((state(9) = '1') or (init_state(14) = '1') or
             (init_state(20) = '1')) and (odt_enable = '1')) then
        odt_en_cnt <= (('0' & additive_latency_value) +
                       ('0' & cas_latency_value) - "0001");
      elsif(odt_en_cnt /= "0000") then
        odt_en_cnt <= odt_en_cnt - "0001";
      else
        odt_en_cnt <= "0000";
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      if (rst_r1 = '1') then
        odt_cnt <= "0000";
      elsif(((state(12) = '1') or (state(13) = '1') or
             (init_state(12) = '1') or (init_state(18) = '1')) and
            (odt_enable = '1')) then
        odt_cnt <= (('0' & additive_latency_value) + ('0'& cas_latency_value) +
                    ('0' & burst_cnt) + ("000" & registered_dimm));
      elsif(((state(9) = '1') or (state(10) = '1') or (init_state(14) = '1') or
             (init_state(20) = '1')) and (odt_enable = '1')) then
        odt_cnt <= (('0' & additive_latency_value) + ('0' & cas_latency_value) +
                    ('0' & burst_cnt) + ("000" & registered_dimm) + "0001");
      elsif(odt_cnt /= "0000") then
        odt_cnt <= odt_cnt - "0001";
      else
        odt_cnt <= "0000";
      end if;
    end if;
  end process;

  -- odt_en logic is made combinational to add a flop to the ctrl_odt logic

  process(odt_en_cnt, odt_cnt)
  begin
    if((odt_en_cnt = "0001") or
       (odt_cnt > "0010" and odt_en_cnt <= "0001")) then
      odt_en((CS_WIDTH-1) downto 0) <= CS_HF((CS_WIDTH-1) downto 0);
    else
      odt_en <= (others => '0');
    end if;
  end process;

  -- added for deep designs

  process(clk0)
  begin
    if (clk0='1' and clk0'event) then
      if (rst_r1 = '1') then
            ctrl_odt  <= (others => '0');
            ctrl_odt_cpy  <= (others => '0');
      else
        case CS_WIDTH is
          when 1 =>
            -- ODT is only enabled on writes is disabled on read operations.
            if ((ddr2_cs_r_odt_r2 = CS_H0((CS_WIDTH-1) downto 0))
                and (odt_en_single = '1')) then
                ctrl_odt <= (odt_en((CS_WIDTH-1) downto 0) and
                             CS_H1((CS_WIDTH-1) downto 0));
                ctrl_odt_cpy <= (odt_en((CS_WIDTH-1) downto 0) and
                             CS_H1((CS_WIDTH-1) downto 0));
            else
                ctrl_odt <= (others=>'0');
                ctrl_odt_cpy <= (others=>'0');
            end if;

          when 2 =>
            if (SINGLE_RANK = 1) then
              -- Two single Rank DIMMs or components poupulated in
              -- two different slots - Memory Componet sequence as
              -- Component 0 is CS0 and Component 1 is CS1.
              -- ODT is enabled for component 1 when writing into 0 and
              -- enabled for component 0 when writing into component 1.
              -- During read operations, ODT is enabled for component 1
              -- when reading from 0 and enabled for component 0 when
              -- reading from component 1.
			  -- Constants CS_H2 = "0010" and CS_H1 = "0001"
              if (ddr2_cs_r_odt_r2 = CS_H2((CS_WIDTH-1) downto 0)) then
                  ctrl_odt <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H2((CS_WIDTH-1) downto 0));
                  ctrl_odt_cpy <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H2((CS_WIDTH-1) downto 0));
              elsif (ddr2_cs_r_odt_r2 =  CS_H1((CS_WIDTH-1) downto 0)) then
                  ctrl_odt <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H1((CS_WIDTH-1) downto 0));
                  ctrl_odt_cpy <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H1((CS_WIDTH-1) downto 0));
              else
                  ctrl_odt <= (others=>'0');
                  ctrl_odt_cpy <= (others=>'0');
              end if;
            elsif (DUAL_RANK = 1) then
              -- One Dual Rank DIMM is poupulated in single slot - Rank1 is
              -- referred as CS0 and Rank2 is referres as CS1.
              -- ODT is enabled for CS0 when writing into CS0 or CS1.
              -- ODT is disabled on read operations.
			  -- Constants CS_H2 = "0010" and CS_H1 = "0001"
              if (ddr2_cs_r_odt_r2 = CS_H2((CS_WIDTH-1) downto 0)
                  and (odt_en_single = '1')) then
                  ctrl_odt <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H1((CS_WIDTH-1) downto 0));
                  ctrl_odt_cpy <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H1((CS_WIDTH-1) downto 0));
              elsif (ddr2_cs_r_odt_r2 =  CS_H1((CS_WIDTH-1) downto 0)
                     and (odt_en_single = '1')) then
                  ctrl_odt <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H1((CS_WIDTH-1) downto 0));
                  ctrl_odt_cpy <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H1((CS_WIDTH-1) downto 0));
              else
                  ctrl_odt <= (others=>'0');
                  ctrl_odt_cpy <= (others=>'0');
              end if;
            end if;

          when 3 =>
            if (SINGLE_RANK = 1) then
              -- Three single Rank DIMMs or components poupulated in
              -- three different slots - Memory Component sequence as
              -- Component 0 is CS0, Component 1 is CS1, Component 2 is CS2.
              -- During write operations, ODT is enabled for component 2
              -- when writing into 0 or 1 and enabled for component 1
              -- when writing into component 2. During read operations,
              -- ODT is enabled for component 2 when reading from 0 or 1 and
              -- enabled for component 1 for reading from component 2.
			  -- Constants CS_H6 = "0110", CS_H5 = "0101", CS_H4 = "0100", 
			  -- CS_H3 = "0011" and CS_H2 = "0010"
              if (ddr2_cs_r_odt_r2 =  CS_H6((CS_WIDTH-1) downto 0)) then
                  ctrl_odt <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H4((CS_WIDTH-1) downto 0));
                  ctrl_odt_cpy <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H4((CS_WIDTH-1) downto 0));
              elsif(ddr2_cs_r_odt_r2 =  CS_H5((CS_WIDTH-1) downto 0))  then
                  ctrl_odt <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H4((CS_WIDTH-1) downto 0));
                  ctrl_odt_cpy <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H4((CS_WIDTH-1) downto 0));
              elsif (ddr2_cs_r_odt_r2 = CS_H3((CS_WIDTH - 1) downto 0)) then
                  ctrl_odt <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H2((CS_WIDTH-1) downto 0));
                  ctrl_odt_cpy <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H2((CS_WIDTH-1) downto 0));
              else
                  ctrl_odt <= (others=>'0');
                  ctrl_odt_cpy <= (others=>'0');
              end if;
--            elsif (DUAL_RANK = 1) then
              -- One Dual Rank DIMM is poupulated in slot1 and
              -- single Rank DIMM is populated in slot2 (2R/R) - Rank1 and
              -- Rank2 of slot1 are referred as CS0 and CS1 respectively.
              -- Rank1 of slot2 is referred as CS2 and Rank2 is unpopulated.
              -- ODT is enabled for CS0 when writing into CS2 and
              -- enabled for CS2 when writing into CS0 or CS1.
              -- ODT is enabled for CS0 when reading from CS2 and
              -- enabled for CS2 when reading from CS0 or CS1.
			  -- Constants CS_H6 = "0110", CS_H5 = "0101", CS_H4 = "0100", 
			  -- CS_H3 = "0011" and CS_H1 = "0001"
			  -- 2R/R configuration is not supported by MIG, 
			  -- ODT logic can be enabled by uncommenting the following logic.
--			  if (ddr2_cs_r_odt_r2 =  CS_H6((CS_WIDTH-1) downto 0)) then
--                  ctrl_odt <= (odt_en((CS_WIDTH-1) downto 0) and
--                               CS_H4((CS_WIDTH-1) downto 0));
--              elsif(ddr2_cs_r_odt_r2 =  CS_H5((CS_WIDTH-1) downto 0))  then
--                  ctrl_odt <= (odt_en((CS_WIDTH-1) downto 0) and
--                               CS_H4((CS_WIDTH-1) downto 0));
--              elsif (ddr2_cs_r_odt_r2 = CS_H3((CS_WIDTH - 1) downto 0)) then
--                  ctrl_odt <= (odt_en((CS_WIDTH-1) downto 0) and
--                               CS_H1((CS_WIDTH-1) downto 0));
--              else
--                  ctrl_odt <= (others=>'0');
--              end if;
            end if;

          when 4 =>
            if (SINGLE_RANK = 1) then
              -- Four single Rank DIMMs or components poupulated in
              -- four different slots - Memory Component sequence as
              -- Component 0 is CS0, Component 1 is CS1,
              -- Component 2 is CS2 and Component 3 is CS3.
              -- During write operations, ODT is enabled for component 3
              -- when writing into 0 or 1 or 2 and enabled for component 2
              -- when writing into component 3. During read operations,
              -- ODT is enabled for component 3 when reading from 0 or 1 or 2
              -- and enabled for component 2 for reading from component 3.
			  -- Constants CS_HE = "1110", CS_HD = "1101", CS_HB = "1011",
			  -- CS_H7 = "0111", CS_H8 = "1000" and CS_H4 = "0100"
			  if (ddr2_cs_r_odt_r2 =  CS_HE((CS_WIDTH - 1) downto 0)) then
                  ctrl_odt <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H8((CS_WIDTH-1) downto 0));
                  ctrl_odt_cpy <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H8((CS_WIDTH-1) downto 0));
              elsif (ddr2_cs_r_odt_r2 = CS_HD((CS_WIDTH - 1) downto 0)) then
                 ctrl_odt <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H8((CS_WIDTH-1) downto 0));
                 ctrl_odt_cpy <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H8((CS_WIDTH-1) downto 0));
              elsif (ddr2_cs_r_odt_r2 = CS_HB((CS_WIDTH - 1) downto 0)) then
                  ctrl_odt <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H8((CS_WIDTH-1) downto 0));
                  ctrl_odt_cpy <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H8((CS_WIDTH-1) downto 0));
              elsif (ddr2_cs_r_odt_r2 = CS_H7((CS_WIDTH - 1) downto 0)) then
                  ctrl_odt <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H4((CS_WIDTH-1) downto 0));
                  ctrl_odt_cpy <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H4((CS_WIDTH-1) downto 0));
              else
                  ctrl_odt <= (others=>'0');
                  ctrl_odt_cpy <= (others=>'0');
              end if;
            elsif (DUAL_RANK = 1) then
              -- Two Dual Rank DIMMs are poupulated in slot1 and slot2 -
              -- Rank1 and Rank2 of slot1 are referred as CS0 and CS1.
              -- Rank1 and Rank2 of slot2 are referred as CS2 and CS3.
              -- ODT is enabled for CS0 when writing into CS2 or CS3 and
              -- enabled for CS2 when writing into CS0 or CS1.
              -- ODT is enabled for CS0 when reading from CS2 or CS3 and
              -- enabled for CS2 when reading from CS0 or CS1.
			  -- Constants CS_HE = "1110", CS_HD = "1101", CS_HB = "1011",
			  -- CS_H7 = "0111", CS_H4 = "0100" and CS_H1 = "0001"
              if (ddr2_cs_r_odt_r2 =  CS_HE((CS_WIDTH - 1) downto 0)) then
                  ctrl_odt <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H4((CS_WIDTH-1) downto 0));
                  ctrl_odt_cpy <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H4((CS_WIDTH-1) downto 0));
              elsif (ddr2_cs_r_odt_r2 = CS_HD((CS_WIDTH - 1) downto 0)) then
                 ctrl_odt <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H4((CS_WIDTH-1) downto 0));
                 ctrl_odt_cpy <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H4((CS_WIDTH-1) downto 0));
              elsif (ddr2_cs_r_odt_r2 = CS_HB((CS_WIDTH - 1) downto 0)) then
                  ctrl_odt <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H1((CS_WIDTH-1) downto 0));
                  ctrl_odt_cpy <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H1((CS_WIDTH-1) downto 0));
              elsif (ddr2_cs_r_odt_r2 = CS_H7((CS_WIDTH - 1) downto 0)) then
                  ctrl_odt <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H1((CS_WIDTH-1) downto 0));
                  ctrl_odt_cpy <= (odt_en((CS_WIDTH-1) downto 0) and
                               CS_H1((CS_WIDTH-1) downto 0));
              else
                  ctrl_odt <= (others=>'0');
                  ctrl_odt_cpy <= (others=>'0');
              end if;
            end if;

          when others => 
            ctrl_odt <= ctrl_odt;
            ctrl_odt_cpy <= ctrl_odt_cpy;

        end case;
      end if;
    end if;
  end process;

  ctrl_ddr2_address <= ddr2_address_r2((ROW_ADDRESS-1) downto 0);
  ctrl_ddr2_ba      <= ddr2_ba_r2((BANK_ADDRESS-1) downto 0);
  ctrl_ddr2_ras_l   <= ddr2_ras_r3;
  ctrl_ddr2_cas_l   <= ddr2_cas_r3;
  ctrl_ddr2_we_l    <= ddr2_we_r3;
  ctrl_ddr2_odt     <= ctrl_odt;
  ctrl_ddr2_odt_cpy     <= ctrl_odt_cpy;
  ctrl_ddr2_cs_l    <= ddr2_cs_r_out;
  ctrl_ddr2_cs_l_cpy    <= ddr2_cs_r_out_cpy;

  ctrl_dqs_rst      <= ctrl_dqs_rst_r1;
  ctrl_dqs_en       <= ctrl_dqs_en_r1;
  ctrl_wren         <= ctrl_wren_r1;
  ctrl_rden         <= ctrl_rden_r1;
  ctrl_dummy_wr_sel <= ctrl_wdf_rden_int when (ctrl_dummy_write = '1') else '0';



  ctrl_ddr2_cke     <= ddr2_cke_r;


end arc_controller;
