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
--  /   /        Filename           : DDR2_test_bench_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module is the synthesizable test bench for the memory
--               interface. This Test bench to compare the write and the
--               read data and generate an error flag.
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity DDR2_test_bench_0 is
  port (
    clk                : in std_logic;
    reset              : in std_logic;
    wdf_almost_full    : in std_logic;
    af_almost_full     : in std_logic;
    burst_length_div2  : in std_logic_vector(2 downto 0);
    read_data_valid    : in std_logic;
    read_data_fifo_out : in std_logic_vector(DQ_WIDTH*2-1 downto 0);
    init_done          : in std_logic;

    app_af_addr        : out std_logic_vector(35 downto 0);
    app_af_wren        : out std_logic;
    app_wdf_data       : out std_logic_vector(DQ_WIDTH*2-1 downto 0);
    app_mask_data      : out std_logic_vector(DM_WIDTH*2-1 downto 0);
    app_wdf_wren       : out std_logic;
    error              : out std_logic
    );

end entity;

architecture arc_test_bench of DDR2_test_bench_0 is

  component DDR2_cmp_rd_data_0
    port (
      clk                : in std_logic;
      reset              : in std_logic;
      read_data_valid    : in std_logic;
      app_compare_data   : in std_logic_vector(DQ_WIDTH*2-1 downto 0);
      read_data_fifo_out : in std_logic_vector(DQ_WIDTH*2-1 downto 0);
      error              : out std_logic
      );
  end component;

  component DDR2_backend_rom_0
    port (
      clk0                : in std_logic;
      rst                 : in std_logic;
      -- enables signals from state machine
      bkend_data_en       : in std_logic;
      bkend_wraddr_en     : in std_logic;
      bkend_rd_data_valid : in std_logic;
      -- Write address fifo signals
      app_af_addr         : out std_logic_vector(35 downto 0);
      app_af_wren         : out std_logic;
      -- Write data fifo signals
      app_wdf_data        : out std_logic_vector(DQ_WIDTH*2-1 downto 0);
      app_mask_data       : out std_logic_vector(DM_WIDTH*2-1 downto 0);
      app_compare_data    : out std_logic_vector(DQ_WIDTH*2-1 downto 0);
      app_wdf_wren        : out std_logic
      );
  end component;

  type t_s is (idle, write, read);
  signal state : t_s;

  signal burst_count       : std_logic_vector(2 downto 0);
  signal write_data_en     : std_logic;
  signal write_addr_en     : std_logic;
  signal app_cmp_data      : std_logic_vector(DQ_WIDTH*2-1 downto 0);
  signal burst_len         : std_logic_vector(2 downto 0);
  signal state_cnt         : std_logic_vector(3 downto 0);
  signal wdf_almost_full_r : std_logic;

  signal reset_r1          : std_logic;

  attribute equivalent_register_removal : string;
  attribute syn_preserve                : boolean;
  attribute equivalent_register_removal of reset_r1 : signal is "no";
  attribute syn_preserve of reset_r1                : signal is true;

begin

  --***************************************************************************

  burst_len <= burst_length_div2;

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      reset_r1 <= reset;
    end if;
  end process;

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      if (reset_r1 = '1') then
        wdf_almost_full_r <= '0';
      else
        wdf_almost_full_r <= wdf_almost_full;
      end if;
    end if;
  end process;

  -- State Machine for writing to WRITE DATA & ADDRESS and READ ADDRESS FIFOs
  -- state machine changed for low FIFO threshold values
  process(clk)
  begin
    if clk'event and clk = '1' then
      if reset_r1 = '1' then            -- State Machine in IDLE state
        write_data_en <= '0';
        write_addr_en <= '0';
        state         <= idle;
        state_cnt     <= "0000";
      else
        case (state) is

          when idle =>
            write_data_en <= '0';
            write_addr_en <= '0';
            if (wdf_almost_full_r = '0' and af_almost_full = '0' and
                init_done = '1') then
              state                   <= write;
              burst_count(2 downto 0) <= burst_len; -- Burst length divided by 2
            else
              state                   <= idle;
              burst_count(2 downto 0) <= "000";
            end if;

          when write =>                 -- write
            if (wdf_almost_full_r = '0' and af_almost_full = '0') then
              if(state_cnt = "1000") then
                state         <= read;
                state_cnt     <= "0000";
                write_data_en <= '1';
              else
                state         <= write;
                write_data_en <= '1';
              end if;

              if (burst_count(2 downto 0) /= "000") then
                burst_count(2 downto 0) <= burst_count(2 downto 0) - "001";
              else
                burst_count(2 downto 0) <= burst_len(2 downto 0) - "001";
              end if;

              if (burst_count(2 downto 0) = "001") then
                write_addr_en <= '1';
                state_cnt     <= state_cnt + '1';
              else
                write_addr_en <= '0';
              end if;
            else
              write_addr_en <= '0';
              write_data_en <= '0';
            end if;

          when read =>                  -- read
            if (af_almost_full = '0') then
              if (state_cnt = "1000") then
                write_addr_en <= '0';
                if (wdf_almost_full_r = '0') then
                  state_cnt <= "0000";
                  state     <= write;
                end if;
              else
                state         <= read;
                write_addr_en <= '1';
                write_data_en <= '0';
                state_cnt     <= state_cnt + "0001";
              end if;
            -- Modified to fix the dead lock condition
            else
              if (state_cnt = "1000") then
                state         <= idle;
                write_addr_en <= '0';
                write_data_en <= '0';
                state_cnt     <= "0000";
              else
                state         <= read;  -- it will remain in read state till it completes 8 reads
                write_addr_en <= '0';
                write_data_en <= '0';
                state_cnt     <= state_cnt; -- state count will retain
              end if;
            end if;

          when others =>
            write_data_en <= '0';
            write_addr_en <= '0';
            state         <= idle;

        end case;
      end if;
    end if;
  end process;

  cmp_rd_data_00 : DDR2_cmp_rd_data_0
    port map (
      clk                => clk,
      reset              => reset,
      read_data_valid    => read_data_valid,
      app_compare_data   => app_cmp_data(DQ_WIDTH*2-1 downto 0),
      read_data_fifo_out => read_data_fifo_out(DQ_WIDTH*2-1 downto 0),
      error              => error
      );

  backend_rom_00 : DDR2_backend_rom_0
    port map (
      clk0                => clk,
      rst                 => reset,
      bkend_data_en       => write_data_en,
      bkend_wraddr_en     => write_addr_en,
      bkend_rd_data_valid => read_data_valid,
      app_af_addr         => app_af_addr(35 downto 0),
      app_af_wren         => app_af_wren,
      app_wdf_data        => app_wdf_data(DQ_WIDTH*2-1 downto 0),
      app_mask_data       => app_mask_data(DM_WIDTH*2-1 downto 0),
      app_compare_data    => app_cmp_data(DQ_WIDTH*2-1 downto 0),
      app_wdf_wren        => app_wdf_wren
      );


end arc_test_bench;
