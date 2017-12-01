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
-- Copyright 2005, 2006, 2007 Xilinx, Inc.
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
--  /   /        Filename           : DDR2_addr_gen_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : The address for the memory and the various user commands
--               can be given through this module. It instantiates the
--               block RAM which stores all the information in particular
--               sequence. The data stored should be in a sequence starting
--               from LSB:
--                  column address, row address, bank address, chip
--                  address, commands.
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity DDR2_addr_gen_0 is
  port (
    clk0            : in  std_logic;
    rst             : in  std_logic;
    -- enables signals from state machine
    bkend_wraddr_en : in  std_logic;
    --address fifo signals
    app_af_addr     : out std_logic_vector(35 downto 0);
    app_af_wren     : out std_logic
    );
end entity;

architecture arc_addr_gen of DDR2_addr_gen_0 is

  -- RAM initialization patterns
  constant RAM_INIT_00 : bit_vector(255 downto 0) :=
    (X"0003C154" & X"0003C198" & X"0003C088" & X"0003C0EC" &
     X"00023154" & X"00023198" & X"00023088" & X"000230EC");
  constant RAM_INIT_01 : bit_vector(255 downto 0) :=
    (X"00023154" & X"00023198" & X"00023088" & X"000230EC" &
     X"0003C154" & X"0003C198" & X"0003C088" & X"0003C0EC");
  constant RAM_INIT_02 : bit_vector(255 downto 0) :=
    (X"0083C154" & X"0083C198" & X"0083C088" & X"0083C0EC" &
     X"00823154" & X"00823198" & X"00823088" & X"008230EC");
  constant RAM_INIT_03 : bit_vector(255 downto 0) :=
    (X"0083C154" & X"0083C198" & X"0083C088" & X"0083C0EC" &
     X"00823154" & X"00823198" & X"00823088" & X"008230EC");
  constant RAM_INIT_04 : bit_vector(255 downto 0) :=
    (X"0043C154" & X"0043C198" & X"0043C088" & X"0043C0EC" &
     X"00423154" & X"00423198" & X"00423088" & X"004230EC");
  constant RAM_INIT_05 : bit_vector(255 downto 0) :=
    (X"0043C154" & X"0043C198" & X"0043C088" & X"0043C0EC" &
     X"00423154" & X"00423198" & X"00423088" & X"004230EC");
  constant RAM_INIT_06 : bit_vector(255 downto 0) :=
    (X"00C3C154" & X"00C3C198" & X"00C3C088" & X"00C3C0EC" &
     X"00C23154" & X"00C23198" & X"00C23088" & X"00C230EC");
  constant RAM_INIT_07 : bit_vector(255 downto 0) :=
    (X"00C3C154" & X"00C3C198" & X"00C3C088" & X"00C3C0EC" &
     X"00C23154" & X"00C23198" & X"00C23088" & X"00C230EC");
  constant RAM_INITP_00 : bit_vector(255 downto 0) :=
    (X"55555555" & X"44444444" & X"55555555" & X"44444444" &
     X"55555555" & X"44444444" & X"55555555" & X"44444444");

  signal wr_rd_addr          : std_logic_vector(8 downto 0);
  signal wr_rd_addr_en       : std_logic;
  signal wr_addr_count       : std_logic_vector(5 downto 0);

  signal bkend_wraddr_en_reg : std_logic;
  signal wr_rd_addr_en_reg   : std_logic;
  signal bkend_wraddr_en_3r  : std_logic;

  signal unused_data_in      : std_logic_vector(31 downto 0);
  signal unused_data_in_p    : std_logic_vector(3 downto 0);
  signal gnd                 : std_logic;
  signal addr_out            : std_logic_vector(35 downto 0);

  signal rst_r1              : std_logic;

  attribute equivalent_register_removal : string;
  attribute syn_preserve                : boolean;
  attribute equivalent_register_removal of wr_rd_addr_en_reg : signal is "no";
  attribute syn_preserve of wr_rd_addr_en_reg                : signal is true;
  attribute equivalent_register_removal of rst_r1            : signal is "no";
  attribute syn_preserve of rst_r1                           : signal is true;

begin

  --***************************************************************************

  unused_data_in   <= X"00000000";
  unused_data_in_p <= "0000";
  gnd              <= '0';

  wr_rd_addr_en <= '1' when (bkend_wraddr_en = '1') else '0';

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      rst_r1 <= rst;
    end if;
  end process;

  process(clk0)
  begin
    if clk0'event and clk0 = '1' then
      if (rst_r1 = '1') then
        wr_rd_addr_en_reg <= '0';
      else
        wr_rd_addr_en_reg <= wr_rd_addr_en;
      end if;
    end if;
  end process;

  -- register backend enables
  process(clk0)
  begin
    if clk0'event and clk0 = '1' then
      if (rst_r1 = '1') then
        bkend_wraddr_en_reg <= '0';
        bkend_wraddr_en_3r  <= '0';
      else
        bkend_wraddr_en_reg <= bkend_wraddr_en;
        bkend_wraddr_en_3r  <= bkend_wraddr_en_reg;
      end if;
    end if;
  end process;

  -- Fifo enables
  process(clk0)
  begin
    if clk0'event and clk0 = '1' then
      if (rst_r1 = '1') then
        app_af_wren <= '0';
      else
        app_af_wren <= bkend_wraddr_en_3r;
      end if;
    end if;
  end process;

  -- address input for RAM
  process(clk0)
  begin
    if clk0'event and clk0 = '1' then
      if (rst_r1 = '1') then
        wr_addr_count(5 downto 0) <= "111111";
      elsif (bkend_wraddr_en = '1') then
        wr_addr_count(5 downto 0) <= wr_addr_count(5 downto 0) + "000001";
      else
        wr_addr_count(5 downto 0) <= wr_addr_count(5 downto 0);
      end if;
    end if;
  end process;

  wr_rd_addr(8 downto 0) <= ("000" & wr_addr_count(5 downto 0))
                            when (bkend_wraddr_en_reg = '1') else "000000000";

  -- FIFO addresses
  process(clk0)
  begin
    if clk0'event and clk0 = '1' then
      if (bkend_wraddr_en_3r = '1') then
        app_af_addr <= addr_out(35 downto 0);
      else
        app_af_addr <= X"000000000";
      end if;
    end if;
  end process;

  --***************************************************************************
  -- ADDRESS generation for Write and Read Address FIFOs
  -- RAMB16_S36 configuration set to 512x36 mode
  -- INIP_OO: Refresh -1
  -- INIP_OO: Precharge -2
  -- INIP_OO: Write -4
  -- INIP_OO: Read -5
  --***************************************************************************

  wr_rd_addr_lookup : RAMB16_S36
    generic map(
      INIT_00   => RAM_INIT_00,
      INIT_01   => RAM_INIT_01,
      INIT_02   => RAM_INIT_02,
      INIT_03   => RAM_INIT_03,
      INIT_04   => RAM_INIT_04,
      INIT_05   => RAM_INIT_05,
      INIT_06   => RAM_INIT_06,
      INIT_07   => RAM_INIT_07,
      INITP_00  => RAM_INITP_00
      )
    port map(
      DO   => addr_out(31 downto 0),
      DOP  => addr_out(35 downto 32),
      ADDR => wr_rd_addr(8 downto 0),
      CLK  => clk0,
      DI   => unused_data_in(31 downto 0),
      DIP  => unused_data_in_p(3 downto 0),
      EN   => wr_rd_addr_en_reg,
      SSR  => gnd,
      WE   => gnd
      );


end arc_addr_gen;
