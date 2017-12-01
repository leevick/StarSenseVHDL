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
--  /   /        Filename           : DDR2_backend_fifos_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Description : This module instantiates the modules containing internal FIFOs
--               to store the data and the address.
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

entity DDR2_backend_fifos_0 is
  port(
    clk0            : in  std_logic;
    clk90           : in  std_logic;
    rst             : in  std_logic;
    init_done       : in  std_logic;
    --Write address fifo signals
    app_af_addr     : in  std_logic_vector(35 downto 0);
    app_af_wren     : in  std_logic;
    ctrl_af_rden    : in  std_logic;
    af_addr         : out std_logic_vector(35 downto 0);
    af_empty        : out std_logic;
    af_almost_full  : out std_logic;
    --Write data fifo signals
    app_wdf_data    : in  std_logic_vector(DQ_WIDTH*2-1 downto 0);
    app_mask_data   : in  std_logic_vector(DM_WIDTH*2-1 downto 0);
    app_wdf_wren    : in  std_logic;
    ctrl_wdf_rden   : in  std_logic;
    wdf_data        : out std_logic_vector(DQ_WIDTH*2-1 downto 0);
    mask_data       : out std_logic_vector(DM_WIDTH*2-1 downto 0);
    wdf_almost_full : out std_logic
    );
end entity;

architecture arc_backend_fifos of DDR2_backend_fifos_0 is

  component DDR2_rd_wr_addr_fifo_0
    port(
      clk0           : in  std_logic;
      clk90          : in  std_logic;
      rst            : in  std_logic;
      --Write address fifo signals
      app_af_addr    : in  std_logic_vector(35 downto 0);
      app_af_wren    : in  std_logic;
      ctrl_af_rden   : in  std_logic;
      af_addr        : out std_logic_vector(35 downto 0);
      af_empty       : out std_logic;
      af_almost_full : out std_logic
      );
  end component;

  component DDR2_wr_data_fifo_16
    port (
      clk0              : in  std_logic;
      clk90             : in  std_logic;
      rst               : in  std_logic;
      --Write data fifo signals
      app_wdf_data      : in  std_logic_vector(31 downto 0);
      app_mask_data     : in  std_logic_vector(3 downto 0);
      app_wdf_wren      : in  std_logic;
      ctrl_wdf_rden     : in  std_logic;
      wdf_data          : out std_logic_vector(31 downto 0);
      mask_data         : out std_logic_vector(3 downto 0);
      wr_df_almost_full : out std_logic
      );
  end component;

  component DDR2_wr_data_fifo_8 is
    port(
      clk0              : in  std_logic;
      clk90             : in  std_logic;
      rst               : in  std_logic;
      --Write data fifo signals
      app_wdf_data      : in  std_logic_vector(15 downto 0);
      app_mask_data     : in  std_logic_vector(1 downto 0);
      app_wdf_wren      : in  std_logic;
      ctrl_wdf_rden     : in  std_logic;
      wdf_data          : out std_logic_vector(15 downto 0);
      mask_data         : out std_logic_vector(1 downto 0);
      wr_df_almost_full : out std_logic
      );
  end component;

  signal wr_df_almost_full_w    : std_logic_vector((FIFO_16-1) downto 0);

  signal init_count             : std_logic_vector(2 downto 0);
  signal init_wren              : std_logic;
  signal init_data              : std_logic_vector((DQ_WIDTH*2)-1 downto 0);
  signal init_flag              : std_logic;
  signal init_mux_app_wdf_data  : std_logic_vector((DQ_WIDTH*2)-1 downto 0);
  signal init_mux_app_mask_data : std_logic_vector((DM_WIDTH*2)-1 downto 0);
  signal init_mux_app_wdf_wren  : std_logic;
  signal pattern_F              : std_logic_vector(143 downto 0);
  signal pattern_0              : std_logic_vector(143 downto 0);
  signal pattern_A              : std_logic_vector(143 downto 0);
  signal pattern_5              : std_logic_vector(143 downto 0);

  signal rst_r1                 : std_logic;

  attribute equivalent_register_removal : string;
  attribute syn_preserve                : boolean;
  attribute equivalent_register_removal of rst_r1 : signal is "no";
  attribute syn_preserve of rst_r1                : signal is true;

begin

  --***************************************************************************

  pattern_F <= X"FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF";
  pattern_0 <= X"0000_0000_0000_0000_0000_0000_0000_0000_0000";
  pattern_A <= X"AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA";
  pattern_5 <= X"5555_5555_5555_5555_5555_5555_5555_5555_5555";

  wdf_almost_full <= wr_df_almost_full_w(0);

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      rst_r1 <= rst;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0'event and clk0 = '1') then
      if (rst_r1 = '1') then
        init_count <= (others => '0');
        init_wren  <= '0';
        init_data  <= (others => '0');
        init_flag  <= '0';
      else
        case init_count is

          when "000" =>
            if(init_flag = '1') then
              init_count <= (others => '0');
              init_wren  <= '0';
              init_data  <= (others => '0');
            else
              init_count <= "001";
              init_wren  <= '1';
              init_data  <= (pattern_F((DQ_WIDTH-1) downto 0) &
                             pattern_0((DQ_WIDTH-1) downto 0));
            end if;

          when "001" =>
            if(LOAD_MODE_REGISTER(2 downto 0) = "011") then
              init_count <= "010";
            else
              init_count <= "110";
            end if;

            init_wren <= '1';
            init_data <= (pattern_F((DQ_WIDTH-1) downto 0) &
                          pattern_0((DQ_WIDTH-1) downto 0));

          when "010" =>
            init_count <= "011";
            init_wren  <= '1';
            init_data  <= (pattern_F((DQ_WIDTH-1) downto 0) &
                           pattern_0((DQ_WIDTH-1) downto 0));

          when "011" =>
            init_count <= "100";
            init_wren  <= '1';
            init_data  <= (pattern_F((DQ_WIDTH-1) downto 0) &
                           pattern_0((DQ_WIDTH-1) downto 0));

          when "100" =>
            init_count <= "101";
            init_wren  <= '1';
            init_data  <= (pattern_A((DQ_WIDTH-1) downto 0) &
                           pattern_5((DQ_WIDTH-1) downto 0));

          when "101" =>
            init_count <= "110";
            init_wren  <= '1';
            init_data  <= (pattern_5((DQ_WIDTH-1) downto 0) &
                           pattern_A((DQ_WIDTH-1) downto 0));

          when "110" =>
            init_count <= "111";
            init_wren  <= '1';
            init_data  <= (pattern_A((DQ_WIDTH-1) downto 0) &
                           pattern_5((DQ_WIDTH-1) downto 0));

          when "111" =>
            init_count <= "000";
            init_wren  <= '1';
            init_data  <= (pattern_5((DQ_WIDTH-1) downto 0) &
                           pattern_A((DQ_WIDTH-1) downto 0));
            init_flag  <= '1';

          when others =>
            init_count <= "000";
            init_wren  <= '0';
            init_data  <= (others => '0');
            init_flag  <= '0';

        end case;  -- case(init_count)
      end if;  -- else: !if(rst)
    end if;
  end process;

  init_mux_app_wdf_data  <= app_wdf_data when (init_done = '1') else init_data;
  init_mux_app_mask_data <= app_mask_data when (init_done = '1')
                            else (others => '0');
  init_mux_app_wdf_wren  <= app_wdf_wren when (init_done = '1') else init_wren;

  rd_wr_addr_fifo_00 : DDR2_rd_wr_addr_fifo_0
    port map (
      clk0           => clk0,
      clk90          => clk90,
      rst            => rst,
      app_af_addr    => app_af_addr,
      app_af_wren    => app_af_wren,
      ctrl_af_rden   => ctrl_af_rden,
      af_addr        => af_addr,
      af_empty       => af_empty,
      af_almost_full => af_almost_full
      );

  wr_data_fifo_160 : DDR2_wr_data_fifo_16
    port map (
      clk0              => clk0,
      clk90             => clk90,
      rst               => rst,
      app_wdf_data      => init_mux_app_wdf_data(31 downto 0),
      app_mask_data     => init_mux_app_mask_data(3 downto 0),
      app_wdf_wren      => init_mux_app_wdf_wren,
      ctrl_wdf_rden     => ctrl_wdf_rden,
      wdf_data          => wdf_data(31 downto 0),
      mask_data         => mask_data(3 downto 0),
      wr_df_almost_full => wr_df_almost_full_w(0)
      );


  wr_data_fifo_161 : DDR2_wr_data_fifo_16
    port map (
      clk0              => clk0,
      clk90             => clk90,
      rst               => rst,
      app_wdf_data      => init_mux_app_wdf_data(63 downto 32),
      app_mask_data     => init_mux_app_mask_data(7 downto 4),
      app_wdf_wren      => init_mux_app_wdf_wren,
      ctrl_wdf_rden     => ctrl_wdf_rden,
      wdf_data          => wdf_data(63 downto 32),
      mask_data         => mask_data(7 downto 4),
      wr_df_almost_full => wr_df_almost_full_w(1)
      );



end arc_backend_fifos;
